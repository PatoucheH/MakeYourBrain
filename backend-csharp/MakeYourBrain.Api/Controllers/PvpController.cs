using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MakeYourBrain.Api.Infrastructure.Extensions;
using MakeYourBrain.Api.Models.Dtos;
using MakeYourBrain.Api.Services;

namespace MakeYourBrain.Api.Controllers;

[ApiController]
[Route("pvp")]
[Authorize]
public class PvpController(PvpService pvp) : ControllerBase
{
    // ─── Matchmaking ──────────────────────────────────────────────────────

    [HttpPost("queue/join")]
    public async Task<IActionResult> JoinQueue([FromBody] PvpJoinQueueRequest req)
    {
        var userId = User.GetUserId();
        var result = await pvp.JoinQueueAsync(userId, req.PreferredLanguage);
        return Ok(result);
    }

    [HttpDelete("queue")]
    public async Task<IActionResult> LeaveQueue()
    {
        var userId = User.GetUserId();
        await pvp.LeaveQueueAsync(userId);
        return Ok();
    }

    [HttpGet("queue/status")]
    public async Task<IActionResult> CheckQueueStatus()
    {
        var userId = User.GetUserId();
        var statusJson = await pvp.CheckQueueStatusAsync(userId);
        return Content(statusJson, "application/json");
    }

    // ─── Polling (replaces Supabase Realtime streams) ─────────────────────

    [HttpGet("match/{matchId:guid}")]
    public async Task<IActionResult> GetMatch(Guid matchId)
    {
        var userId = User.GetUserId();
        var match = await pvp.GetMatchAsync(matchId, userId);
        return match is null ? Forbid() : Ok(match);
    }

    [HttpGet("match/{matchId:guid}/rounds")]
    public async Task<IActionResult> GetRounds(Guid matchId)
    {
        var userId = User.GetUserId();
        var rounds = await pvp.GetRoundsAsync(matchId, userId);
        return Ok(rounds);
    }

    [HttpGet("matches")]
    public async Task<IActionResult> GetMyMatches([FromQuery] int limit = 20)
    {
        var userId = User.GetUserId();
        var matches = await pvp.GetMyMatchesAsync(userId, limit);
        return Ok(matches);
    }

    // ─── Match lifecycle ──────────────────────────────────────────────────

    [HttpPatch("match/{matchId:guid}/status")]
    public async Task<IActionResult> UpdateMatchStatus(Guid matchId, [FromBody] PvpUpdateMatchStatusRequest req)
    {
        var userId = User.GetUserId();
        var match = await pvp.GetMatchAsync(matchId, userId);
        if (match is null) return Forbid();
        await pvp.UpdateMatchStatusAsync(matchId, req.Status, userId, req.CurrentRound);
        return Ok();
    }

    [HttpPost("match/{matchId:guid}/complete")]
    public async Task<IActionResult> CompleteMatch(Guid matchId)
    {
        var userId = User.GetUserId();
        var match = await pvp.GetMatchAsync(matchId, userId);
        if (match is null) return Forbid();
        await pvp.CompleteMatchAsync(matchId);
        return Ok();
    }

    // ─── Rounds ───────────────────────────────────────────────────────────

    [HttpPost("rounds")]
    public async Task<IActionResult> CreateRound([FromBody] PvpCreateRoundRequest req)
    {
        var userId = User.GetUserId();
        var match = await pvp.GetMatchAsync(req.MatchId, userId);
        if (match is null) return Forbid();
        var roundId = await pvp.CreateRoundAsync(req.MatchId, req.RoundNumber, req.QuestionIds, req.ThemeId);
        return Ok(new { round_id = roundId });
    }

    [HttpPost("rounds/submit")]
    public async Task<IActionResult> SubmitRound([FromBody] PvpSubmitRoundRequest req)
    {
        var userId = User.GetUserId();
        var match = await pvp.GetMatchAsync(req.MatchId, userId);
        if (match is null) return Forbid();
        await pvp.SubmitRoundAnswersAsync(req.MatchId, req.RoundNumber, userId, req.AnswersJson);
        return Ok();
    }

    // ─── Questions ────────────────────────────────────────────────────────

    [HttpGet("questions")]
    public async Task<IActionResult> GetRandomQuestions(
        [FromQuery] string? themeId,
        [FromQuery] string language = "en",
        [FromQuery] int limit = 5)
    {
        var userId = User.GetUserId();
        IEnumerable<dynamic> questions = themeId is null
            ? await pvp.GetRandomQuestionsByThemeAsync(language, limit)
            : await pvp.GetRandomQuestionsAsync(themeId, language, limit, await pvp.GetUserRatingAsync(userId));
        return Ok(questions);
    }

    [HttpPost("questions/by-ids")]
    public async Task<IActionResult> GetQuestionsByIds(
        [FromBody] GetQuestionsByIdsRequest req)
    {
        var questions = await pvp.GetQuestionsByIdsAsync(req.QuestionIds, req.Language);
        return Ok(questions);
    }

    [HttpGet("theme/random")]
    public async Task<IActionResult> GetRandomTheme(
        [FromQuery] string language = "en",
        [FromQuery] string[]? excludeIds = null)
    {
        var theme = await pvp.GetRandomThemeAsync(language, excludeIds);
        return theme is null ? NotFound() : Content(theme, "application/json");
    }

    // ─── Invitations ──────────────────────────────────────────────────────

    [HttpPost("invitations")]
    public async Task<IActionResult> SendInvitation([FromBody] PvpSendInvitationRequest req)
    {
        var userId = User.GetUserId();
        var invitationId = await pvp.SendInvitationAsync(userId, req.RecipientId);
        return Ok(new { invitation_id = invitationId });
    }

    [HttpPost("invitations/{invitationId:guid}/respond")]
    public async Task<IActionResult> RespondInvitation(
        Guid invitationId, [FromBody] bool accept)
    {
        var userId = User.GetUserId();
        var result = await pvp.RespondInvitationAsync(invitationId, userId, accept);
        return Ok(result);
    }

    [HttpGet("invitations/pending")]
    public async Task<IActionResult> GetPendingInvitations()
    {
        var userId = User.GetUserId();
        var invitations = await pvp.GetPendingInvitationsAsync(userId);
        return Ok(invitations);
    }

    // ─── PvP Leaderboard ──────────────────────────────────────────────────

    [HttpGet("leaderboard/following")]
    public async Task<IActionResult> GetFollowingLeaderboard()
    {
        var userId = User.GetUserId();
        IEnumerable<dynamic> entries = await pvp.GetFollowingLeaderboardAsync(userId);
        return Ok(entries);
    }

    // ─── Nested request records ───────────────────────────────────────────
    public record GetQuestionsByIdsRequest(Guid[] QuestionIds, string Language = "en");
}
