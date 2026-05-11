using Dapper;
using MakeYourBrain.Api.Infrastructure;

namespace MakeYourBrain.Api.Services;

public class LivesService(DapperConnectionFactory db)
{
    public async Task<dynamic?> GetUserLivesAsync(Guid userId)
    {
        using var conn = db.CreateConnection();
        return await conn.QuerySingleOrDefaultAsync(
            "SELECT * FROM get_user_lives(@userId)",
            new { userId });
    }

    public async Task<bool> UseLifeAsync(Guid userId)
    {
        using var conn = db.CreateConnection();
        return await conn.ExecuteScalarAsync<bool>(
            "SELECT use_life(@userId)",
            new { userId });
    }

    public async Task<dynamic?> RegenerateLivesAsync(Guid userId)
    {
        using var conn = db.CreateConnection();
        // get_user_lives wraps regenerate_lives and converts next_life_in interval → next_life_in_seconds integer,
        // which is the format the Flutter client expects.
        return await conn.QuerySingleOrDefaultAsync(
            "SELECT * FROM get_user_lives(@userId)",
            new { userId });
    }

    public async Task AddLivesFromAdAsync(Guid userId)
    {
        using var conn = db.CreateConnection();
        await conn.ExecuteAsync(
            "SELECT add_lives_from_ad(@userId)",
            new { userId });
    }
}
