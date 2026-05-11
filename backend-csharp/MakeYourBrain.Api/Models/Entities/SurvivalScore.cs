namespace MakeYourBrain.Api.Models.Entities;

public class SurvivalScore
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public Guid ThemeId { get; set; }
    public int Score { get; set; }
    public DateTimeOffset PlayedAt { get; set; }
}
