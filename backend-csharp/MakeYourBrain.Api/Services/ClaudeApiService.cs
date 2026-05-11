using System.Text;
using System.Text.Json;
using System.Text.Json.Serialization;
using System.Text.RegularExpressions;
using Dapper;
using MakeYourBrain.Api.Infrastructure;
using MakeYourBrain.Api.Models.Dtos;

namespace MakeYourBrain.Api.Services;

/// <summary>
/// Replicates the generate-questions Edge Function logic using the Anthropic API.
/// </summary>
public class ClaudeApiService(
    DapperConnectionFactory db,
    IConfiguration configuration,
    IHttpClientFactory httpFactory,
    ILogger<ClaudeApiService> logger)
{
    private const int QuestionsPerConcept = 15;
    private const int MaxConceptsToAvoid = 100;
    private const int EasyCount = 6;
    private const int HardCount = 3;
    private const int MediumCount = QuestionsPerConcept - EasyCount - HardCount;

    private readonly string _apiKey = configuration["Anthropic:ApiKey"]
        ?? throw new InvalidOperationException("Anthropic:ApiKey is not configured");

    private readonly string _model = configuration["Anthropic:Model"] ?? "claude-sonnet-4-20250514";

    // ── Private DTOs for Claude API response parsing ──────────────────────────
    private record ClaudeAnswer(
        [property: JsonPropertyName("text")] string Text,
        [property: JsonPropertyName("is_correct")] bool IsCorrect);

    private record ClaudeQuestion(
        [property: JsonPropertyName("question_en")] string QuestionEn,
        [property: JsonPropertyName("question_fr")] string QuestionFr,
        [property: JsonPropertyName("explanation_en")] string? ExplanationEn,
        [property: JsonPropertyName("explanation_fr")] string? ExplanationFr,
        [property: JsonPropertyName("difficulty")] string? Difficulty,
        [property: JsonPropertyName("answers_en")] List<ClaudeAnswer> AnswersEn,
        [property: JsonPropertyName("answers_fr")] List<ClaudeAnswer> AnswersFr);

    private record ClaudeQuestionsRoot(
        [property: JsonPropertyName("questions")] List<ClaudeQuestion> Questions);

    public async Task<GenerateQuestionsResponse> GenerateQuestionsAsync(
        Guid? themeId, string? forcedConcept, string? forcedConceptFr)
    {
        using var conn = db.CreateConnection();

        // ── Select theme ──────────────────────────────────────────────────
        string themeQuery = themeId.HasValue
            ? "SELECT id, icon FROM themes WHERE id = @themeId ORDER BY id"
            : "SELECT id, icon FROM themes ORDER BY id";

        var themes = (await conn.QueryAsync(themeQuery, new { themeId })).ToList();
        if (themes.Count == 0) throw new Exception("No themes found");

        dynamic theme;
        if (themeId.HasValue)
        {
            theme = themes[0];
        }
        else
        {
            // Fair rotation: pick theme with fewest questions
            var themeCounts = new List<(Guid Id, string Icon, int Count)>();
            foreach (var t in themes)
            {
                var count = await conn.ExecuteScalarAsync<int>(
                    "SELECT COUNT(*) FROM questions WHERE theme_id = @id",
                    new { id = (Guid)t.id });
                themeCounts.Add(((Guid)t.id, (string)t.icon, count));
            }
            var least = themeCounts.OrderBy(x => x.Count).First();
            theme = themes.First(t => (Guid)t.id == least.Id);
        }

        var themeName = await conn.ExecuteScalarAsync<string>(
            "SELECT name FROM theme_translations WHERE theme_id = @themeId AND language_code = 'en'",
            new { themeId = (Guid)theme.id }) ?? "General";

        // ── Used concepts ─────────────────────────────────────────────────
        var usedConcepts = (await conn.QueryAsync<string>(
            "SELECT concept FROM question_concepts WHERE theme_id = @themeId ORDER BY created_at DESC",
            new { themeId = (Guid)theme.id })).ToList();

        // ── Choose concept ────────────────────────────────────────────────
        string conceptName;
        string conceptFr;

        if (forcedConcept is not null)
        {
            var exists = usedConcepts.Any(c =>
                c.Contains(forcedConcept, StringComparison.OrdinalIgnoreCase) ||
                forcedConcept.Contains(c, StringComparison.OrdinalIgnoreCase));

            if (exists)
                return new GenerateQuestionsResponse(false, "manual", themeName, null, forcedConcept, 0, null, usedConcepts.Count,
                    Message: "Concept already exists for this theme");

            conceptName = forcedConcept;
            conceptFr = forcedConceptFr ?? forcedConcept;
        }
        else
        {
            var chosen = await AskClaudeForConceptAsync(themeName, usedConcepts);
            conceptName = chosen.Concept;
            conceptFr = chosen.ConceptFr;

            var exists = usedConcepts.Any(c =>
                c.Contains(conceptName, StringComparison.OrdinalIgnoreCase) ||
                conceptName.Contains(c, StringComparison.OrdinalIgnoreCase));

            if (exists)
                return new GenerateQuestionsResponse(false, "automatic", themeName, null, null, 0, null, usedConcepts.Count,
                    Message: "Concept already exists, will retry tomorrow",
                    AttemptedConcept: conceptName);
        }

        // ── Generate questions ────────────────────────────────────────────
        var generated = await AskClaudeForQuestionsAsync(conceptName, themeName);

        // ── Insert concept ────────────────────────────────────────────────
        var conceptId = await conn.ExecuteScalarAsync<Guid>(
            """
            INSERT INTO question_concepts (concept, concept_en, concept_fr, theme_id)
            VALUES (@concept, @conceptEn, @conceptFr, @themeId)
            RETURNING id
            """,
            new { concept = conceptName, conceptEn = conceptName, conceptFr, themeId = (Guid)theme.id });

        // ── Insert questions ──────────────────────────────────────────────
        int added = 0;
        var diffCount = new int[3]; // 0=easy, 1=medium, 2=hard

        foreach (var q in generated)
        {
            try
            {
                if (!ValidateQuestion(q)) continue;

                var dup = await conn.ExecuteScalarAsync<bool>(
                    "SELECT EXISTS(SELECT 1 FROM question_translations WHERE question_text = @text AND language_code = 'en')",
                    new { text = q.QuestionEn });
                if (dup) continue;

                var difficulty = q.Difficulty is "easy" or "medium" or "hard"
                    ? q.Difficulty : "medium";

                var questionId = await conn.ExecuteScalarAsync<Guid>(
                    "INSERT INTO questions (theme_id, concept_id, difficulty) VALUES (@themeId, @conceptId, @difficulty) RETURNING id",
                    new { themeId = (Guid)theme.id, conceptId, difficulty });

                await conn.ExecuteAsync(
                    """
                    INSERT INTO question_translations (question_id, language_code, question_text, explanation)
                    VALUES (@qid, 'en', @textEn, @explEn), (@qid, 'fr', @textFr, @explFr)
                    """,
                    new { qid = questionId, textEn = q.QuestionEn, explEn = q.ExplanationEn ?? "",
                          textFr = q.QuestionFr, explFr = q.ExplanationFr ?? "" });

                var answersData = q.AnswersEn.Select((a, i) =>
                    new { question_id = questionId, is_correct = a.IsCorrect, display_order = i });

                var insertedAnswers = (await conn.QueryAsync<dynamic>(
                    "INSERT INTO answers (question_id, is_correct, display_order) VALUES (@question_id, @is_correct, @display_order) RETURNING id",
                    answersData)).ToList();

                if (insertedAnswers.Count != 4) continue;

                var answerTranslations = insertedAnswers.SelectMany((ans, i) => new[]
                {
                    new { answer_id = (Guid)ans.id, language_code = "en", answer_text = q.AnswersEn[i].Text },
                    new { answer_id = (Guid)ans.id, language_code = "fr", answer_text = q.AnswersFr[i].Text },
                });

                await conn.ExecuteAsync(
                    "INSERT INTO answer_translations (answer_id, language_code, answer_text) VALUES (@answer_id, @language_code, @answer_text)",
                    answerTranslations);

                added++;
                diffCount[difficulty == "easy" ? 0 : difficulty == "medium" ? 1 : 2]++;
            }
            catch (Exception ex)
            {
                logger.LogWarning(ex, "Skipping question due to error");
            }
        }

        if (added == 0)
        {
            await conn.ExecuteAsync("DELETE FROM question_concepts WHERE id = @conceptId", new { conceptId });
            throw new Exception("No valid questions generated, concept deleted");
        }

        var mode = forcedConcept is null ? "automatic" : "manual";
        return new GenerateQuestionsResponse(
            true, mode, themeName, (string)theme.icon, conceptName, added,
            new DifficultyDistribution(diffCount[0], diffCount[1], diffCount[2]),
            usedConcepts.Count + 1);
    }

    private async Task<(string Concept, string ConceptFr)> AskClaudeForConceptAsync(
        string themeName, IList<string> usedConcepts)
    {
        var avoidList = usedConcepts.Count > 0
            ? "\n🚫 CRITICAL - These concepts have ALREADY been covered:\n" +
              string.Join("\n", usedConcepts.Take(MaxConceptsToAvoid).Select((c, i) => $"{i + 1}. {c}")) +
              "\n\nYou MUST choose a COMPLETELY DIFFERENT concept not in this list.\n"
            : "";

        var prompt = $$"""
            You are helping create quiz questions for a "{{themeName}}" themed quiz app for a GENERAL AUDIENCE.
            {{avoidList}}
            Task: Suggest ONE specific, interesting concept related to "{{themeName}}".

            Requirements:
            - Must be BROAD and WELL-KNOWN (not too specific)
            - Should be a general topic that allows multiple angles
            - Must be recognizable by most people
            - Must be related to {{themeName}}
            - Should allow for diverse question angles at different difficulty levels
            - Must be COMPLETELY DIFFERENT from all concepts listed above

            Examples of GOOD concepts (BROAD):
              - "The Legend of Zelda" (not "The Legend of Zelda: Ocarina of Time")
              - "World War II" (not "The Battle of Stalingrad")
              - "The Solar System" (not "Jupiter's Great Red Spot")
              - "Vincent van Gogh" (not "Vincent van Gogh's Starry Night")

            Examples of BAD concepts (too narrow/specific):
              - "The Legend of Zelda: Ocarina of Time Water Temple"
              - "The Third Punic War's naval tactics"
              - "Cytochrome P450 enzyme family"

            Examples of BAD concepts (too basic):
              - "Colors", "Numbers", "Animals"

            Respond ONLY with valid JSON (no markdown):

            {
              "concept": "Specific concept name in English",
              "concept_fr": "Nom du concept en français"
            }
            """;

        var response = await CallClaudeAsync(prompt, 500);
        using var doc = JsonDocument.Parse(response);
        return (
            doc.RootElement.GetProperty("concept").GetString()!,
            doc.RootElement.GetProperty("concept_fr").GetString()!
        );
    }

    private async Task<IList<ClaudeQuestion>> AskClaudeForQuestionsAsync(string conceptName, string themeName)
    {
        var prompt = $$"""
            Generate {{QuestionsPerConcept}} diverse and high-quality quiz questions about "{{conceptName}}" (theme: {{themeName}}).

            CRITICAL REQUIREMENTS:
            - ALL questions MUST be specifically about "{{conceptName}}"
            - Questions must be DIVERSE (different aspects, angles, perspectives)
            - Difficulty distribution: {{EasyCount}} EASY, {{MediumCount}} MEDIUM, {{HardCount}} HARD
            - Factually accurate and verifiable
            - 4 answers per question (exactly 1 correct)
            - Interesting and educational
            - Questions should range from basic facts to deeper analysis
            - The four answers must be the same time max 10 characters between the good answer size and the average bad answer size

            Difficulty guidelines:
            - EASY: Requires genuine knowledge of the concept, not just common sense. The answer should not be guessable by someone unfamiliar with "{{conceptName}}". Ask about well-known but specific facts. ({{EasyCount}} questions)
              ✅ Good example: "What is the main weapon used by Link in The Legend of Zelda?" (specific but known by fans)
              ❌ Bad example: "What color is the sky?" or "Who is the main character of Zelda?" (too trivial)
            - MEDIUM: Standard knowledge, requires familiarity with the topic. About 40-50% of people interested in the theme should know this. ({{MediumCount}} questions)
              Example: "What year did World War II end?" or "What is the process by which plants make food?"
            - HARD: Specific details, deeper knowledge, less commonly known facts. Only enthusiasts or experts should know this. ({{HardCount}} questions)
              Example: "Which treaty ended World War I?" or "What is the smallest bone in the human body?"

            BALANCE:
            - EASY should require real knowledge of "{{conceptName}}", not just common sense. Someone who knows nothing about this topic should NOT be able to guess easily.
            - MEDIUM should be known by about 40-50% of people with some interest in the topic.
            - HARD should be known by about 15-25% (enthusiasts and experts only).
            - NEVER generate trivially obvious questions like "What is X famous for?" or "Who is the creator of Y?"

            🚫 ABSOLUTE PROHIBITIONS:
            - NEVER generate a question where the answer is contained in or directly deducible from the question itself
            - NEVER generate a question where the answer is contained in or directly deducible from the concept name "{{conceptName}}"
            - NEVER ask "What does X mean?" or "What is the literal meaning of X?" if X is the concept name or closely related to it
            - NEVER ask questions whose answer requires zero prior knowledge of "{{conceptName}}" (e.g. language/translation questions)
            - NEVER ask questions where the correct answer appears word-for-word in the question text
            - Before finalizing each question, verify: "Could someone with NO knowledge of {{conceptName}} guess this answer from the question alone?" — if YES, rewrite it

            RESPOND ONLY WITH VALID JSON (no markdown, no explanation):

            {
              "questions": [
                {
                  "question_en": "Question in English",
                  "question_fr": "Question en français",
                  "explanation_en": "Detailed explanation why this is correct (2-3 sentences)",
                  "explanation_fr": "Explication détaillée en français (2-3 phrases)",
                  "difficulty": "easy",
                  "answers_en": [
                    {"text": "Wrong answer 1", "is_correct": false},
                    {"text": "Correct answer", "is_correct": true},
                    {"text": "Wrong answer 2", "is_correct": false},
                    {"text": "Wrong answer 3", "is_correct": false}
                  ],
                  "answers_fr": [
                    {"text": "Mauvaise réponse 1", "is_correct": false},
                    {"text": "Bonne réponse", "is_correct": true},
                    {"text": "Mauvaise réponse 2", "is_correct": false},
                    {"text": "Mauvaise réponse 3", "is_correct": false}
                  ]
                }
              ]
            }
            """;

        var response = await CallClaudeAsync(prompt, 16000);
        var root = JsonSerializer.Deserialize<ClaudeQuestionsRoot>(response);
        if (root?.Questions is null || root.Questions.Count == 0)
            throw new Exception("Invalid questions format");
        return root.Questions;
    }

    private async Task<string> CallClaudeAsync(string prompt, int maxTokens)
    {
        var client = httpFactory.CreateClient();
        var requestBody = JsonSerializer.Serialize(new
        {
            model = _model,
            max_tokens = maxTokens,
            messages = new[] { new { role = "user", content = prompt } }
        });

        var request = new HttpRequestMessage(HttpMethod.Post, "https://api.anthropic.com/v1/messages");
        request.Headers.Add("x-api-key", _apiKey);
        request.Headers.Add("anthropic-version", "2023-06-01");
        request.Content = new StringContent(requestBody, Encoding.UTF8, "application/json");

        var response = await client.SendAsync(request);
        if (!response.IsSuccessStatusCode)
            throw new Exception($"Claude API error: {response.StatusCode}");

        var body = await response.Content.ReadAsStringAsync();
        using var doc = JsonDocument.Parse(body);
        var text = doc.RootElement
            .GetProperty("content")[0]
            .GetProperty("text")
            .GetString()!
            .Trim();

        if (text.StartsWith("```"))
            text = Regex.Replace(text, @"```json?\n?", "").Replace("```", "").Trim();

        return text;
    }

    private static bool ValidateQuestion(ClaudeQuestion q)
    {
        if (string.IsNullOrWhiteSpace(q.QuestionEn) || string.IsNullOrWhiteSpace(q.QuestionFr)) return false;
        if (q.AnswersEn is null || q.AnswersFr is null) return false;
        if (q.AnswersEn.Count != 4 || q.AnswersFr.Count != 4) return false;
        if (q.AnswersEn.Count(a => a.IsCorrect) != 1) return false;
        if (q.AnswersFr.Count(a => a.IsCorrect) != 1) return false;
        if (q.AnswersEn.Any(a => string.IsNullOrWhiteSpace(a.Text))) return false;
        if (q.AnswersFr.Any(a => string.IsNullOrWhiteSpace(a.Text))) return false;
        return true;
    }
}
