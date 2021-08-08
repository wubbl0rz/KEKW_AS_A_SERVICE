using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;

namespace KEKW_AS_A_SERVICE.Controllers
{
  [ApiController]
  [Route("/")]
  public class KEKWController : ControllerBase
  {
    [HttpGet]
    public IActionResult Get()
    {
      var random = new Random();
      var n = random.Next(0, 360);
      
      var file = System.IO.File.OpenRead($"wwwroot/out{n}.png");

      return File(file, "image/png");
    }
  }
}