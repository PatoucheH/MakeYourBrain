namespace MakeYourBrain.Domain.Views;

public class LeaderboardByTheme
{
    public Guid? ThemeId { get; set; }
    public Guid? UserId { get; set; }
    public string? DisplayName { get; set; }
    public int? Xp { get; set; }
    public int? Level { get; set; }
    public int? TotalQuestions { get; set; }
    public int? CorrectAnswers { get; set; }
    public decimal? Accuracy { get; set; }
}

