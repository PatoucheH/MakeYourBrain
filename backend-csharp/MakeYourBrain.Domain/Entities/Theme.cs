namespace MakeYourBrain.Domain.Entities;

public class Theme
{
    public Guid Id { get; set; }
    public string Icon { get; set; } = string.Empty;
    public string Color { get; set; } = string.Empty;
    public DateTimeOffset? CreatedAt { get; set; }

    public ICollection<ThemeTranslation> Translations { get; set; } = [];
    public ICollection<Question> Questions { get; set; } = [];
    public ICollection<QuestionConcept> Concepts { get; set; } = [];
}

