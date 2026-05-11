namespace MakeYourBrain.Api.Models.Entities;

public class ThemeTranslation
{
    public Guid Id { get; set; }
    public Guid ThemeId { get; set; }
    public string LanguageCode { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }
    public DateTimeOffset? CreatedAt { get; set; }

    public Theme? Theme { get; set; }
}
