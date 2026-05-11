namespace MakeYourBrain.Domain.Entities;

public class UserProfile
{
    public Guid UserId { get; set; }
    public string? DisplayName { get; set; }
    public DateTimeOffset? CreatedAt { get; set; }
    public DateTimeOffset? UpdatedAt { get; set; }
}

