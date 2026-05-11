using System.Text.Json.Serialization;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using MakeYourBrain.Api.Models.Entities;
using MakeYourBrain.Api.Services;
using Swashbuckle.AspNetCore.Annotations;

namespace MakeYourBrain.Api.Controllers;

[ApiController]
[Route("auth")]
[AllowAnonymous]
public class AuthController(
    UserManager<ApplicationUser> userManager,
    TokenService                 tokenService,
    UserProvisioningService      provisioning,
    SocialAuthService            socialAuth,
    IWebHostEnvironment          env) : ControllerBase
{
    // ─── Request / Response DTOs ──────────────────────────────────────────
    public record RegisterRequest(
        string Email,
        string Password,
        string Username,
        string PreferredLanguage = "en");

    public record LoginRequest(string Email, string Password);

    public record RefreshRequest(
        [property: JsonPropertyName("refresh_token")] string RefreshToken);

    public record GoogleRequest(
        [property: JsonPropertyName("id_token")]    string IdToken);

    public record AppleRequest(
        [property: JsonPropertyName("id_token")]    string IdToken,
        [property: JsonPropertyName("nonce")]       string? Nonce = null);

    public record FacebookRequest(
        [property: JsonPropertyName("access_token")] string AccessToken);

    public record AuthResponse(
        [property: JsonPropertyName("access_token")]  string AccessToken,
        [property: JsonPropertyName("token_type")]    string TokenType,
        [property: JsonPropertyName("expires_in")]    int    ExpiresIn,
        [property: JsonPropertyName("refresh_token")] string RefreshToken);

    // ─── Register ─────────────────────────────────────────────────────────
    [HttpPost("register")]
    public async Task<IActionResult> Register([FromBody] RegisterRequest request)
    {
        var user = new ApplicationUser
        {
            Id                = Guid.NewGuid(),
            UserName          = request.Username,
            Email             = request.Email,
            PreferredLanguage = request.PreferredLanguage,
            EmailConfirmed    = true,
        };

        var result = await userManager.CreateAsync(user, request.Password);
        if (!result.Succeeded)
            return BadRequest(new { errors = result.Errors.Select(e => e.Description) });

        await provisioning.ProvisionAsync(user.Id, user.Email!, user.UserName!, user.PreferredLanguage);

        return Ok(await BuildResponseAsync(user));
    }

    // ─── Login ────────────────────────────────────────────────────────────
    [HttpPost("login")]
    public async Task<IActionResult> Login([FromBody] LoginRequest request)
    {
        var user = await userManager.FindByEmailAsync(request.Email);
        if (user is null || !await userManager.CheckPasswordAsync(user, request.Password))
            return Unauthorized(new { error = "Invalid login credentials" });

        return Ok(await BuildResponseAsync(user));
    }

    // ─── Refresh ──────────────────────────────────────────────────────────
    [HttpPost("refresh")]
    public async Task<IActionResult> Refresh([FromBody] RefreshRequest request)
    {
        var rt = await tokenService.ValidateRefreshTokenAsync(request.RefreshToken);
        if (rt is null)
            return Unauthorized(new { error = "Invalid or expired refresh token" });

        await tokenService.RevokeAsync(rt.Token);
        return Ok(await BuildResponseAsync(rt.User));
    }

    // ─── Social — Google ──────────────────────────────────────────────────
    [HttpPost("google")]
    public async Task<IActionResult> Google([FromBody] GoogleRequest request)
    {
        var info = await socialAuth.VerifyGoogleAsync(request.IdToken);
        if (info is null) return Unauthorized(new { error = "Invalid Google token" });
        return await HandleSocialAsync("google", info);
    }

    // ─── Social — Apple ───────────────────────────────────────────────────
    [HttpPost("apple")]
    public async Task<IActionResult> Apple([FromBody] AppleRequest request)
    {
        var info = await socialAuth.VerifyAppleAsync(request.IdToken);
        if (info is null) return Unauthorized(new { error = "Invalid Apple token" });
        return await HandleSocialAsync("apple", info);
    }

    // ─── Social — Facebook ────────────────────────────────────────────────
    [HttpPost("facebook")]
    [SwaggerOperation(Summary = "Login via Facebook", Description = "Not available yet")]
    public async Task<IActionResult> Facebook([FromBody] FacebookRequest request)
    {
        var info = await socialAuth.VerifyFacebookAsync(request.AccessToken);
        if (info is null) return Unauthorized(new { error = "Invalid Facebook token" });
        return await HandleSocialAsync("facebook", info);
    }

    // ─── Dev-only: simulate social login without hitting real OAuth provider ─
    // Only available in Development environment — returns 404 in production.
    [HttpPost("dev/social")]
    public async Task<IActionResult> DevSocial([FromBody] DevSocialRequest request)
    {
        if (!env.IsDevelopment())
            return NotFound();

        var info = new SocialUserInfo(request.ProviderId, request.Email, request.Name);
        return await HandleSocialAsync(request.Provider, info);
    }

    public record DevSocialRequest(
        string  Provider,
        string  ProviderId,
        string? Email,
        string? Name);

    // ─── Helpers ──────────────────────────────────────────────────────────
    private async Task<IActionResult> HandleSocialAsync(string provider, SocialUserInfo info)
    {
        // 1. Existing external login
        var user = await userManager.FindByLoginAsync(provider, info.ProviderId);

        // 2. Fallback: same email already registered
        if (user is null && info.Email is not null)
            user = await userManager.FindByEmailAsync(info.Email);

        // 3. Create new account
        if (user is null)
        {
            var username = info.Name?.Replace(" ", "")
                           ?? $"user_{Guid.NewGuid():N}"[..12];

            if (await userManager.FindByNameAsync(username) is not null)
                username = $"{username}_{Guid.NewGuid():N}"[..4];

            var email = info.Email ?? $"{info.ProviderId.Replace(".", "_")}@privaterelay.appleid.com";
            user = new ApplicationUser
            {
                Id             = Guid.NewGuid(),
                UserName       = username,
                Email          = email,
                EmailConfirmed = info.Email is not null,
            };

            var result = await userManager.CreateAsync(user);
            if (!result.Succeeded)
                return BadRequest(new { errors = result.Errors.Select(e => e.Description) });

            await provisioning.ProvisionAsync(
                user.Id,
                user.Email ?? $"{user.Id}@social",
                user.UserName!,
                user.PreferredLanguage);
        }

        // Link provider if not already linked
        var logins = await userManager.GetLoginsAsync(user);
        if (!logins.Any(l => l.LoginProvider == provider && l.ProviderKey == info.ProviderId))
            await userManager.AddLoginAsync(user, new UserLoginInfo(provider, info.ProviderId, provider));

        return Ok(await BuildResponseAsync(user));
    }

    private async Task<AuthResponse> BuildResponseAsync(ApplicationUser user)
    {
        var (token, expiresIn) = tokenService.GenerateAccessToken(user);
        var refresh            = await tokenService.CreateRefreshTokenAsync(user.Id);
        return new AuthResponse(token, "Bearer", expiresIn, refresh);
    }
}
