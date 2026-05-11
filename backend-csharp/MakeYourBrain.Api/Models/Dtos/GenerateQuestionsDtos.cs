using System.Text.Json.Serialization;

namespace MakeYourBrain.Api.Models.Dtos;

public record GenerateQuestionsRequest(
    Guid? ThemeId = null,
    string? Concept = null,
    string? ConceptFr = null
);

public record GenerateQuestionsResponse(
    bool Success,
    string? Mode,
    string? Theme,
    string? ThemeIcon,
    string? Concept,
    int QuestionsGenerated,
    DifficultyDistribution? DifficultyDistribution,
    int TotalConceptsForTheme,
    string? Message = null,
    string? Error = null,
    [property: JsonPropertyName("attempted_concept")] string? AttemptedConcept = null
);

public record DifficultyDistribution(int Easy, int Medium, int Hard);
