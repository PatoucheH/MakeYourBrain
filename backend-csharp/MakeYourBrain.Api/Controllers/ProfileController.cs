using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MakeYourBrain.Api.Extensions;
using MakeYourBrain.Application.Services;
using MakeYourBrain.Infrastructure.Services;

namespace MakeYourBrain.Api.Controllers;

[ApiController]
[Route("profile")]
[Authorize]
public class ProfileController(ProfileService profile, QuizService quiz) : ControllerBase
{
    public record UpdateDisplayNameRequest(string DisplayName);
    public record AddBonusXpRequest(Guid ThemeId, int Xp);
    public record AddThemeXpRequest(Guid ThemeId, bool IsCorrect);
    public record RegisterDeviceRequest(string FcmToken, string Platform, int TimezoneOffsetHours);
    public record RemoveDeviceRequest(string FcmToken);

    // â”€â”€â”€ Profile summary â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    [HttpGet]
    public async Task<IActionResult> GetProfile()
    {
        var userId = User.GetUserId();
        var summary = await profile.GetUserProfileSummaryAsync(userId, userId);
        return summary is null ? NotFound() : Ok(summary);
    }

    // Public â€” anyone can view another user's player info
    [HttpGet("player/{userId:guid}")]
    [AllowAnonymous]
    public async Task<IActionResult> GetPlayerInfo(Guid userId)
    {
        var info = await profile.GetPlayerInfoAsync(userId);
        return info is null ? NotFound() : Ok(info);
    }

    [HttpPatch("display-name")]
    public async Task<IActionResult> UpdateDisplayName([FromBody] UpdateDisplayNameRequest req)
    {
        var userId = User.GetUserId();
        await profile.UpdateDisplayNameAsync(userId, req.DisplayName);
        return Ok();
    }

    // â”€â”€â”€ XP helpers â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    [HttpPost("xp/bonus")]
    public async Task<IActionResult> AddBonusXp([FromBody] AddBonusXpRequest req)
    {
        var userId = User.GetUserId();
        await profile.AddBonusXpAsync(userId, req.ThemeId, req.Xp);
        return Ok();
    }

    [HttpPost("xp/theme")]
    public async Task<IActionResult> AddThemeXp([FromBody] AddThemeXpRequest req)
    {
        var userId = User.GetUserId();
        await profile.AddThemeXpAsync(userId, req.ThemeId, req.IsCorrect);
        return Ok();
    }

    // â”€â”€â”€ Level helpers â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    [HttpGet("level")]
    public async Task<IActionResult> GetLevel([FromQuery] int xp)
    {
        var level = await profile.CalculateLevelFromXpAsync(xp);
        var cumXp  = await profile.CumulativeXpForLevelAsync(level);
        return Ok(new { level, cumulative_xp = cumXp });
    }

    // â”€â”€â”€ Progress by theme â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    [HttpGet("progress")]
    public async Task<IActionResult> GetProgressByTheme([FromQuery] string language = "en")
    {
        var userId = User.GetUserId();
        var progress = await quiz.GetUserProgressByThemeAsync(userId, language);
        return Ok(progress);
    }

    // â”€â”€â”€ Device (FCM token + timezone) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    [HttpPost("device")]
    public async Task<IActionResult> RegisterDevice([FromBody] RegisterDeviceRequest req)
    {
        var userId = User.GetUserId();
        await profile.RegisterFcmTokenAsync(userId, req.FcmToken, req.Platform, req.TimezoneOffsetHours);
        return Ok();
    }

    [HttpDelete("device")]
    public async Task<IActionResult> RemoveDevice([FromBody] RemoveDeviceRequest req)
    {
        var userId = User.GetUserId();
        await profile.RemoveFcmTokenAsync(userId, req.FcmToken);
        return Ok();
    }
}


