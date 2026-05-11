namespace MakeYourBrain.Api.Models.Views;

public class LeaderboardGlobal
{
    public Guid? UserId { get; set; }
    public string? DisplayName { get; set; }
    public long? TotalXp { get; set; }
    public long? TotalLevels { get; set; }
    public int? TotalQuestions { get; set; }
    public int? CorrectAnswers { get; set; }
    public decimal? Accuracy { get; set; }
    public int? CurrentStreak { get; set; }
}
