using Dapper;
using MakeYourBrain.Application.Interfaces;
using MakeYourBrain.Domain.Dtos;

namespace MakeYourBrain.Application.Services;

/// <summary>
/// Wraps all pvp_* Dapper RPCs. Each method maps 1-to-1 to a PostgreSQL function.
/// </summary>
public class PvpService(IDbConnectionFactory db)
{
    // â”€â”€â”€ Matchmaking â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

    public async Task<dynamic> JoinQueueAsync(Guid userId, string language)
    {
        using var conn = db.CreateConnection();
        var rating = await conn.ExecuteScalarAsync<int>(
            "SELECT COALESCE(pvp_rating, 1000) FROM user_stats WHERE user_id = @userId",
            new { userId });
        return await conn.QuerySingleAsync(
            "SELECT * FROM pvp_join_queue(@userId, @rating, @language)",
            new { userId, rating, language });
    }

    public async Task LeaveQueueAsync(Guid userId)
    {
        using var conn = db.CreateConnection();
        await conn.ExecuteAsync(
            "SELECT pvp_leave_queue(@userId)",
            new { userId });
    }

    public async Task<string> CheckQueueStatusAsync(Guid userId)
    {
        using var conn = db.CreateConnection();
        var result = await conn.ExecuteScalarAsync<string>(
            "SELECT pvp_check_queue_status(@userId)",
            new { userId });
        return result ?? "{}";
    }

    // â”€â”€â”€ Rounds â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

    public async Task<Guid> CreateRoundAsync(Guid matchId, int roundNumber, string[] questionIds, string? themeId = null)
    {
        using var conn = db.CreateConnection();
        return await conn.ExecuteScalarAsync<Guid>(
            "SELECT pvp_create_round(@matchId, @roundNumber, @questionIds, @themeId)",
            new { matchId, roundNumber, questionIds, themeId });
    }

    public async Task SubmitRoundAnswersAsync(
        Guid matchId, int roundNumber, Guid playerId, string answersJson)
    {
        using var conn = db.CreateConnection();
        // p_score (last arg) is required by the SQL signature but completely ignored:
        // the function recalculates the score server-side from p_answers. Pass 0.
        await conn.ExecuteAsync(
            "SELECT pvp_submit_round_answers(@matchId, @roundNumber, @playerId, @answersJson::jsonb, 0)",
            new { matchId, roundNumber, playerId, answersJson });
    }

    // â”€â”€â”€ Match lifecycle â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

    public async Task UpdateMatchStatusAsync(Guid matchId, string status, Guid callerUserId, int? currentRound = null)
    {
        using var conn = db.CreateConnection();
        // Explicit C# participant check â€” pvp_update_match_status relies on auth.uid() which
        // is NULL in C# context, so the SQL-level guard is bypassed without this check.
        var isParticipant = await conn.ExecuteScalarAsync<bool>(
            """
            SELECT EXISTS(
                SELECT 1 FROM pvp_matches
                WHERE id = @matchId
                  AND (player1_id = @callerUserId OR player2_id = @callerUserId)
            )
            """,
            new { matchId, callerUserId });
        if (!isParticipant)
            throw new UnauthorizedAccessException(
                $"User {callerUserId} is not a participant in match {matchId}");

        await conn.ExecuteAsync(
            "SELECT pvp_update_match_status(@matchId, @status, @currentRound)",
            new { matchId, status, currentRound });
    }

    public async Task CompleteMatchAsync(Guid matchId)
    {
        using var conn = db.CreateConnection();
        await conn.ExecuteAsync(
            "SELECT pvp_complete_match(@matchId)",
            new { matchId });
    }

    // â”€â”€â”€ Questions â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

    public async Task<int> GetUserRatingAsync(Guid userId)
    {
        using var conn = db.CreateConnection();
        return await conn.ExecuteScalarAsync<int>(
            "SELECT COALESCE(pvp_rating, 1000) FROM user_stats WHERE user_id = @userId",
            new { userId });
    }

    // themeId specified â†’ fetch from that specific theme
    public async Task<IEnumerable<dynamic>> GetRandomQuestionsAsync(
        string themeId, string language, int limit = 5, int avgRating = 1000)
    {
        using var conn = db.CreateConnection();
        return await conn.QueryAsync(
            "SELECT * FROM pvp_get_random_questions_by_theme(@themeId, @language, @limit, @avgRating)",
            new { themeId, language, limit, avgRating });
    }

