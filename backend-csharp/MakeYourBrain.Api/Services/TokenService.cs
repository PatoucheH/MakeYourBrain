using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.JsonWebTokens;
using Microsoft.IdentityModel.Tokens;
using MakeYourBrain.Api.Infrastructure;
using MakeYourBrain.Api.Models.Entities;

namespace MakeYourBrain.Api.Services;

public class TokenService(IConfiguration config, AppDbContext db)
{
    private int AccessExpiryMinutes => int.Parse(config["Jwt:AccessTokenExpiryMinutes"] ?? "60");
    private int RefreshExpiryDays   => int.Parse(config["Jwt:RefreshTokenExpiryDays"]   ?? "30");

    public (string Token, int ExpiresInSeconds) GenerateAccessToken(ApplicationUser user, string role = "authenticated")
    {
        var secret = config["Jwt:Secret"] ?? throw new InvalidOperationException("Jwt:Secret not configured");
        var key    = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(secret));

        var descriptor = new SecurityTokenDescriptor
        {
            Subject = new ClaimsIdentity([
                new Claim("sub",   user.Id.ToString()),
                new Claim("email", user.Email ?? ""),
                new Claim("role",  role),
                new Claim("jti",   Guid.NewGuid().ToString()),
            ]),
            Issuer             = config["Jwt:Issuer"] ?? "makeyourbrain",
            Expires            = DateTime.UtcNow.AddMinutes(AccessExpiryMinutes),
            SigningCredentials = new SigningCredentials(key, SecurityAlgorithms.HmacSha256),
        };

        var token = new JsonWebTokenHandler().CreateToken(descriptor);
        return (token, AccessExpiryMinutes * 60);
    }

    public async Task<string> CreateRefreshTokenAsync(Guid userId)
    {
        var token = Convert.ToBase64String(RandomNumberGenerator.GetBytes(64));

        db.RefreshTokens.Add(new RefreshToken
        {
            UserId    = userId,
            Token     = token,
            ExpiresAt = DateTime.UtcNow.AddDays(RefreshExpiryDays),
            CreatedAt = DateTime.UtcNow,
        });
        await db.SaveChangesAsync();
        return token;
    }

    public Task<RefreshToken?> ValidateRefreshTokenAsync(string token)
        => db.RefreshTokens
             .Include(r => r.User)
             .FirstOrDefaultAsync(r => r.Token == token && !r.IsRevoked && r.ExpiresAt > DateTime.UtcNow);

    public async Task RevokeAsync(string token)
    {
        var rt = await db.RefreshTokens.FirstOrDefaultAsync(r => r.Token == token);
        if (rt is null) return;
        rt.IsRevoked = true;
        await db.SaveChangesAsync();
    }
}
