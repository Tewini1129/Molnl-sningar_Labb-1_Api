namespace Molnlösningar_Labb_1_Api
{
    public class Program
    {
        public static void Main(string[] args)
        {
            var builder = WebApplication.CreateBuilder(args);
            var app = builder.Build();


            app.Run();
        }
    }
}
