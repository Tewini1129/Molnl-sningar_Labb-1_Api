using Azure.Storage.Blobs;
using Molnlösningar_Labb_1_Api.Core.Interfaces;

namespace Molnlösningar_Labb_1_Api.Core.Services
{
    public class BlobService : IBlobService
    {
        private readonly BlobContainerClient _containerClient;

        public BlobService(IConfiguration configuration)
        {
            var connectionString = configuration["StorageConnectionString"];
            var containerName = "backupslabbtest";
            var blobServiceClient = new BlobServiceClient(connectionString);

            _containerClient = blobServiceClient.GetBlobContainerClient(containerName);

        }
        public async Task<List<string>> GetAllFilesAsync()
        {
            var files = new List<string>();

            await foreach (var blob in _containerClient.GetBlobsAsync())
            {
                files.Add(blob.Name);
            }

            return files;
        }
    }
}
