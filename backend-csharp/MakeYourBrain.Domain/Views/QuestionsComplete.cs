namespace MakeYourBrain.Domain.Views;

public class QuestionsComplete
{
    public Guid? Id { get; set; }
    public Guid? ThemeId { get; set; }
    public string? Difficulty { get; set; }
    public int? TimesUsed { get; set; }
    public string? QuestionText { get; set; }
    public string? Explanation { get; set; }
    public string? LanguageCode { get; set; }
    public DateTimeOffset? CreatedAt { get; set; }
    public string? AnswersJson { get; set; }
}

