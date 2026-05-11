namespace MakeYourBrain.Api.Models.Entities;

public class PvpRound
{
    public Guid Id { get; set; }
    public Guid MatchId { get; set; }
    public int RoundNumber { get; set; }
    public string[] QuestionIds { get; set; } = [];
    public int? Player1Score { get; set; }
    public int? Player2Score { get; set; }
    public string Player1Answers { get; set; } = "[]";
    public DateTimeOffset? Player1CompletedAt { get; set; }
    public string Player2Answers { get; set; } = "[]";
    public DateTimeOffset? Player2CompletedAt { get; set; }
    public DateTimeOffset? CreatedAt { get; set; }
    public string? ThemeId { get; set; }

    public PvpMatch? Match { get; set; }
}
