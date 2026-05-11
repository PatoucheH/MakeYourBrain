namespace MakeYourBrain.Api.Models.Entities;

public class UserStat
{
    public Guid UserId { get; set; }
    public int? TotalQuestions { get; set; }
    public int? CorrectAnswers { get; set; }
    public int? CurrentStreak { get; set; }
    public int? BestStreak { get; set; }
    public string? PreferredLanguage { get; set; }
    public DateTimeOffset? LastPlayedAt { get; set; }
    public DateTimeOffset? UpdatedAt { get; set; }
    public bool? HasCompletedOnboarding { get; set; }
    public int? PvpRating { get; set; }
    public int? PvpWins { get; set; }
    public int? PvpLosses { get; set; }
    public int? PvpDraws { get; set; }
    public string? Username { get; set; }
    public DateOnly? LastDailyCompletedAt { get; set; }
    public int? TimezoneOffsetHours { get; set; }
    public DateTimeOffset? LastAnswerAt { get; set; }
    public int? DailyStreak { get; set; }
}
