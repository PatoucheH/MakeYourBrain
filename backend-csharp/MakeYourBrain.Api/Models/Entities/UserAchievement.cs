namespace MakeYourBrain.Api.Models.Entities;

public class UserAchievement
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public Guid AchievementId { get; set; }
    public DateTimeOffset? UnlockedAt { get; set; }

    public Achievement? Achievement { get; set; }
}
