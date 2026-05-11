using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MakeYourBrain.Api.Infrastructure.Extensions;
using MakeYourBrain.Api.Services;

namespace MakeYourBrain.Api.Controllers;

[ApiController]
[Route("quiz")]
[Authorize]
public class QuizController(QuizService quiz) : ControllerBase
{
    // ─── Request records ─────────────────────────────────────────────────
    public record RandomQuestionsRequest(Guid ThemeId, string Language, int Limit = 10);
    public record SaveAnswerRequest(Guid QuestionId, Guid AnswerId, bool IsCorrect, string Language = "en");
    public record AddXpRequest(Guid ThemeId, Guid[] QuestionIds, Guid[] AnswerIds, bool IsDaily);
    public record UpdateStatsRequest(int TotalDelta, int CorrectDelta, bool UpdateStreak = true);
    public record SurvivalScoreRequest(Guid ThemeId, int Score);
    public record CompleteDailyRequest(Guid? ConceptId = null);
    public record UpdateLanguageRequest(string Language);

    // ─── Random questions ─────────────────────────────────────────────────
    [HttpPost("random")]
    public async Task<IActionResult> GetRandomQuestions([FromBody] RandomQuestionsRequest req)
    {
        var questions = await quiz.GetRandomQuestionsAsync(req.ThemeId, req.Language, req.Limit);
        return Ok(questions);
    }

    // ─── Save user answer ─────────────────────────────────────────────────
    [HttpPost("answer")]
    public async Task<IActionResult> SaveAnswer([FromBody] SaveAnswerRequest req)
    {
        var userId = User.GetUserId();
        await quiz.SaveUserAnswerAsync(userId, req.QuestionId, req.AnswerId, req.IsCorrect, req.Language);
        return Ok();
    }

    // ─── XP & stats ───────────────────────────────────────────────────────
    [HttpPost("xp")]
    public async Task<IActionResult> AddXp([FromBody] AddXpRequest req)
    {
        var userId = User.GetUserId();
        var xpGained = await quiz.AddQuizCompletionXpAsync(userId, req.ThemeId, req.QuestionIds, req.AnswerIds, req.IsDaily);
        return Ok(new { xp_gained = xpGained });
    }

    [HttpPost("stats")]
    public async Task<IActionResult> UpdateStats([FromBody] UpdateStatsRequest req)
    {
        var userId = User.GetUserId();
        await quiz.IncrementUserStatsAsync(userId, req.TotalDelta, req.CorrectDelta, req.UpdateStreak);
        return Ok();
    }

    [HttpPost("streak")]
    public async Task<IActionResult> UpdateStreak()
    {
        var userId = User.GetUserId();
        await quiz.UpdateUserStreakAsync(userId);
        return Ok();
    }

    // ─── Progress ─────────────────────────────────────────────────────────
    [HttpGet("progress")]
    public async Task<IActionResult> GetProgressByTheme([FromQuery] string language = "en")
    {
        var userId = User.GetUserId();
        var progress = await quiz.GetUserProgressByThemeAsync(userId, language);
        return Ok(progress);
    }

    // ─── Language ─────────────────────────────────────────────────────────
    [HttpPatch("language")]
    public async Task<IActionResult> UpdateLanguage([FromBody] UpdateLanguageRequest req)
    {
        var userId = User.GetUserId();
        await quiz.UpdateUserLanguageAsync(userId, req.Language);
        return Ok();
    }

    // ─── Daily quiz ───────────────────────────────────────────────────────
    [HttpGet("daily")]
    public async Task<IActionResult> GetDailyConcept([FromQuery] string language = "en")
    {
        var userId = User.GetUserId();
        var concept = await quiz.GetDailyConceptAsync(userId, language);
        return concept is null ? NotFound() : Ok(concept);
    }

    [HttpGet("daily/{conceptId:guid}/questions")]
    public async Task<IActionResult> GetDailyQuestions(Guid conceptId, [FromQuery] string language = "en")
    {
        // conceptId kept in URL for Flutter client compatibility; SQL function selects latest concept internally
        var questions = await quiz.GetDailyQuestionsAsync(language);
        return Ok(questions);
    }

    [HttpPost("daily/complete")]
    public async Task<IActionResult> CompleteDailyConcept([FromBody] CompleteDailyRequest req)
    {
        var userId = User.GetUserId();
        await quiz.CompleteDailyConceptAsync(userId);
        await quiz.UpdateUserStreakAsync(userId);
        return Ok();
    }

    // ─── Survival mode ────────────────────────────────────────────────────
    [HttpPost("survival/score")]
    public async Task<IActionResult> SaveSurvivalScore([FromBody] SurvivalScoreRequest req)
    {
        var userId = User.GetUserId();
        await quiz.SaveSurvivalScoreAsync(userId, req.ThemeId, req.Score);
        return Ok();
    }

    [HttpGet("survival/scores")]
    public async Task<IActionResult> GetMySurvivalScores()
    {
        var userId = User.GetUserId();
        var scores = await quiz.GetMySurvivalScoresAsync(userId);
        return Ok(scores);
    }
}
