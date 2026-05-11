using Dapper;
using MakeYourBrain.Infrastructure.Data;
using MakeYourBrain.Infrastructure.Services;

namespace MakeYourBrain.Jobs;

public class GenerateQuestionsJob(
    ClaudeApiService claude,
    DapperConnectionFactory db,
    ILogger<GenerateQuestionsJob> logger)
{
    public async Task ExecuteAsync()
    {
        using var conn = db.CreateConnection();

        // Guard: skip if a concept was already generated today (mirrors Supabase pg_cron WHERE NOT EXISTS)
        var alreadyDone = await conn.ExecuteScalarAsync<bool>(
            "SELECT EXISTS(SELECT 1 FROM question_concepts WHERE created_at >= date_trunc('day', NOW() AT TIME ZONE 'UTC'))");
        if (alreadyDone)
        {
            logger.LogDebug("generate-questions: concept already generated today, skipping");
            return;
        }

        logger.LogInformation("generate-questions job started");
        try
        {
            var result = await claude.GenerateQuestionsAsync(null, null, null);
            if (result.Success)
                logger.LogInformation(
                    "generate-questions: {Count} questions for '{Concept}' ({Theme})",
                    result.QuestionsGenerated, result.Concept, result.Theme);
            else
                logger.LogWarning("generate-questions skipped: {Message}", result.Message);
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "generate-questions job failed");
            throw; // let Hangfire retry at next scheduled hour
        }
    }
}

