namespace MakeYourBrain.Api.Models.Entities;

public class Question
{
    public Guid Id { get; set; }
    public Guid ThemeId { get; set; }
    public string? Difficulty { get; set; }
    public int? TimesUsed { get; set; }
    public DateTimeOffset? CreatedAt { get; set; }
    public bool? IsVerified { get; set; }
    public DateTimeOffset? VerifiedAt { get; set; }
    public Guid? ConceptId { get; set; }

    public Theme? Theme { get; set; }
    public QuestionConcept? Concept { get; set; }
    public ICollection<QuestionTranslation> Translations { get; set; } = [];
    public ICollection<Answer> Answers { get; set; } = [];
}
