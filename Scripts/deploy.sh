# ----Variables----
resourceGroup="RG-William-Nilsson-b634ed-DotNetCloudDeveloper-VT-Mars-Goteborg"
location="westeurope"
name="labbtest"
keyvaultname="kv$(date +%s)"
storagename="storage$(date +%s)"
containername="backups${name}"
expiry=$(date -u -d "+1 day" +"%Y-%m-%dT%H:%MZ")
az account set --subscription "SUB-Utbildning-DotNetCloudDeveloper-2026-VT-Mars-Goteborg"
echo "Current Azure Account:"
az account show --output table
userObjectId=$(az ad signed-in-user show --query id -o tsv)




#----Create-----

set -e

# Create Sql Server
az sql server create --name "server-$name" --resource-group $resourceGroup --location $location --admin-user tewini1129 --admin-password WiNi6287!

# Create Database
az sql db create --resource-group $resourceGroup --server "server-$name" --name "db-"$name --edition GeneralPurpose --family Gen5 --capacity 1 --compute-model Serverless --auto-pause-delay 60

# Create Key Vault
az keyvault create --name $keyvaultname  --resource-group $resourceGroup --location $location --enable-rbac-authorization true 
sleep 10

# Create App Service Plan
az appservice plan create --name "appservice-plan-$name" --resource-group $resourceGroup --sku S1 --is-linux  

# Create App Service
az webapp create --name "webapp-$name" --resource-group $resourceGroup --plan "appservice-plan-$name" --runtime "DOTNETCORE:8.0"  

az webapp identity assign --name "webapp-$name" --resource-group $resourceGroup

# Create Storage Account
az storage account create --name $storagename --resource-group $resourceGroup --location $location --sku Standard_LRS --min-tls-version TLS1_2

echo "Storage Name:"
echo $storagename

echo "Waiting for storage account to be ready..."
sleep 30

storageId=$(az storage account show --name $storagename --resource-group $resourceGroup --query id -o tsv)

echo "Storage ID:"
echo $storageId

userObjectId=$(az ad signed-in-user show --query id -o tsv)

echo "USER OBJECT ID:"
echo $userObjectId

storageId=$(az storage account show --name $storagename --resource-group $resourceGroup --query id -o tsv)

echo "Storage ID:"
echo $storageId


echo "Now its time to Assign roles manually to web app and yourself"
echo "1. Go to the Azure Portal"
echo "2. Go to SQL database 'db-$name'"
echo "3. Click on Set firewall rules and add your IP address then click save"
echo "4. Go to KeyVault '$keyvaultname'"
echo "5. Click on Access controll and add a role assignment for 'Key Vault Secrets User' to the web app 'webapp-$name' and 'Key Vault Sercrets Officer' toyourself"
echo "After that you can come back here and press enter to continue with the deployment"

read -r


echo "Getting account key..."
accountKey=$(az storage account keys list --account-name $storagename --resource-group $resourceGroup --query "[0].value" -o tsv)

echo "AccountKey: $accountKey"

# Get storage connection string
storageConnStr=$(az storage account show-connection-string --name $storagename --resource-group $resourceGroup --query connectionString -o tsv)



# Create storage container
az storage container create --name "$containername" --account-name $storagename --account-key "$accountKey"
echo "Waiting 30 seconds for storage account provisioning..."
sleep 30




# Generate SAS using key (NOT RBAC)
echo "Generating SAS token..."
sasToken=$(az storage container generate-sas --account-name $storagename --account-key $accountKey --name "$containername" --permissions rwdl --expiry $expiry -o tsv)

echo "SAS TOKEN: $sasToken"

if [ -z "$sasToken" ]; then
  echo "ERROR: SAS token is EMPTY"
  exit 1
fi


# Build URL
containerUrl="https://${storagename}.blob.core.windows.net/${containername}?${sasToken}"


#Dubbel checking if URL is correct
echo "CONTAINER URL:"
echo "$containerUrl"

