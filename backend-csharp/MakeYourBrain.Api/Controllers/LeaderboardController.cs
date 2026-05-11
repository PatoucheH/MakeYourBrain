using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MakeYourBrain.Api.Extensions;
using MakeYourBrain.Application.Services;

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

    [HttpGet("global")]
    [AllowAnonymous]
    public async Task<IActionResult> GetGlobal([FromQuery] int limit = 100)
    {
        var entries = await leaderboard.GetGlobalLeaderboardAsync(limit);
        return Ok(entries);
    }

    [HttpGet("theme/{themeId:guid}")]
    [AllowAnonymous]
    public async Task<IActionResult> GetTheme(Guid themeId, [FromQuery] int limit = 100)
    {
        var entries = await leaderboard.GetThemeLeaderboardAsync(themeId, limit);
        return Ok(entries);
    }

    [HttpGet("rank/global")]
    public async Task<IActionResult> GetUserGlobalRank()
    {
        var userId = User.GetUserId();
        var rank = await leaderboard.GetUserGlobalRankAsync(userId);
        return rank is null ? NotFound() : Ok(new { rank });
    }

    [HttpGet("rank/theme/{themeId:guid}")]
    public async Task<IActionResult> GetUserThemeRank(Guid themeId)
    {
        var userId = User.GetUserId();
        var rank = await leaderboard.GetUserThemeRankAsync(userId, themeId);
        return rank is null ? NotFound() : Ok(new { rank });
    }
}


