using MakeYourBrain.Api.Services;

namespace MakeYourBrain.Api.Jobs;

public class GenerateQuestionsJob(ClaudeApiService claude, ILogger<GenerateQuestionsJob> logger)
{
    public async Task ExecuteAsync()
    {
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
            throw; // let Hangfire retry
        }
    }
}
