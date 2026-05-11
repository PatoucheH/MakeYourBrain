namespace MakeYourBrain.Domain.Entities;

public class AnswerTranslation
{
    public Guid Id { get; set; }
    public Guid AnswerId { get; set; }
    public string LanguageCode { get; set; } = string.Empty;
    public string AnswerText { get; set; } = string.Empty;
    public DateTimeOffset? CreatedAt { get; set; }

    public Answer? Answer { get; set; }
}

