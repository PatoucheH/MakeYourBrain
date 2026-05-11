using Dapper;
using MakeYourBrain.Application.Interfaces;

namespace MakeYourBrain.Application.Services;

public class SocialService(IDbConnectionFactory db)
{
    public async Task FollowUserAsync(Guid followerId, Guid followingId)
    {
        using var conn = db.CreateConnection();
        using var tran = conn.BeginTransaction();
        await conn.ExecuteAsync(
            "SELECT set_config('request.jwt.claim.sub', @sub, true)",
            new { sub = followerId.ToString() }, tran);
        await conn.ExecuteAsync("SELECT follow_user(@followingId)", new { followingId }, tran);
        tran.Commit();
    }

    public async Task UnfollowUserAsync(Guid followerId, Guid followingId)
    {
        using var conn = db.CreateConnection();
        using var tran = conn.BeginTransaction();
        await conn.ExecuteAsync(
            "SELECT set_config('request.jwt.claim.sub', @sub, true)",
            new { sub = followerId.ToString() }, tran);
        await conn.ExecuteAsync("SELECT unfollow_user(@followingId)", new { followingId }, tran);
        tran.Commit();
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
        using var tran = conn.BeginTransaction();
        await conn.ExecuteAsync(
            "SELECT set_config('request.jwt.claim.sub', @sub, true)",
            new { sub = requesterId.ToString() }, tran);
        var result = await conn.QueryAsync(
            "SELECT * FROM search_users(@query)", new { query }, tran);
        tran.Commit();
        return result;
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

