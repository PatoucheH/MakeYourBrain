namespace MakeYourBrain.Domain.Entities;

public class PvpMatch
{
    public Guid Id { get; set; }
    public Guid Player1Id { get; set; }
    public Guid Player2Id { get; set; }
    public string Status { get; set; } = string.Empty;
    public int CurrentRound { get; set; } = 1;
    public int? Player1TotalScore { get; set; }
    public int? Player2TotalScore { get; set; }
    public Guid? WinnerId { get; set; }
    public int Player1RatingBefore { get; set; }
    public int Player2RatingBefore { get; set; }
    public int? Player1RatingChange { get; set; }
    public int? Player2RatingChange { get; set; }
    public DateTimeOffset? CreatedAt { get; set; }
    public DateTimeOffset? StartedAt { get; set; }
    public DateTimeOffset? CompletedAt { get; set; }
    public DateTimeOffset? UpdatedAt { get; set; }

    public ICollection<PvpRound> Rounds { get; set; } = [];
}

