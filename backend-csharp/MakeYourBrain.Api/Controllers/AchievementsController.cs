using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MakeYourBrain.Api.Extensions;
using MakeYourBrain.Application.Services;

namespace MakeYourBrain.Api.Controllers;

[ApiController]
[Route("achievements")]
[Authorize]
public class AchievementsController(AchievementService achievements) : ControllerBase
{
    [HttpGet]
    public async Task<IActionResult> GetAll()
    {
        var userId = User.GetUserId();
        var all = await achievements.GetAllWithUserStatusAsync(userId);
        return Ok(all);
    }

    [HttpPost("check")]
    public async Task<IActionResult> Check()
    {
        var userId = User.GetUserId();
        var unlocked = await achievements.CheckAndGetNewAchievementsAsync(userId);
        return Ok(unlocked);
    }
}


