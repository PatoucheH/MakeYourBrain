namespace MakeYourBrain.Api.Models.Entities;

public class UserFollow
{
    public Guid Id { get; set; }
    public Guid FollowerId { get; set; }
    public Guid FollowingId { get; set; }
    public DateTimeOffset? CreatedAt { get; set; }
}