if [ -z "$sasToken" ]; then
  echo "ERROR: SAS token is empty"
  exit 1
fi

containerUrl="https://${storagename}.blob.core.windows.net/${containername}?${sasToken}"

sleep 20
az webapp config backup create --resource-group $resourceGroup --webapp-name "webapp-$name" --container-url $containerUrl


#Keep updating backup
az webapp config backup update --resource-group $resourceGroup --webapp-name "webapp-$name" --container-url $containerUrl --frequency 1d --retain-one true --retention 30


#-----/|\-------
#------|--------
#try all code above in one go




# ----ADJUSTMENTS----

# Add Secrets
connStr="Server=tcp:server-$name.database.windows.net,1433;Initial Catalog=db-$name;Persist Security Info=False;User ID=tewini1129;Password=WiNi6287!;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"

az webapp identity assign --name "webapp-$name" --resource-group $resourceGroup

sleep 30
principalId=$(az webapp show --name "webapp-$name" --resource-group $resourceGroup --query identity.principalId -o tsv)

userPrincipalName=$(az account show --query user.name -o tsv)

keyVaultId=$(az keyvault show --name $keyvaultname --resource-group $resourceGroup --query id -o tsv)

echo "KeyVault ID:"
echo $keyVaultId

echo "Assigning Key Vault roles..."


sleep 10
az keyvault secret set --vault-name $keyvaultname --name "DbConnectionString" --value "$connStr"


az webapp config appsettings set --name "webapp-$name" --resource-group $resourceGroup --settings KeyVaultUri="https://$keyvaultname.vault.azure.net/"

az keyvault secret set --vault-name $keyvaultname --name "StorageConnectionString" --value "$storageConnStr"


# Upload to container
echo "Hello blob storage" > test.txt

az storage blob upload --account-name $storagename --account-key "$accountKey" --container-name "$containername" --name "test.txt" --file "./test.txt"

# Create Insight
az monitor app-insights component create --app "appi-$name" --location $location --resource-group $resourceGroup --application-type web

connectionString=$(az monitor app-insights component show --app "appi-$name" --resource-group $resourceGroup --query connectionString --output tsv)

az webapp config appsettings set --name "webapp-$name" --resource-group $resourceGroup --settings APPLICATIONINSIGHTS_CONNECTION_STRING="$connectionString"


# Add Logging



# Add Security
az webapp update --name "webapp-$name" --resource-group $resourceGroup --https-only true

az webapp config access-restriction add --resource-group $resourceGroup --name "webapp-$name" --rule-name AllowMyIP --action Allow --ip-address 94.255.134.207 --priority 100

#Create firewall-rule 
az sql server firewall-rule create --resource-group $resourceGroup --server "server-$name" --name AllowMyIP --start-ip-address 94.255.134.207 --end-ip-address 94.255.134.207

az sql server firewall-rule create --resource-group $resourceGroup --server "server-$name" --name AllowAzureServices --start-ip-address 0.0.0.0 --end-ip-address 0.0.0.0




# Github Actions
git init
git add .
git commit -m "Initial commit"
git branch -M main
git remote add origin https://github.com/Tewini1129/Molnl-sningar_Labb-1_Api.git
git push -u origin main


# deploy to app service
az webapp deployment list-publishing-profiles --name "webapp-$name" --resource-group $resourceGroup --xml


echo "Now its time to enable SCM Basic Auth Publishing Credentials and FTP Basic Auth Publishing Credentials"
echo "1. Go to the Azure Portal"
echo "2. Go to Web App 'webapp-$name'"
echo "3. Click on Settings > Configuration > General settings and enable both 'Scm Basic Auth Publishing Credentials' and 'FTP Basic Auth Publishing Credentials'"
echo "4. Thats it! You can now deploy your code using FTP or Local Git. You can also use the publishing profile to deploy using Visual Studio or Github Actions"


