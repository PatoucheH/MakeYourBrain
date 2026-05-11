namespace MakeYourBrain.Api.Models.Dtos;

public record SendNotificationRequest(
    Guid UserId,
    string NotificationType
);

public record SendNotificationResponse(
    bool Success,
    int Sent,
    string? Error = null
);

public record StreakReminderResponse(
    bool Success,
    int Sent,
    string? Message = null
);
