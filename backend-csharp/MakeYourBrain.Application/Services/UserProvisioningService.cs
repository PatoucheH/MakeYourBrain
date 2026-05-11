using Dapper;
using MakeYourBrain.Application.Interfaces;

namespace MakeYourBrain.Application.Services;

public class UserProvisioningService(IDbConnectionFactory connectionFactory)
{
    public async Task ProvisionAsync(Guid userId, string email, string displayName, string preferredLanguage = "en")
    {
        using var conn = connectionFactory.CreateConnection();

        // auth.users stub keeps FK constraints (user_stats / user_lives / user_profiles â†’ auth.users) satisfied
        await conn.ExecuteAsync(
            "INSERT INTO auth.users (id, email) VALUES (@id, @email) ON CONFLICT (id) DO NOTHING",
            new { id = userId, email });

        await conn.ExecuteAsync("""
            INSERT INTO user_stats (user_id, preferred_language, username)
            SELECT @userId, @lang, @displayName
            WHERE NOT EXISTS (SELECT 1 FROM user_stats WHERE user_id = @userId);

            INSERT INTO user_lives (user_id, current_lives, max_lives)
            SELECT @userId, 10, 10
            WHERE NOT EXISTS (SELECT 1 FROM user_lives WHERE user_id = @userId);

            INSERT INTO user_profiles (user_id, display_name)
            VALUES (@userId, @displayName)
            ON CONFLICT (user_id) DO UPDATE SET display_name = EXCLUDED.display_name;
            """,
            new { userId, lang = preferredLanguage, displayName });
    }
}

