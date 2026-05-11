using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MakeYourBrain.Api.Extensions;
using MakeYourBrain.Application.Services;
using MakeYourBrain.Infrastructure.Services;

namespace MakeYourBrain.Api.Controllers;

[ApiController]
[Route("lives")]
[Authorize]
public class LivesController(LivesService lives) : ControllerBase
{
    [HttpGet]
    public async Task<IActionResult> GetLives()
    {
        var userId = User.GetUserId();
        var result = await lives.GetUserLivesAsync(userId);
        return result is null ? NotFound() : Ok(result);
    }

    [HttpPost("use")]
    public async Task<IActionResult> UseLife()
    {
        var userId = User.GetUserId();
        var success = await lives.UseLifeAsync(userId);
        return Ok(new { success });
    }

    [HttpPost("regenerate")]
    public async Task<IActionResult> Regenerate()
    {
        var userId = User.GetUserId();
        var result = await lives.RegenerateLivesAsync(userId);
        return Ok(result);
    }
}


