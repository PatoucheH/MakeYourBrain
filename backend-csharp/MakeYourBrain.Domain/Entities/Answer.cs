namespace MakeYourBrain.Domain.Entities;

public class Answer
{
    public Guid Id { get; set; }
    public Guid QuestionId { get; set; }
    public bool IsCorrect { get; set; }
    public int? DisplayOrder { get; set; }
    public DateTimeOffset? CreatedAt { get; set; }

    public Question? Question { get; set; }
    public ICollection<AnswerTranslation> Translations { get; set; } = [];
}

