using Dapper;
using MakeYourBrain.Api.Infrastructure;

namespace MakeYourBrain.Api.Services;

public class SocialService(DapperConnectionFactory db)
{
    public async Task FollowUserAsync(Guid followerId, Guid followingId)
    {
        using var conn = db.CreateConnection();
        await conn.ExecuteAsync(
            """
            INSERT INTO user_follows (follower_id, following_id)
            VALUES (@followerId, @followingId)
            ON CONFLICT (follower_id, following_id) DO NOTHING
            """,
            new { followerId, followingId });
    }

    public async Task UnfollowUserAsync(Guid followerId, Guid followingId)
    {
        using var conn = db.CreateConnection();
        await conn.ExecuteAsync(
            "DELETE FROM user_follows WHERE follower_id = @followerId AND following_id = @followingId",
            new { followerId, followingId });
    }

    public async Task<dynamic?> GetFollowCountsAsync(Guid userId)
    {
        using var conn = db.CreateConnection();
        return await conn.QuerySingleOrDefaultAsync(
            "SELECT * FROM get_follow_counts(@userId)",
            new { userId });
    }

    public async Task<IEnumerable<dynamic>> GetFollowersAsync(Guid userId)
    {
        using var conn = db.CreateConnection();
        return await conn.QueryAsync(
            "SELECT * FROM get_followers(@userId)",
            new { userId });
    }

    public async Task<IEnumerable<dynamic>> GetFollowingAsync(Guid userId)
    {
        using var conn = db.CreateConnection();
        return await conn.QueryAsync(
            "SELECT * FROM get_following(@userId)",
            new { userId });
    }

    public async Task<IEnumerable<dynamic>> SearchUsersAsync(Guid requesterId, string query)
    {
        using var conn = db.CreateConnection();
        return await conn.QueryAsync(
            """
            SELECT
              us.user_id,
              us.username,
              us.pvp_rating,
              us.total_questions,
              us.correct_answers,
              EXISTS (
                SELECT 1 FROM user_follows uf
                WHERE uf.follower_id = @requesterId AND uf.following_id = us.user_id
              ) AS is_following
            FROM user_stats us
            WHERE us.user_id != @requesterId
              AND us.username ILIKE '%' || @query || '%'
            ORDER BY
              CASE WHEN us.username ILIKE @query THEN 0
                   WHEN us.username ILIKE @query || '%' THEN 1
                   ELSE 2 END,
              us.username ASC
            LIMIT 20
            """,
            new { requesterId, query });
    }

    public async Task<string?> GetDisplayNameAsync(Guid userId, Guid? requesterId = null)
    {
        using var conn = db.CreateConnection();
        // Self-lookup: replicate the auth.uid() branch the SQL function cannot execute from C#
        if (requesterId.HasValue && requesterId.Value == userId)
        {
            var username = await conn.ExecuteScalarAsync<string?>(
                "SELECT username FROM user_stats WHERE user_id = @userId AND username IS NOT NULL AND username != ''",
                new { userId });
            if (username is not null) return username;

            var displayName = await conn.ExecuteScalarAsync<string?>(
                "SELECT display_name FROM user_profiles WHERE user_id = @userId AND display_name IS NOT NULL AND display_name != ''",
                new { userId });
            if (displayName is not null) return displayName;

            var email = await conn.ExecuteScalarAsync<string?>(
                "SELECT email FROM auth.users WHERE id = @userId",
                new { userId });
            return email ?? "Anonymous";
        }
        return await conn.ExecuteScalarAsync<string?>(
            "SELECT get_display_name(@userId)",
            new { userId });
    }
}
