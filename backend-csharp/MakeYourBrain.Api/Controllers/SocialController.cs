using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MakeYourBrain.Api.Infrastructure.Extensions;
using MakeYourBrain.Api.Services;

namespace MakeYourBrain.Api.Controllers;

[ApiController]
[Route("social")]
[Authorize]
public class SocialController(SocialService social) : ControllerBase
{
    public record FollowRequest(Guid UserId);

    [HttpPost("follow")]
    public async Task<IActionResult> Follow([FromBody] FollowRequest req)
    {
        var followerId = User.GetUserId();
        if (followerId == req.UserId) return BadRequest(new { error = "Cannot follow yourself" });
        await social.FollowUserAsync(followerId, req.UserId);
        return Ok();
    }

    [HttpDelete("follow/{userId:guid}")]
    public async Task<IActionResult> Unfollow(Guid userId)
    {
        var followerId = User.GetUserId();
        await social.UnfollowUserAsync(followerId, userId);
        return Ok();
    }

    [HttpGet("followers")]
    public async Task<IActionResult> GetFollowers()
    {
        var userId = User.GetUserId();
        var followers = await social.GetFollowersAsync(userId);
        return Ok(followers);
    }

    [HttpGet("following")]
    public async Task<IActionResult> GetFollowing()
    {
        var userId = User.GetUserId();
        var following = await social.GetFollowingAsync(userId);
        return Ok(following);
    }

    [HttpGet("counts")]
    public async Task<IActionResult> GetFollowCounts()
    {
        var userId = User.GetUserId();
        var counts = await social.GetFollowCountsAsync(userId);
        return counts is null ? NotFound() : Ok(counts);
    }

    [HttpGet("search")]
    public async Task<IActionResult> SearchUsers([FromQuery] string q)
    {
        if (string.IsNullOrWhiteSpace(q) || q.Length < 2)
            return BadRequest(new { error = "Query must be at least 2 characters" });
        var requesterId = User.GetUserId();
        var results = await social.SearchUsersAsync(requesterId, q);
        return Ok(results);
    }

    // Public — display name lookup
    [HttpGet("display-name/{userId:guid}")]
    [AllowAnonymous]
    public async Task<IActionResult> GetDisplayName(Guid userId)
    {
        Guid? requesterId = User.Identity?.IsAuthenticated == true ? User.GetUserId() : null;
        var name = await social.GetDisplayNameAsync(userId, requesterId);
        return name is null ? NotFound() : Ok(new { display_name = name });
    }
}
