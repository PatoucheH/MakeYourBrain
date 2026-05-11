using Dapper;
using MakeYourBrain.Api.Infrastructure;

namespace MakeYourBrain.Api.Services;

public class QuizService(DapperConnectionFactory db)
{
    public async Task<IEnumerable<dynamic>> GetRandomQuestionsAsync(
        Guid themeId, string language, int limit = 10)
    {
        using var conn = db.CreateConnection();
        return await conn.QueryAsync(
            "SELECT * FROM get_random_questions(@themeId::uuid, @language::text, @limit::int, 100, 0, 0)",
            new { themeId, language, limit });
    }

    public async Task<dynamic?> GetDailyConceptAsync(Guid userId, string language)
    {
        using var conn = db.CreateConnection();
        return await conn.QuerySingleOrDefaultAsync(
            "SELECT * FROM get_daily_concept(@userId, @language)",
            new { userId, language });
    }

    public async Task<IEnumerable<dynamic>> GetDailyQuestionsAsync(string language)
    {
        using var conn = db.CreateConnection();
        return await conn.QueryAsync(
            "SELECT * FROM get_daily_questions(@language)",
            new { language });
    }

    public async Task CompleteDailyConceptAsync(Guid userId)
    {
        using var conn = db.CreateConnection();
        await conn.ExecuteAsync(
            "SELECT complete_daily_concept(@userId)",
            new { userId });
    }

    public async Task<int> AddQuizCompletionXpAsync(
        Guid userId, Guid themeId, Guid[] questionIds, Guid[] answerIds, bool isDaily)
    {
        using var conn = db.CreateConnection();
        var correct = await conn.ExecuteScalarAsync<int>(
            """
            SELECT COUNT(*) FROM answers a
            JOIN UNNEST(@questionIds::uuid[], @answerIds::uuid[]) AS p(qid, aid)
              ON a.id = p.aid AND a.question_id = p.qid
            WHERE a.is_correct = true
            """,
            new { questionIds, answerIds });
        int total = answerIds.Length;
        int xpGained = correct * 10;
        await conn.ExecuteAsync(
            """
            INSERT INTO user_theme_progress (user_id, theme_id, xp, total_questions, correct_answers)
            VALUES (@userId, @themeId, @xpGained, @total, @correct)
            ON CONFLICT (user_id, theme_id) DO UPDATE
              SET xp              = user_theme_progress.xp + @xpGained,
                  total_questions = user_theme_progress.total_questions + @total,
                  correct_answers = user_theme_progress.correct_answers + @correct,
                  updated_at      = NOW()
            """,
            new { userId, themeId, xpGained, total, correct });
        await conn.ExecuteAsync(
            """
            UPDATE user_theme_progress
            SET level = calculate_level_from_xp(xp)
            WHERE user_id = @userId AND theme_id = @themeId
            """,
            new { userId, themeId });
        return xpGained;
    }

    public async Task IncrementUserStatsAsync(
        Guid userId, int totalDelta, int correctDelta, bool updateStreak = true)
    {
        using var conn = db.CreateConnection();
        await conn.ExecuteAsync(
            """
            INSERT INTO user_stats (user_id, total_questions, correct_answers, last_answer_at)
            VALUES (@userId, @totalDelta, @correctDelta, NOW())
            ON CONFLICT (user_id) DO UPDATE
              SET total_questions = user_stats.total_questions + @totalDelta,
                  correct_answers = user_stats.correct_answers + @correctDelta,
                  last_answer_at  = NOW()
            """,
            new { userId, totalDelta, correctDelta });
        if (updateStreak)
            await UpdateUserStreakAsync(userId);
    }

    public async Task UpdateUserStreakAsync(Guid userId)
    {
        using var conn = db.CreateConnection();
        var offsetHours = await conn.ExecuteScalarAsync<int?>(
            "SELECT timezone_offset_hours FROM user_stats WHERE user_id = @userId",
            new { userId });
        var offset = offsetHours ?? 0;
        // POSIX sign is inverted: Etc/GMT-2 = UTC+2, Etc/GMT+5 = UTC-5
        var tz = offset == 0 ? "UTC"
            : offset > 0 ? $"Etc/GMT-{offset}"
            : $"Etc/GMT+{Math.Abs(offset)}";
        await conn.ExecuteAsync(
            "SELECT update_user_streak(@userId::uuid, @tz::text)",
            new { userId, tz });
    }

    public async Task<IEnumerable<dynamic>> GetUserProgressByThemeAsync(Guid userId, string language)
    {
        using var conn = db.CreateConnection();
        return await conn.QueryAsync(
            "SELECT * FROM get_user_progress_by_theme(@userId, @language)",
            new { userId, language });
    }

    public async Task UpdateUserLanguageAsync(Guid userId, string language)
    {
        using var conn = db.CreateConnection();
        using var tran = conn.BeginTransaction();
        await conn.ExecuteAsync(
            "SELECT set_config('request.jwt.claim.sub', @sub, true)",
            new { sub = userId.ToString() }, tran);
        await conn.ExecuteAsync("SELECT update_user_language(@language)", new { language }, tran);
        tran.Commit();
    }

    public async Task SaveUserAnswerAsync(
        Guid userId, Guid questionId, Guid answerId, bool isCorrect, string language = "en")
    {
        using var conn = db.CreateConnection();
        await conn.ExecuteAsync(
            """
            INSERT INTO user_answers (user_id, question_id, selected_answer_id, is_correct, language_used)
            VALUES (@userId, @questionId, @answerId, @isCorrect, @language)
            """,
            new { userId, questionId, answerId, isCorrect, language });
    }

    public async Task SaveSurvivalScoreAsync(Guid userId, Guid themeId, int score)
    {
        using var conn = db.CreateConnection();
        await conn.ExecuteAsync(
            "INSERT INTO survival_scores (user_id, theme_id, score) VALUES (@userId, @themeId, @score)",
            new { userId, themeId, score });
    }

    public async Task<IEnumerable<dynamic>> GetMySurvivalScoresAsync(Guid userId)
    {
        using var conn = db.CreateConnection();
        return await conn.QueryAsync(
            "SELECT * FROM survival_scores WHERE user_id = @userId ORDER BY score DESC LIMIT 20",
            new { userId });
    }
}
