namespace MakeYourBrain.Api.Models.Entities;

public class Achievement
{
    public Guid Id { get; set; }
    public string Key { get; set; } = string.Empty;
    public string NameEn { get; set; } = string.Empty;
    public string NameFr { get; set; } = string.Empty;
    public string DescriptionEn { get; set; } = string.Empty;
    public string DescriptionFr { get; set; } = string.Empty;
    public string Icon { get; set; } = string.Empty;
    public string Category { get; set; } = "general";
    public string ConditionType { get; set; } = string.Empty;
    public int ConditionValue { get; set; }
    public int XpReward { get; set; }
    public DateTimeOffset? CreatedAt { get; set; }
}
