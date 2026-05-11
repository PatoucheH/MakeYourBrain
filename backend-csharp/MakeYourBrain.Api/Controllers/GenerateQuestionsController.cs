using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MakeYourBrain.Api.Infrastructure.Extensions;
using MakeYourBrain.Api.Models.Dtos;
using MakeYourBrain.Api.Services;

namespace MakeYourBrain.Api.Controllers;

[ApiController]
[Route("functions/v1/generate-questions")]
public class GenerateQuestionsController(
    ClaudeApiService claudeService,
    ILogger<GenerateQuestionsController> logger) : ControllerBase
{
    private static readonly System.Text.RegularExpressions.Regex UuidRegex =
        new(@"^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$",
            System.Text.RegularExpressions.RegexOptions.IgnoreCase);

    private static readonly System.Text.RegularExpressions.Regex HtmlRegex =
        new(@"<[^>]*>");

    [HttpPost]
    [Authorize]
    public async Task<IActionResult> GenerateQuestions([FromBody] GenerateQuestionsRequest request)
    {
        // Only service_role can call this endpoint (cron / admin)
        if (!User.IsServiceRole())
            return StatusCode(403, new { error = "Forbidden" });

        if (request.ThemeId.HasValue && !UuidRegex.IsMatch(request.ThemeId.Value.ToString()))
            return BadRequest(new { error = "Invalid theme_id format" });

        if (request.Concept is not null)
        {
            var concept = request.Concept.Trim();
            if (concept.Length == 0 || concept.Length > 200 || HtmlRegex.IsMatch(concept))
                return BadRequest(new { error = "Invalid concept value" });
        }

        if (request.ConceptFr is not null)
        {
            var conceptFr = request.ConceptFr.Trim();
            if (conceptFr.Length > 200 || HtmlRegex.IsMatch(conceptFr))
                return BadRequest(new { error = "Invalid concept_fr value" });
        }

        try
        {
            var result = await claudeService.GenerateQuestionsAsync(
                request.ThemeId,
                request.Concept?.Trim(),
                request.ConceptFr?.Trim());

            return Ok(result);
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "Fatal error in generate-questions");
            return StatusCode(500, new { success = false, error = "Internal server error" });
        }
    }
}
