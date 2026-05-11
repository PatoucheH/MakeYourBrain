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

    public async Task<IEnumerable<dynamic>> GetGlobalLeaderboardAsync(int limit = 100)
    {
        using var conn = db.CreateConnection();
        return await conn.QueryAsync(
            "SELECT * FROM leaderboard_global ORDER BY total_xp DESC LIMIT @limit",
            new { limit });
    }

    public async Task<IEnumerable<dynamic>> GetThemeLeaderboardAsync(Guid themeId, int limit = 100)
    {
        using var conn = db.CreateConnection();
        return await conn.QueryAsync(
            "SELECT * FROM leaderboard_by_theme WHERE theme_id = @themeId ORDER BY xp DESC LIMIT @limit",
            new { themeId, limit });
    }

    public async Task<int?> GetUserGlobalRankAsync(Guid userId)
    {
        using var conn = db.CreateConnection();
        var userXp = await conn.ExecuteScalarAsync<int?>(
            "SELECT total_xp FROM leaderboard_global WHERE user_id = @userId",
            new { userId });
        if (userXp is null) return null;
        var countAbove = await conn.ExecuteScalarAsync<int>(
            "SELECT COUNT(*) FROM leaderboard_global WHERE total_xp > @userXp",
            new { userXp });
        return countAbove + 1;
    }

    public async Task<int?> GetUserThemeRankAsync(Guid userId, Guid themeId)
    {
        using var conn = db.CreateConnection();
        var userXp = await conn.ExecuteScalarAsync<int?>(
            "SELECT xp FROM leaderboard_by_theme WHERE user_id = @userId AND theme_id = @themeId",
            new { userId, themeId });
        if (userXp is null) return null;
        var countAbove = await conn.ExecuteScalarAsync<int>(
            "SELECT COUNT(*) FROM leaderboard_by_theme WHERE theme_id = @themeId AND xp > @userXp",
            new { themeId, userXp });
        return countAbove + 1;
    }
}

