namespace MakeYourBrain.Api.Models.Entities;

public class AdRewardTransaction
{
    public string TransactionId { get; set; } = string.Empty;
    public Guid UserId { get; set; }
    public DateTimeOffset? CreatedAt { get; set; }
}
