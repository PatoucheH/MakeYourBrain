using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MakeYourBrain.Api.Infrastructure.Extensions;
using MakeYourBrain.Api.Services;

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

    // ─── Profile summary ──────────────────────────────────────────────────
    [HttpGet]
    public async Task<IActionResult> GetProfile()
    {
        var userId = User.GetUserId();
        var summary = await profile.GetUserProfileSummaryAsync(userId, userId);
        return summary is null ? NotFound() : Ok(summary);
    }

    // Public — anyone can view another user's player info
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

    // ─── XP helpers ───────────────────────────────────────────────────────
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

    // ─── Level helpers ────────────────────────────────────────────────────
    [HttpGet("level")]
    public async Task<IActionResult> GetLevel([FromQuery] int xp)
    {
        var level = await profile.CalculateLevelFromXpAsync(xp);
        var cumXp  = await profile.CumulativeXpForLevelAsync(level);
        return Ok(new { level, cumulative_xp = cumXp });
    }

    // ─── Progress by theme ────────────────────────────────────────────────
    [HttpGet("progress")]
    public async Task<IActionResult> GetProgressByTheme([FromQuery] string language = "en")
    {
        var userId = User.GetUserId();
        var progress = await quiz.GetUserProgressByThemeAsync(userId, language);
        return Ok(progress);
    }

    // ─── Device (FCM token + timezone) ───────────────────────────────────
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
