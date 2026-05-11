namespace MakeYourBrain.Api.Models.Entities;

public class UserLife
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public int CurrentLives { get; set; } = 10;
    public int MaxLives { get; set; } = 10;
    public DateTimeOffset? LastRegenAt { get; set; }
    public DateTimeOffset? CreatedAt { get; set; }
    public DateTimeOffset? UpdatedAt { get; set; }
    public DateTimeOffset? LastAdLivesAt { get; set; }
}
