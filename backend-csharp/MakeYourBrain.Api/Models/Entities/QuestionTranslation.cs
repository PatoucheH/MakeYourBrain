namespace MakeYourBrain.Api.Models.Entities;

public class QuestionTranslation
{
    public Guid Id { get; set; }
    public Guid QuestionId { get; set; }
    public string LanguageCode { get; set; } = string.Empty;
    public string QuestionText { get; set; } = string.Empty;
    public string? Explanation { get; set; }
    public DateTimeOffset? CreatedAt { get; set; }

    public Question? Question { get; set; }
}
