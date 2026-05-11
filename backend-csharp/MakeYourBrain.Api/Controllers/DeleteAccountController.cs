using Dapper;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using MakeYourBrain.Application.Interfaces;
using MakeYourBrain.Api.Extensions;
using MakeYourBrain.Domain.Entities;

namespace MakeYourBrain.Api.Controllers;

[ApiController]
[Route("functions/v1/delete-account")]
[Authorize]
public class DeleteAccountController(
    UserManager<ApplicationUser> userManager,
    IDbConnectionFactory db,
    ILogger<DeleteAccountController> logger) : ControllerBase
{
    [HttpPost]
    public async Task<IActionResult> DeleteAccount()
    {
        var userId = User.GetUserId();
        try
        {
            using var conn = db.CreateConnection();

            // Forfeit active PvP matches so the opponent receives the win
            await conn.ExecuteAsync(
                """
                UPDATE pvp_matches
                SET status = 'completed',
                    winner_id = CASE WHEN player1_id = @userId THEN player2_id ELSE player1_id END,
                    completed_at = NOW()
                WHERE (player1_id = @userId OR player2_id = @userId)
                  AND status NOT IN ('completed', 'cancelled')
                """,
                new { userId });

            // Remove from matchmaking queue
            await conn.ExecuteAsync(
                "DELETE FROM pvp_matchmaking_queue WHERE user_id = @userId",
                new { userId });

            // Deleting from auth.users cascades to user_stats, user_lives,
            // user_profiles, user_fcm_tokens, and all other FK-linked app tables.
            await conn.ExecuteAsync(
                "DELETE FROM auth.users WHERE id = @userId",
                new { userId });

            // Delete ASP.NET Identity user (asp_net_users + related tables)
            var user = await userManager.FindByIdAsync(userId.ToString());
            if (user is not null)
            {
                var result = await userManager.DeleteAsync(user);
                if (!result.Succeeded)
                {
                    logger.LogError("delete-account: Identity deletion failed for {UserId}: {Errors}",
                        userId, string.Join(", ", result.Errors.Select(e => e.Description)));
                    return StatusCode(500, new { error = "Failed to delete account" });
                }
            }

            // Clean up refresh tokens (not FK-linked to asp_net_users)
            await conn.ExecuteAsync(
                "DELETE FROM refresh_tokens WHERE user_id = @userId",
                new { userId });

            logger.LogInformation("delete-account: account fully deleted for user {UserId}", userId);
            return Ok(new { success = true });
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "delete-account: unexpected error for user {UserId}", userId);
            return StatusCode(500, new { error = "Internal Server Error" });
        }
    }
}

