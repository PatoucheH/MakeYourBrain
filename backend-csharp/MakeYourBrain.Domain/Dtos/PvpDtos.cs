namespace MakeYourBrain.Domain.Dtos;

public record PvpJoinQueueRequest(string PreferredLanguage);

public record PvpJoinQueueResponse(
    bool Success,
    string Status,
    Guid? MatchId,
    string? Message
);

public record PvpSubmitRoundRequest(
    Guid MatchId,
    int RoundNumber,
    string AnswersJson
);

public record PvpSendInvitationRequest(Guid RecipientId);

public record PvpRespondInvitationRequest(Guid InvitationId, bool Accept);

public record PvpRespondInvitationResponse(
    bool Success,
    Guid? MatchId,
    string? Status
);

public record PvpCreateRoundRequest(Guid MatchId, int RoundNumber, string[] QuestionIds, string? ThemeId = null);

public record PvpUpdateMatchStatusRequest(string Status, int? CurrentRound = null);

public record PvpLeaderboardEntry(
    Guid UserId,
    string? Username,
    string? DisplayName,
    int Rating,
    int Wins,
    int Losses,
    int Draws
);

