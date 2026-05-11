using Dapper;
using MakeYourBrain.Application.Interfaces;

namespace MakeYourBrain.Application.Services;

public class ProfileService(IDbConnectionFactory db)
{
    public async Task<dynamic?> GetUserProfileSummaryAsync(Guid targetUserId, Guid requesterId)
    {
        using var conn = db.CreateConnection();
        var profile = await conn.QuerySingleOrDefaultAsync(
            "SELECT * FROM get_user_profile_summary(@targetUserId)",
            new { targetUserId });
        if (profile is null) return null;

        // auth.uid() is NULL when called from C# (no PostgREST context), so compute is_following explicitly
        var isFollowing = targetUserId != requesterId && await conn.ExecuteScalarAsync<bool>(
            "SELECT EXISTS(SELECT 1 FROM user_follows WHERE follower_id = @requesterId AND following_id = @targetUserId)",
            new { requesterId, targetUserId });

        ((IDictionary<string, object>)profile)["is_following"] = isFollowing;
        return profile;
    }

    public async Task<dynamic?> GetPlayerInfoAsync(Guid userId)
    {
        using var conn = db.CreateConnection();
        return await conn.QuerySingleOrDefaultAsync(
            "SELECT * FROM get_player_info(@userId)",
            new { userId });
    }

    public async Task AddBonusXpAsync(Guid userId, Guid themeId, int xp)
    {
        using var conn = db.CreateConnection();
        await conn.ExecuteAsync(
            "SELECT add_bonus_xp(@userId, @themeId, @xp)",
            new { userId, themeId, xp });
    }

    public async Task AddThemeXpAsync(Guid userId, Guid themeId, bool isCorrect)
    {
        using var conn = db.CreateConnection();
        await conn.ExecuteAsync(
            "SELECT add_theme_xp(@userId, @themeId, @isCorrect)",
            new { userId, themeId, isCorrect });
    }

    public async Task<int> CalculateLevelFromXpAsync(int xp)
    {
        using var conn = db.CreateConnection();
        return await conn.ExecuteScalarAsync<int>(
            "SELECT calculate_level_from_xp(@xp)",
            new { xp });
    }

    public async Task<int> CumulativeXpForLevelAsync(int level)
    {
        using var conn = db.CreateConnection();
        return await conn.ExecuteScalarAsync<int>(
            "SELECT cumulative_xp_for_level(@level)",
            new { level });
    }

    public async Task UpdateDisplayNameAsync(Guid userId, string displayName)
    {
        using var conn = db.CreateConnection();
        await conn.ExecuteAsync(
            "UPDATE user_profiles SET display_name = @displayName WHERE user_id = @userId",
            new { userId, displayName });
    }

    public async Task RegisterFcmTokenAsync(Guid userId, string token, string platform, int timezoneOffsetHours)
    {
        using var conn = db.CreateConnection();
        await conn.ExecuteAsync(
            """
            INSERT INTO user_fcm_tokens (user_id, token, platform)
            VALUES (@userId, @token, @platform)
            ON CONFLICT (user_id, token) DO UPDATE SET platform = @platform, updated_at = NOW()
            """,
            new { userId, token, platform });
        await conn.ExecuteAsync(
            "UPDATE user_stats SET timezone_offset_hours = @offset WHERE user_id = @userId",
            new { userId, offset = timezoneOffsetHours });
    }

    public async Task RemoveFcmTokenAsync(Guid userId, string token)
    {
        using var conn = db.CreateConnection();
        await conn.ExecuteAsync(
            "DELETE FROM user_fcm_tokens WHERE user_id = @userId AND token = @token",
            new { userId, token });
    }
}

