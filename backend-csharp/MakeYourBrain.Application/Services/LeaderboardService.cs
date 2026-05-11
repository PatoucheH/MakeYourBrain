using Dapper;
using MakeYourBrain.Application.Interfaces;

namespace MakeYourBrain.Application.Services;

public class LeaderboardService(IDbConnectionFactory db)
{
    public async Task<IEnumerable<dynamic>> GetWeeklyLeaderboardAsync()
    {
        using var conn = db.CreateConnection();
        return await conn.QueryAsync("SELECT * FROM get_weekly_leaderboard()");
    }

    public async Task<IEnumerable<dynamic>> GetFollowingLeaderboardAsync(Guid userId)
    {
        using var conn = db.CreateConnection();
        return await conn.QueryAsync(
            "SELECT * FROM get_following_leaderboard(@userId)",
            new { userId });
    }

    public async Task<IEnumerable<dynamic>> GetSurvivalLeaderboardAsync(Guid themeId, int limit = 20)
    {
        using var conn = db.CreateConnection();
        return await conn.QueryAsync(
            "SELECT * FROM get_survival_leaderboard(@themeId, @limit)",
            new { themeId, limit });
    }
}

