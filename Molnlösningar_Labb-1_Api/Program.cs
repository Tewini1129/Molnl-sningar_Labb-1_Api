using Azure.Identity;
using Molnlösningar_Labb_1_Api.Core.Interfaces;
using Molnlösningar_Labb_1_Api.Core.Services;

namespace Molnlösningar_Labb_1_Api
{
    public class Program
    {
        public static void Main(string[] args)
        {
            var builder = WebApplication.CreateBuilder(args);


            var keyVaultUri = builder.Configuration["KeyVaultUri"];

            if (!string.IsNullOrEmpty(keyVaultUri))
            {
                builder.Configuration.AddAzureKeyVault(
                    new Uri(keyVaultUri),
                    new DefaultAzureCredential());
            }

            var storageConn = builder.Configuration["StorageConnectionString"];

            var conn = builder.Configuration["DbConnectionString"];

            builder.Services.AddScoped<IBlobService, BlobService>();
            builder.Services.AddControllers();

            var app = builder.Build();
            Console.WriteLine("Triggering actions");

            app.MapControllers();

            app.Run();
        }
    }
}
