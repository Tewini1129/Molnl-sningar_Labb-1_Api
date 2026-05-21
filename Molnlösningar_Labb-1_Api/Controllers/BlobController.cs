using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Molnlösningar_Labb_1_Api.Core.Interfaces;

namespace Molnlösningar_Labb_1_Api.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class BlobController : ControllerBase
    {
        private readonly IBlobService _service;

        public BlobController(IBlobService service)
        {
            _service = service;
        }


        [HttpGet("files")]
        public async Task<IActionResult> GetFiles()
        {
            var files = await _service.GetAllFilesAsync();
            return Ok(files);
        }
        [HttpGet("HelloWorld")]
        public IActionResult HelloWorld()
        {
            return Ok("Hello World");
        }
}
