namespace MakeYourBrain.Api.Models.Entities;

public class PvpMatchmakingQueue
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public int Rating { get; set; }
    public string PreferredLanguage { get; set; } = string.Empty;
    public DateTimeOffset? CreatedAt { get; set; }
    public DateTimeOffset? LastSeen { get; set; }
}
