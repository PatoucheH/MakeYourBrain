using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MakeYourBrain.Infrastructure.Data;
using MakeYourBrain.Api.Extensions;
using MakeYourBrain.Domain.Dtos;
using MakeYourBrain.Application.Services;
using MakeYourBrain.Infrastructure.Services;
using Dapper;

namespace MakeYourBrain.Api.Controllers;

[ApiController]
[Route("functions/v1/send-notification")]
[Authorize]
public class SendNotificationController(
    DapperConnectionFactory db,
    FirebaseFcmService fcmService,
    ILogger<SendNotificationController> logger) : ControllerBase
{
    private static readonly HashSet<string> AllowedTypes =
        ["match_found", "your_turn", "match_over", "pvp_invitation", "pvp_invitation_accepted"];

    private static readonly HashSet<string> InvitationTypes =
        ["pvp_invitation", "pvp_invitation_accepted"];

    private static readonly Dictionary<string, (string TitleEn, string BodyEn, string TitleFr, string BodyFr)> NotificationContent = new()
    {
        ["match_found"]             = ("Match found!", "An opponent is waiting! Open the app to play.", "Match trouvÃ© !", "Un adversaire t'attend ! Ouvre l'app pour jouer."),
        ["your_turn"]               = ("Your turn!", "Your opponent has played. It's your turn!", "C'est ton tour !", "Ton adversaire a jouÃ©. Ã€ toi de jouer !"),
        ["match_over"]              = ("Match over!", "Your match result is available!", "Match terminÃ© !", "Le rÃ©sultat de ta partie est disponible !"),
        ["pvp_invitation"]          = ("PvP Challenge!", "{name} challenges you to a match!", "DÃ©fi PvP !", "{name} vous dÃ©fie en match !"),
        ["pvp_invitation_accepted"] = ("Challenge Accepted!", "{name} accepted your PvP challenge!", "DÃ©fi AcceptÃ© !", "{name} a acceptÃ© votre dÃ©fi PvP !"),
    };

    [HttpPost]
    public async Task<IActionResult> SendNotification([FromBody] SendNotificationRequest request)
    {
        var callerId = User.GetUserId();

        if (!AllowedTypes.Contains(request.NotificationType))
            return BadRequest(new { success = false, error = "Invalid notification type" });

        if (callerId == request.UserId)
            return StatusCode(403, new { success = false, error = "Forbidden" });

        using var conn = db.CreateConnection();

        // For non-invitation types, verify an active match exists between the two players
        if (!InvitationTypes.Contains(request.NotificationType))
        {
            var matchExists = await conn.ExecuteScalarAsync<bool>(
                """
                SELECT EXISTS(
                    SELECT 1 FROM pvp_matches
                    WHERE (player1_id = @callerId AND player2_id = @userId
                        OR player1_id = @userId  AND player2_id = @callerId)
                    AND status NOT IN ('completed','cancelled')
                )
                """,
                new { callerId, userId = request.UserId });

            if (!matchExists)
                return StatusCode(403, new { success = false, error = "Forbidden" });
        }

        // Fetch recipient language + caller username
        var recipientLang = await conn.ExecuteScalarAsync<string?>(
            "SELECT preferred_language FROM user_stats WHERE user_id = @userId",
            new { userId = request.UserId });

        string? senderName = null;
        if (InvitationTypes.Contains(request.NotificationType))
        {
            senderName = await conn.ExecuteScalarAsync<string?>(
                "SELECT username FROM user_stats WHERE user_id = @callerId",
                new { callerId });
        }

        var lang = recipientLang == "fr" ? "fr" : "en";
        var (titleEn, bodyEn, titleFr, bodyFr) = NotificationContent[request.NotificationType];
        var title = lang == "fr" ? titleFr : titleEn;
        var body  = (lang == "fr" ? bodyFr : bodyEn).Replace("{name}", senderName ?? "Someone");

        // Fetch FCM tokens
        var tokens = (await conn.QueryAsync<string>(
            "SELECT token FROM user_fcm_tokens WHERE user_id = @userId",
            new { userId = request.UserId })).ToList();

        if (tokens.Count == 0)
            return NotFound(new { success = false, error = "No FCM tokens found for this user" });

        try
        {
            var (staleTokens, results) = await fcmService.SendWithResultsAsync(tokens, title, body);

            if (staleTokens.Count > 0)
            {
                await conn.ExecuteAsync(
                    "DELETE FROM user_fcm_tokens WHERE token = ANY(@staleTokens)",
                    new { staleTokens = staleTokens.ToArray() });
                logger.LogInformation("Removed {Count} stale FCM token(s) for user {UserId}",
                    staleTokens.Count, request.UserId);
            }

            return Ok(new { success = true, sent = tokens.Count, stale_removed = staleTokens.Count, results });
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "FCM send error");
            return StatusCode(500, new { success = false, error = "Internal server error" });
        }
    }
}


