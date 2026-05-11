namespace MakeYourBrain.Api.Models.Entities;

public class UserThemeProgress
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public Guid ThemeId { get; set; }
    public int? Xp { get; set; }
    public int? Level { get; set; }
    public int? TotalQuestions { get; set; }
    public int? CorrectAnswers { get; set; }
    public DateTimeOffset? CreatedAt { get; set; }
    public DateTimeOffset? UpdatedAt { get; set; }

    public Theme? Theme { get; set; }
}
