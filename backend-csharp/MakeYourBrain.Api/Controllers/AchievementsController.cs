using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MakeYourBrain.Api.Extensions;
using MakeYourBrain.Application.Services;
using MakeYourBrain.Infrastructure.Services;

namespace MakeYourBrain.Api.Controllers;

[ApiController]
[Route("achievements")]
[Authorize]
public class AchievementsController(AchievementService achievements) : ControllerBase
{
    /// <summary>
    /// Runs check_achievements for the authenticated user and returns newly unlocked achievements.
    /// Call this after any quiz completion or PvP match.
    /// </summary>
    [HttpPost("check")]
    public async Task<IActionResult> Check()
    {
        var userId = User.GetUserId();
        var unlocked = await achievements.CheckAndGetNewAchievementsAsync(userId);
        return Ok(unlocked);
    }
}


