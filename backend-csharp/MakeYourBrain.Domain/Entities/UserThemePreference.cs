namespace MakeYourBrain.Domain.Entities;

public class UserThemePreference
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public Guid ThemeId { get; set; }
    public DateTimeOffset? CreatedAt { get; set; }

    public Theme? Theme { get; set; }
}

