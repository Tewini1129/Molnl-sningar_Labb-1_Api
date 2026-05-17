namespace Molnlösningar_Labb_1_Api.Core.Interfaces
{
    public interface IBlobService
    {
        Task<List<string>> GetAllFilesAsync();
    }
}
