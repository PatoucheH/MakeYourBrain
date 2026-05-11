namespace MakeYourBrain.Api.Models.Entities;

public class QuestionConcept
{
    public Guid Id { get; set; }
    public string Concept { get; set; } = string.Empty;
    public Guid? ThemeId { get; set; }
    public DateTimeOffset? CreatedAt { get; set; }
    public string? ConceptEn { get; set; }
    public string? ConceptFr { get; set; }

    public Theme? Theme { get; set; }
    public ICollection<Question> Questions { get; set; } = [];
}
