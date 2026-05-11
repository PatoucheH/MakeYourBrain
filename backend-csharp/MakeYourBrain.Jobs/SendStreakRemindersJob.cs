using Dapper;
using MakeYourBrain.Infrastructure.Data;
using MakeYourBrain.Infrastructure.Services;

namespace MakeYourBrain.Jobs;

public class SendStreakRemindersJob(
    DapperConnectionFactory db,
    FirebaseFcmService fcm,
    ILogger<SendStreakRemindersJob> logger)
{
    public async Task ExecuteAsync()
    {
        var nowUtc = DateTime.UtcNow;

        // Integer UTC offsets where local time == 22:00 right now
        var targetOffsets = Enumerable.Range(-12, 27)
            .Where(o => ((nowUtc.Hour + o) % 24 + 24) % 24 == 22)
            .ToList();

        if (targetOffsets.Count == 0)
        {
            logger.LogDebug("send-streak-reminders: no timezone at 22h right now, skipping");
            return;
        }

        using var conn = db.CreateConnection();

        var users = (await conn.QueryAsync("""
            SELECT user_id, current_streak, last_played_at, preferred_language, timezone_offset_hours
            FROM user_stats
            WHERE current_streak >= 2
              AND timezone_offset_hours = ANY(@targetOffsets)
            """,
            new { targetOffsets = targetOffsets.ToArray() })).ToList();

        if (users.Count == 0)
        {
            logger.LogDebug("send-streak-reminders: no eligible users in target timezones");
            return;
        }

        // Keep only users who played yesterday (local) but not yet today
        var eligible = users.Where(u =>
        {
            if (u.last_played_at is null) return false;
            var offset = (int)(u.timezone_offset_hours ?? 0);
            var localNow       = nowUtc.AddHours(offset);
            var localLastPlayed = ((DateTime)u.last_played_at).AddHours(offset);
            var yesterdayStr   = localNow.AddDays(-1).ToString("yyyy-MM-dd");
            return localLastPlayed.ToString("yyyy-MM-dd") == yesterdayStr;
        }).ToList();

        if (eligible.Count == 0)
        {
            logger.LogInformation("send-streak-reminders: all eligible users already played today");
            return;
        }

        int sent = 0;

        foreach (var user in eligible)
        {
            var tokens = (await conn.QueryAsync<string>(
                "SELECT token FROM user_fcm_tokens WHERE user_id = @userId",
                new { userId = (Guid)user.user_id })).ToList();

            if (tokens.Count == 0) continue;

            var lang   = (string?)user.preferred_language ?? "en";
            var streak = (int)user.current_streak;

            var title = lang == "fr"
                ? "ðŸ”¥ Ne perds pas ta sÃ©rie !"
                : "ðŸ”¥ Don't lose your streak!";

            var body = lang == "fr"
                ? $"Tu as {streak} jour{(streak > 1 ? "s" : "")} de suite. Joue maintenant avant minuit !"
                : $"You have a {streak}-day streak. Play now before midnight!";

            var staleTokens = await fcm.SendAndGetStaleTokensAsync(
                tokens, title, body,
                new Dictionary<string, string> { ["type"] = "streak" });

            if (staleTokens.Count > 0)
            {
                await conn.ExecuteAsync(
                    "DELETE FROM user_fcm_tokens WHERE token = ANY(@tokens)",
                    new { tokens = staleTokens.ToArray() });

                logger.LogInformation(
                    "Removed {Count} stale FCM token(s) for user {UserId}",
                    staleTokens.Count, (Guid)user.user_id);
            }

            sent++;
        }

        logger.LogInformation("send-streak-reminders: {Sent}/{Total} users notified", sent, eligible.Count);
    }
}

