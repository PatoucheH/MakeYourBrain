using Dapper;
using MakeYourBrain.Infrastructure.Data;

namespace MakeYourBrain.Jobs;

public class CleanupMatchmakingQueueJob(
    DapperConnectionFactory db,
    ILogger<CleanupMatchmakingQueueJob> logger)
{
    public async Task ExecuteAsync()
    {
        using var conn = db.CreateConnection();
        await conn.ExecuteAsync("SELECT clean_old_matchmaking_queue()");
        logger.LogDebug("cleanup-matchmaking-queue: clean_old_matchmaking_queue() executed");
    }
}

