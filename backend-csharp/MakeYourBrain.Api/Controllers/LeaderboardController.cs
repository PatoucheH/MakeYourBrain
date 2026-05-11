using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MakeYourBrain.Api.Extensions;
using MakeYourBrain.Application.Services;
using MakeYourBrain.Infrastructure.Services;

namespace MakeYourBrain.Api.Controllers;

[ApiController]
[Route("leaderboard")]
[Authorize]
public class LeaderboardController(LeaderboardService leaderboard, PvpService pvp) : ControllerBase
{
    // Public â€” anyone can see global weekly leaderboard
    [HttpGet("weekly")]
    [AllowAnonymous]
    public async Task<IActionResult> GetWeekly()
    {
        var entries = await leaderboard.GetWeeklyLeaderboardAsync();
        return Ok(entries);
    }

    [HttpGet("following")]
    public async Task<IActionResult> GetFollowing()
    {
        var userId = User.GetUserId();
        var entries = await leaderboard.GetFollowingLeaderboardAsync(userId);
        return Ok(entries);
    }

    [HttpGet("survival/{themeId:guid}")]
    [AllowAnonymous]
    public async Task<IActionResult> GetSurvival(Guid themeId, [FromQuery] int limit = 20)
    {
        var entries = await leaderboard.GetSurvivalLeaderboardAsync(themeId, limit);
        return Ok(entries);
    }

    [HttpGet("pvp/following")]
    public async Task<IActionResult> GetPvpFollowing()
    {
        var userId = User.GetUserId();
        var entries = await pvp.GetFollowingLeaderboardAsync(userId);
        return Ok(entries);
    }
}


