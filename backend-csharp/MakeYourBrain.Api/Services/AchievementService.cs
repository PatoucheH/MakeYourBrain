using Dapper;
using MakeYourBrain.Api.Infrastructure;

namespace MakeYourBrain.Api.Services;

public class AchievementService(DapperConnectionFactory db)
{
    public async Task<IEnumerable<dynamic>> CheckAndGetNewAchievementsAsync(Guid userId)
    {
        using var conn = db.CreateConnection();
        var unlocked = (await conn.QueryAsync(
            "SELECT * FROM check_achievements(@userId)",
            new { userId })).ToList();

        foreach (var achievement in unlocked)
        {
            var xpReward = Convert.ToInt32(
                ((IDictionary<string, object>)achievement)["xp_reward"] ?? 0);
            if (xpReward <= 0) continue;

            var topTheme = await conn.ExecuteScalarAsync<Guid?>(
                "SELECT theme_id FROM user_theme_progress WHERE user_id = @userId ORDER BY xp DESC LIMIT 1",
                new { userId });
            if (topTheme.HasValue)
                await conn.ExecuteAsync(
                    "SELECT add_bonus_xp(@userId, @themeId, @xp)",
                    new { userId, themeId = topTheme.Value, xp = xpReward });
        }

        return unlocked;
    }
}
