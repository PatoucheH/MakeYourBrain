namespace MakeYourBrain.Domain.Dtos;

public record AdRewardCallbackParams(
    string? UserId,
    string? TransactionId,
    string? Signature,
    string? KeyId
);

