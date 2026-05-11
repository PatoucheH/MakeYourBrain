using System.Security.Cryptography;
using System.Text;
using System.Text.Json;

namespace MakeYourBrain.Api.Services;

/// <summary>
/// Verifies AdMob SSV ECDSA P-256/SHA-256 signatures.
/// Mirrors the logic from the Deno verify-ad-reward Edge Function.
/// </summary>
public class AdMobVerificationService(IConfiguration configuration, IHttpClientFactory httpFactory)
{
    private readonly string _verifierKeysUrl =
        configuration["AdMob:VerifierKeysUrl"]
        ?? "https://gstatic.com/admob/reward/verifier-keys.json";

    public async Task<bool> VerifySignatureAsync(string rawQuery, string signature, string keyId)
    {
        try
        {
            var client = httpFactory.CreateClient();
            var keysJson = await client.GetStringAsync(_verifierKeysUrl);
            using var keysDoc = JsonDocument.Parse(keysJson);

            ECDsa? publicKey = null;
            foreach (var key in keysDoc.RootElement.GetProperty("keys").EnumerateArray())
            {
                if (key.GetProperty("keyId").GetInt64().ToString() == keyId)
                {
                    var pem = key.GetProperty("pem").GetString()!;
                    publicKey = ImportEcPublicKey(pem);
                    break;
                }
            }

            if (publicKey is null) return false;

            var message = BuildVerificationMessage(rawQuery);
            var signatureBytes = DecodeSignature(signature);
            var messageBytes = Encoding.UTF8.GetBytes(message);

            return publicKey.VerifyData(messageBytes, signatureBytes, HashAlgorithmName.SHA256);
        }
        catch
        {
            return false;
        }
    }

    private static string BuildVerificationMessage(string rawQuery)
    {
        var query = rawQuery.StartsWith('?') ? rawQuery[1..] : rawQuery;
        var sigIdx = query.LastIndexOf("&signature=", StringComparison.Ordinal);
        return sigIdx >= 0 ? query[..sigIdx] : query;
    }

    private static ECDsa ImportEcPublicKey(string pem)
    {
        var pemContents = pem
            .Replace("-----BEGIN PUBLIC KEY-----", "")
            .Replace("-----END PUBLIC KEY-----", "")
            .Replace("\n", "");

        var keyBytes = Convert.FromBase64String(pemContents);
        var ecdsa = ECDsa.Create();
        ecdsa.ImportSubjectPublicKeyInfo(keyBytes, out _);
        return ecdsa;
    }

    private static byte[] DecodeSignature(string base64url)
    {
        var base64 = base64url.Replace('-', '+').Replace('_', '/');
        var padded = base64 + new string('=', (4 - base64.Length % 4) % 4);
        var bytes = Convert.FromBase64String(padded);

        // DER format (starts with 0x30) — convert to P1363 (raw r||s, 64 bytes)
        if (bytes[0] == 0x30)
            return DerToP1363(bytes);

        return bytes;
    }

    private static byte[] DerToP1363(byte[] der)
    {
        var offset = 2; // skip 0x30 + length

        offset++; // skip 0x02 (integer tag)
        var rLen = der[offset++];
        var r = der[offset..(offset + rLen)];
        offset += rLen;

        offset++; // skip 0x02
        var sLen = der[offset++];
        var s = der[offset..(offset + sLen)];

        var p1363 = new byte[64];
        var rBytes = r.Length > 32 ? r[^32..] : r;
        var sBytes = s.Length > 32 ? s[^32..] : s;
        rBytes.CopyTo(p1363, 32 - rBytes.Length);
        sBytes.CopyTo(p1363, 64 - sBytes.Length);
        return p1363;
    }
}
