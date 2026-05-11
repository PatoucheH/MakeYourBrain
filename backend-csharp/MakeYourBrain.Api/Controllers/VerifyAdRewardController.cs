using Dapper;
using Microsoft.AspNetCore.Mvc;
using MakeYourBrain.Application.Interfaces;
using MakeYourBrain.Infrastructure.Services;

namespace MakeYourBrain.Api.Controllers;

/// <summary>
/// AdMob SSV callback — no JWT required (called directly by Google).
/// </summary>
[ApiController]
[Route("functions/v1/verify-ad-reward")]
public class VerifyAdRewardController(
    IDbConnectionFactory db,
    AdMobVerificationService adMobService,
    ILogger<VerifyAdRewardController> logger) : ControllerBase
{
    private static readonly System.Text.RegularExpressions.Regex UuidRegex =
        new(@"^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$",
            System.Text.RegularExpressions.RegexOptions.IgnoreCase);

    [HttpGet]
    public async Task<IActionResult> VerifyAdReward(
        [FromQuery] string? user_id,
        [FromQuery] string? transaction_id,
        [FromQuery] string? signature,
        [FromQuery] string? key_id)
    {
        // AdMob sends a validation ping without parameters â€" return 200 to confirm the URL
        if (user_id is null || transaction_id is null || signature is null || key_id is null)
            return Ok("OK");

        if (!UuidRegex.IsMatch(user_id))
        {
            logger.LogError("SSV: invalid user_id (non-UUID): {UserId}", user_id);
            return StatusCode(403, "Forbidden");
        }

        try
        {
            var rawQuery = Request.QueryString.Value ?? string.Empty;
            var isValid = await adMobService.VerifySignatureAsync(rawQuery, signature, key_id);
            if (!isValid)
            {
                logger.LogError("SSV: invalid signature for transaction {TransactionId}", transaction_id);
                return StatusCode(403, "Forbidden");
            }

            using var conn = db.CreateConnection();

            // Anti-replay: try inserting; unique constraint violation = already processed
            try
            {
                await conn.ExecuteAsync(
                    "INSERT INTO ad_reward_transactions (transaction_id, user_id) VALUES (@transactionId, @userId)",
                    new { transactionId = transaction_id, userId = Guid.Parse(user_id) });
            }
            catch (Npgsql.PostgresException ex) when (ex.SqlState == "23505")
            {
                logger.LogInformation("SSV: transaction already processed {TransactionId}", transaction_id);
                return Ok("OK");
            }

            // add_lives_from_ad checks request.jwt.claims.role = 'service_role'.
            // SET LOCAL scopes the claim to this transaction, satisfying the SQL guard.
            using var tran = conn.BeginTransaction();
            await conn.ExecuteAsync(
                "SET LOCAL \"request.jwt.claims\" = '{\"role\":\"service_role\"}'",
                transaction: tran);
            await conn.ExecuteAsync(
                "SELECT add_lives_from_ad(@userId)",
                new { userId = Guid.Parse(user_id) }, tran);
            tran.Commit();

            logger.LogInformation("SSV: +2 lives granted to {UserId} (transaction: {TransactionId})", user_id, transaction_id);
            return Ok("OK");
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "SSV: fatal error");
            return StatusCode(500, "Internal Error");
        }
    }
}


