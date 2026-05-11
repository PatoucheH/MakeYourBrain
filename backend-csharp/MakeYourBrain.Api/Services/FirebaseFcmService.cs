using System.Security.Cryptography;
using System.Text;
using System.Text.Json;

namespace MakeYourBrain.Api.Services;

public class FirebaseFcmService(IConfiguration configuration, IHttpClientFactory httpFactory, ILogger<FirebaseFcmService> logger)
{
    private readonly string _serviceAccountJson = LoadServiceAccount(configuration);

    private static string LoadServiceAccount(IConfiguration configuration)
    {
        var path = configuration["Firebase:ServiceAccountPath"];
        if (!string.IsNullOrEmpty(path))
            return File.ReadAllText(path);

        return configuration["Firebase:ServiceAccountJson"]
            ?? throw new InvalidOperationException("Firebase:ServiceAccountPath or Firebase:ServiceAccountJson must be configured");
    }

    public async Task<List<object>> SendToTokensAsync(
        IEnumerable<string> tokens,
        string title,
        string body,
        Dictionary<string, string>? data = null)
    {
        var serviceAccount = JsonSerializer.Deserialize<Dictionary<string, string>>(_serviceAccountJson)
            ?? throw new InvalidOperationException("Invalid Firebase service account JSON");

        var projectId = serviceAccount["project_id"];
        var accessToken = await GetAccessTokenAsync(serviceAccount);
        var fcmUrl = $"https://fcm.googleapis.com/v1/projects/{projectId}/messages:send";

        var client = httpFactory.CreateClient();
        var results = new List<object>();

        foreach (var token in tokens)
        {
            var payload = new
            {
                message = new
                {
                    token,
                    notification = new { title, body },
                    data,
                }
            };

            var content = new StringContent(
                JsonSerializer.Serialize(payload),
                Encoding.UTF8, "application/json");

            var request = new HttpRequestMessage(HttpMethod.Post, fcmUrl);
            request.Headers.Authorization =
                new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", accessToken);
            request.Content = content;

            var response = await client.SendAsync(request);
            var resultBody = await response.Content.ReadAsStringAsync();

            if (!response.IsSuccessStatusCode)
            {
                using var doc = JsonDocument.Parse(resultBody);
                var status = doc.RootElement
                    .TryGetProperty("error", out var errEl) &&
                    errEl.TryGetProperty("status", out var statusEl)
                    ? statusEl.GetString()
                    : null;

                if (status is "UNREGISTERED" or "INVALID_ARGUMENT" or "NOT_FOUND")
                {
                    logger.LogWarning("FCM: removing stale token {Token}", token[..Math.Min(20, token.Length)] + "...");
                    // Token cleanup is handled by the caller or a background job
                }
            }

            results.Add(new
            {
                token = token[..Math.Min(20, token.Length)] + "...",
                status = (int)response.StatusCode,
                result = resultBody,
            });
        }

        return results;
    }

    public async Task<IReadOnlyList<string>> SendAndGetStaleTokensAsync(
        IEnumerable<string> tokens,
        string title,
        string body,
        Dictionary<string, string>? data = null)
    {
        var staleTokens = new List<string>();
        var tokenList = tokens.ToList();
        if (tokenList.Count == 0) return staleTokens;

        var serviceAccount = JsonSerializer.Deserialize<Dictionary<string, string>>(_serviceAccountJson)!;
        var projectId   = serviceAccount["project_id"];
        var accessToken = await GetAccessTokenAsync(serviceAccount);
        var fcmUrl      = $"https://fcm.googleapis.com/v1/projects/{projectId}/messages:send";
        var client      = httpFactory.CreateClient();

        foreach (var token in tokenList)
        {
            var payload = new
            {
                message = new
                {
                    token,
                    notification = new { title, body },
                    data,
                }
            };

            var request = new HttpRequestMessage(HttpMethod.Post, fcmUrl);
            request.Headers.Authorization =
                new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", accessToken);
            request.Content = new StringContent(
                JsonSerializer.Serialize(payload), Encoding.UTF8, "application/json");

            var response = await client.SendAsync(request);
            if (!response.IsSuccessStatusCode)
            {
                var resultBody = await response.Content.ReadAsStringAsync();
                using var doc  = JsonDocument.Parse(resultBody);
                var status = doc.RootElement
                    .TryGetProperty("error", out var errEl) &&
                    errEl.TryGetProperty("status", out var statusEl)
                    ? statusEl.GetString() : null;

                if (status is "UNREGISTERED" or "INVALID_ARGUMENT" or "NOT_FOUND")
                    staleTokens.Add(token);
            }
        }

        return staleTokens;
    }

    private async Task<string> GetAccessTokenAsync(Dictionary<string, string> serviceAccount)
    {
        var privateKeyPem = serviceAccount["private_key"]
            .Replace("-----BEGIN PRIVATE KEY-----", "")
            .Replace("-----END PRIVATE KEY-----", "")
            .Replace("\n", "");

        var keyBytes = Convert.FromBase64String(privateKeyPem);

        using var rsa = RSA.Create();
        rsa.ImportPkcs8PrivateKey(keyBytes, out _);

        var now = DateTimeOffset.UtcNow.ToUnixTimeSeconds();
        var header = Base64UrlEncode(JsonSerializer.SerializeToUtf8Bytes(new { alg = "RS256", typ = "JWT" }));
        var claims = Base64UrlEncode(JsonSerializer.SerializeToUtf8Bytes(new
        {
            iss = serviceAccount["client_email"],
            scope = "https://www.googleapis.com/auth/firebase.messaging",
            aud = "https://oauth2.googleapis.com/token",
            iat = now,
            exp = now + 3600,
        }));

        var signingInput = $"{header}.{claims}";
        var signature = rsa.SignData(
            Encoding.UTF8.GetBytes(signingInput),
            HashAlgorithmName.SHA256,
            RSASignaturePadding.Pkcs1);

        var jwt = $"{signingInput}.{Base64UrlEncode(signature)}";

        var client = httpFactory.CreateClient();
        var tokenResponse = await client.PostAsync(
            "https://oauth2.googleapis.com/token",
            new FormUrlEncodedContent(new[]
            {
                new KeyValuePair<string, string>("grant_type", "urn:ietf:params:oauth:grant-type:jwt-bearer"),
                new KeyValuePair<string, string>("assertion", jwt),
            }));

        if (!tokenResponse.IsSuccessStatusCode)
            throw new Exception($"Failed to get FCM access token: {await tokenResponse.Content.ReadAsStringAsync()}");

        using var doc = JsonDocument.Parse(await tokenResponse.Content.ReadAsStringAsync());
        return doc.RootElement.GetProperty("access_token").GetString()
            ?? throw new Exception("No access_token in Google response");
    }

    private static string Base64UrlEncode(byte[] bytes)
        => Convert.ToBase64String(bytes).TrimEnd('=').Replace('+', '-').Replace('/', '_');
}
