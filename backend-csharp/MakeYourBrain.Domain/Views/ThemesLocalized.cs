namespace MakeYourBrain.Domain.Views;

public class ThemesLocalized
{
    public Guid? Id { get; set; }
    public string? Icon { get; set; }
    public string? Color { get; set; }
    public string? Name { get; set; }
    public string? Description { get; set; }
    public string? LanguageCode { get; set; }
    public DateTimeOffset? CreatedAt { get; set; }
}

