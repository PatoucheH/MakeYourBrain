namespace MakeYourBrain.Domain.Entities;

public class UserAnswer
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public Guid QuestionId { get; set; }
    public Guid SelectedAnswerId { get; set; }
    public bool IsCorrect { get; set; }
    public string LanguageUsed { get; set; } = string.Empty;
    public DateTimeOffset? AnsweredAt { get; set; }

    public Question? Question { get; set; }
    public Answer? SelectedAnswer { get; set; }
}

