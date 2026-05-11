namespace MakeYourBrain.Api.Models.Entities;

public class PvpInvitation
{
    public Guid Id { get; set; }
    public Guid SenderId { get; set; }
    public Guid RecipientId { get; set; }
    public string Status { get; set; } = "pending";
    public Guid? MatchId { get; set; }
    public DateTimeOffset? CreatedAt { get; set; }
    public DateTimeOffset? ExpiresAt { get; set; }
}
