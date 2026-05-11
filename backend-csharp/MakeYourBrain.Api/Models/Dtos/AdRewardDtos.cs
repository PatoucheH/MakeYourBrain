namespace MakeYourBrain.Api.Models.Dtos;

public record AdRewardCallbackParams(
    string? UserId,
    string? TransactionId,
    string? Signature,
    string? KeyId
);
