using System.Text.Json.Serialization;

namespace MakeYourBrain.Domain.Dtos;

public record GenerateQuestionsRequest(
    Guid? ThemeId = null,
    string? Concept = null,
    string? ConceptFr = null
);

public record GenerateQuestionsResponse(
    [property: JsonPropertyName("success")]                   bool Success,
    [property: JsonPropertyName("mode")]                      string? Mode,
    [property: JsonPropertyName("theme")]                     string? Theme,
    [property: JsonPropertyName("theme_icon")]                string? ThemeIcon,
    [property: JsonPropertyName("concept")]                   string? Concept,
    [property: JsonPropertyName("questions_generated")]       int QuestionsGenerated,
    [property: JsonPropertyName("difficulty_distribution")]   DifficultyDistribution? DifficultyDistribution,
    [property: JsonPropertyName("total_concepts_for_theme")]  int TotalConceptsForTheme,
    [property: JsonPropertyName("message")]                   string? Message = null,
    [property: JsonPropertyName("error")]                     string? Error = null,
    [property: JsonPropertyName("attempted_concept")]         string? AttemptedConcept = null
);

public record DifficultyDistribution(
    [property: JsonPropertyName("easy")]   int Easy,
    [property: JsonPropertyName("medium")] int Medium,
    [property: JsonPropertyName("hard")]   int Hard);