    // no themeId â†’ fetch from a random theme
    public async Task<IEnumerable<dynamic>> GetRandomQuestionsByThemeAsync(
        string language, int limit = 5)
    {
        using var conn = db.CreateConnection();
        return await conn.QueryAsync(
            "SELECT * FROM pvp_get_random_questions(@language, @limit)",
            new { language, limit });
    }

    public async Task<string?> GetRandomThemeAsync(string language = "en", string[]? excludeIds = null)
    {
        using var conn = db.CreateConnection();
        return await conn.ExecuteScalarAsync<string?>(
            "SELECT pvp_get_random_theme(@language, @excludeIds)",
            new { language, excludeIds = excludeIds ?? Array.Empty<string>() });
    }

    public async Task<IEnumerable<dynamic>> GetQuestionsByIdsAsync(
        Guid[] questionIds, string language)
    {
        using var conn = db.CreateConnection();
        return await conn.QueryAsync(
            "SELECT * FROM pvp_get_questions_by_ids(@questionIds, @language)",
            new { questionIds, language });
    }

    // â”€â”€â”€ Invitations â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

    public async Task<Guid> SendInvitationAsync(Guid senderId, Guid recipientId)
    {
        using var conn = db.CreateConnection();
        return await conn.ExecuteScalarAsync<Guid>(
            "SELECT pvp_send_invitation(@senderId, @recipientId)",
            new { senderId, recipientId });
    }

    public async Task<dynamic> RespondInvitationAsync(Guid invitationId, Guid userId, bool accept)
    {
        using var conn = db.CreateConnection();
        var result = await conn.QuerySingleAsync(
            "SELECT * FROM pvp_respond_invitation(@invitationId, @userId, @accept)",
            new { invitationId, userId, accept });
        if (accept)
        {
            var dict = (IDictionary<string, object>)result;
            if (dict.TryGetValue("match_id", out var matchIdObj) && matchIdObj is Guid matchId)
                await conn.ExecuteAsync(
                    "UPDATE pvp_matches SET started_at = NOW() WHERE id = @matchId",
                    new { matchId });
        }
        return result;
    }

    public async Task<IEnumerable<dynamic>> GetPendingInvitationsAsync(Guid userId)
    {
        using var conn = db.CreateConnection();
        return await conn.QueryAsync(
            "SELECT * FROM pvp_get_pending_invitations(@userId)",
            new { userId });
    }

    // â”€â”€â”€ Leaderboard â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

    public async Task<IEnumerable<dynamic>> GetFollowingLeaderboardAsync(Guid userId)
    {
        using var conn = db.CreateConnection();
        return await conn.QueryAsync(
            "SELECT * FROM get_pvp_following_leaderboard(@userId)",
            new { userId });
    }

    // â”€â”€â”€ Polling (replaces Supabase Realtime streams) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

    // Caller must be player1 or player2; returns null â†’ 403 in controller
    public async Task<dynamic?> GetMatchAsync(Guid matchId, Guid userId)
    {
        using var conn = db.CreateConnection();
        return await conn.QuerySingleOrDefaultAsync(
            "SELECT * FROM pvp_matches WHERE id = @matchId AND (player1_id = @userId OR player2_id = @userId)",
            new { matchId, userId });
    }

    public async Task<IEnumerable<dynamic>> GetRoundsAsync(Guid matchId, Guid userId)
    {
        using var conn = db.CreateConnection();
        return await conn.QueryAsync(
            """
            SELECT r.* FROM pvp_rounds r
            JOIN pvp_matches m ON m.id = r.match_id
            WHERE r.match_id = @matchId
              AND (m.player1_id = @userId OR m.player2_id = @userId)
            ORDER BY r.round_number
            """,
            new { matchId, userId });
    }

    public async Task<IEnumerable<dynamic>> GetMyMatchesAsync(Guid userId, int limit = 20)
    {
        using var conn = db.CreateConnection();
        return await conn.QueryAsync(
            "SELECT * FROM pvp_matches WHERE player1_id = @userId OR player2_id = @userId ORDER BY created_at DESC LIMIT @limit",
            new { userId, limit });
    }
}

