using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MakeYourBrain.Infrastructure.Data;
using MakeYourBrain.Api.Extensions;
using MakeYourBrain.Application.Services;
using MakeYourBrain.Infrastructure.Services;
using Dapper;

namespace MakeYourBrain.Api.Controllers;

[ApiController]
[Route("functions/v1/send-streak-reminders")]
[Authorize]
public class SendStreakRemindersController(
    DapperConnectionFactory db,
    FirebaseFcmService fcmService,
    ILogger<SendStreakRemindersController> logger) : ControllerBase
{
    [HttpPost]
    public async Task<IActionResult> SendReminders()
    {
        if (!User.IsServiceRole())
            return StatusCode(403, new { error = "Forbidden" });

        var nowUtc = DateTime.UtcNow;
        var nowUtcHour = nowUtc.Hour;

        // Find UTC offsets where local time is 22h right now
        var targetOffsets = Enumerable.Range(-12, 27)
            .Where(offset => ((nowUtcHour + offset) + 24) % 24 == 22)
            .ToList();

        if (targetOffsets.Count == 0)
            return Ok(new { success = true, message = "No timezone at 22h right now", sent = 0 });

        using var conn = db.CreateConnection();

        var users = (await conn.QueryAsync(
            """
            SELECT user_id, current_streak, last_played_at, preferred_language, timezone_offset_hours
            FROM user_stats
            WHERE current_streak >= 2
            AND timezone_offset_hours = ANY(@offsets)
            """,
            new { offsets = targetOffsets.ToArray() })).ToList();

        if (users.Count == 0)
            return Ok(new { success = true, message = "No eligible users", sent = 0 });

        // Filter users whose streak is saveable (played yesterday, not today)
        var usersToNotify = users.Where(u =>
        {
            if (u.last_played_at is null) return false;
            int offset = u.timezone_offset_hours ?? 0;
            var localNow = nowUtc.AddHours(offset);
            var localLastPlayed = ((DateTime)u.last_played_at).AddHours(offset);
            var todayStr = localNow.ToString("yyyy-MM-dd");
            var lastPlayedStr = localLastPlayed.ToString("yyyy-MM-dd");
            var yesterdayStr = localNow.AddDays(-1).ToString("yyyy-MM-dd");
            return lastPlayedStr == yesterdayStr && todayStr != lastPlayedStr;
        }).ToList();

        if (usersToNotify.Count == 0)
            return Ok(new { success = true, message = "All eligible users already played today", sent = 0 });

        int sent = 0;

        foreach (var user in usersToNotify)
        {
            var tokens = (await conn.QueryAsync<string>(
                "SELECT token FROM user_fcm_tokens WHERE user_id = @userId",
                new { userId = (Guid)user.user_id })).ToList();

            if (tokens.Count == 0) continue;

            var lang = (string?)user.preferred_language ?? "en";
            var streak = (int)(user.current_streak ?? 0);
            var title = lang == "fr" ? "ðŸ”¥ Ne perds pas ta sÃ©rie !" : "ðŸ”¥ Don't lose your streak!";
            var body = lang == "fr"
                ? $"Tu as {streak} jour{(streak > 1 ? "s" : "")} de suite. Joue maintenant avant minuit !"
                : $"You have a {streak}-day streak. Play now before midnight!";

            try
            {
                var staleTokens = await fcmService.SendAndGetStaleTokensAsync(tokens, title, body,
                    new Dictionary<string, string> { ["type"] = "streak" });

                if (staleTokens.Count > 0)
                {
                    await conn.ExecuteAsync(
                        "DELETE FROM user_fcm_tokens WHERE token = ANY(@staleTokens)",
                        new { staleTokens = staleTokens.ToArray() });
                    logger.LogInformation("Removed {Count} stale FCM token(s) for user {UserId}",
                        staleTokens.Count, (Guid)user.user_id);
                }

                sent++;
            }
            catch (Exception ex)
            {
                logger.LogWarning(ex, "Failed to send streak reminder to user {UserId}", (Guid)user.user_id);
            }
        }

        return Ok(new { success = true, sent });
    }
}


