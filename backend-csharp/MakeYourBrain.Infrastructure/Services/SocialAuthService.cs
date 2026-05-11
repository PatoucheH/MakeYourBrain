using System.Text.Json;
using Microsoft.IdentityModel.JsonWebTokens;
using Microsoft.IdentityModel.Tokens;

namespace MakeYourBrain.Infrastructure.Services;

public record SocialUserInfo(string ProviderId, string? Email, string? Name);

public class SocialAuthService(IHttpClientFactory httpClientFactory, IConfiguration config)
{
    public async Task<SocialUserInfo?> VerifyGoogleAsync(string idToken)
    {
        var client = httpClientFactory.CreateClient();
        var resp   = await client.GetAsync($"https://oauth2.googleapis.com/tokeninfo?id_token={idToken}");
        if (!resp.IsSuccessStatusCode) return null;

        var root = JsonDocument.Parse(await resp.Content.ReadAsStringAsync()).RootElement;
        var sub  = root.TryGetProperty("sub",   out var s) ? s.GetString() : null;
        return sub is null ? null : new SocialUserInfo(
            ProviderId: sub,
            Email: root.TryGetProperty("email", out var e) ? e.GetString() : null,
            Name:  root.TryGetProperty("name",  out var n) ? n.GetString() : null);
    }

    public async Task<SocialUserInfo?> VerifyAppleAsync(string idToken)
    {
        var client   = httpClientFactory.CreateClient();
        var jwksJson = await client.GetStringAsync("https://appleid.apple.com/auth/keys");
        var keys     = new JsonWebKeySet(jwksJson).GetSigningKeys();

        var result = await new JsonWebTokenHandler().ValidateTokenAsync(idToken, new TokenValidationParameters
        {
            ValidateIssuerSigningKey = true,
            IssuerSigningKeys        = keys,
            ValidIssuer              = "https://appleid.apple.com",
            ValidateIssuer           = true,
            ValidateAudience         = true,
            ValidAudiences           = ["com.patou.makeyourbrain"],
            ValidateLifetime         = true,
            ClockSkew                = TimeSpan.FromMinutes(5),
        });

        if (!result.IsValid) return null;

        result.Claims.TryGetValue("sub",   out var sub);
        result.Claims.TryGetValue("email", out var email);
        return sub is null ? null : new SocialUserInfo(
            ProviderId: sub.ToString()!,
            Email: email?.ToString(),
            Name: null);
    }

    public async Task<SocialUserInfo?> VerifyFacebookAsync(string accessToken)
    {
        var appId     = config["Facebook:AppId"]     ?? throw new InvalidOperationException("Facebook:AppId not configured");
        var appSecret = config["Facebook:AppSecret"] ?? throw new InvalidOperationException("Facebook:AppSecret not configured");

        var client = httpClientFactory.CreateClient();

        // Step 1: validate the token is issued for our app
        var debugResp = await client.GetAsync(
            $"https://graph.facebook.com/debug_token?input_token={accessToken}&access_token={appId}|{appSecret}");
        if (!debugResp.IsSuccessStatusCode) return null;

        var debugRoot = JsonDocument.Parse(await debugResp.Content.ReadAsStringAsync()).RootElement;
        if (!debugRoot.TryGetProperty("data", out var data)) return null;

        var isValid    = data.TryGetProperty("is_valid", out var valid) && valid.GetBoolean();
        var tokenAppId = data.TryGetProperty("app_id",   out var aid)   ? aid.GetString() : null;
        var userId     = data.TryGetProperty("user_id",  out var uid)   ? uid.GetString() : null;

        if (!isValid || tokenAppId != appId || userId is null) return null;

        // Step 2: fetch user details
        var meResp = await client.GetAsync(
            $"https://graph.facebook.com/me?fields=id,email,name&access_token={accessToken}");
        if (!meResp.IsSuccessStatusCode) return null;

        var meRoot = JsonDocument.Parse(await meResp.Content.ReadAsStringAsync()).RootElement;
        return new SocialUserInfo(
            ProviderId: userId,
            Email: meRoot.TryGetProperty("email", out var e) ? e.GetString() : null,
            Name:  meRoot.TryGetProperty("name",  out var n) ? n.GetString() : null);
    }
}

