using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore;
using MakeYourBrain.Domain.Entities;

namespace MakeYourBrain.Infrastructure.Data;

public class AppDbContext(DbContextOptions<AppDbContext> options)
    : IdentityDbContext<ApplicationUser, IdentityRole<Guid>, Guid>(options)
{
    // â”€â”€â”€ Identity â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    public DbSet<RefreshToken> RefreshTokens => Set<RefreshToken>();

    // â”€â”€â”€ Tables â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    public DbSet<Achievement> Achievements => Set<Achievement>();
    public DbSet<AdRewardTransaction> AdRewardTransactions => Set<AdRewardTransaction>();
    public DbSet<Answer> Answers => Set<Answer>();
    public DbSet<AnswerTranslation> AnswerTranslations => Set<AnswerTranslation>();
    public DbSet<PvpInvitation> PvpInvitations => Set<PvpInvitation>();
    public DbSet<PvpMatch> PvpMatches => Set<PvpMatch>();
    public DbSet<PvpMatchmakingQueue> PvpMatchmakingQueues => Set<PvpMatchmakingQueue>();
    public DbSet<PvpRound> PvpRounds => Set<PvpRound>();
    public DbSet<Question> Questions => Set<Question>();
    public DbSet<QuestionConcept> QuestionConcepts => Set<QuestionConcept>();
    public DbSet<QuestionTranslation> QuestionTranslations => Set<QuestionTranslation>();
    public DbSet<SurvivalScore> SurvivalScores => Set<SurvivalScore>();
    public DbSet<Theme> Themes => Set<Theme>();
    public DbSet<ThemeTranslation> ThemeTranslations => Set<ThemeTranslation>();
    public DbSet<UserAchievement> UserAchievements => Set<UserAchievement>();
    public DbSet<UserAnswer> UserAnswers => Set<UserAnswer>();
    public DbSet<UserFcmToken> UserFcmTokens => Set<UserFcmToken>();
    public DbSet<UserFollow> UserFollows => Set<UserFollow>();
    public DbSet<UserLife> UserLives => Set<UserLife>();
    public DbSet<UserProfile> UserProfiles => Set<UserProfile>();
    public DbSet<UserStat> UserStats => Set<UserStat>();
    public DbSet<UserThemePreference> UserThemePreferences => Set<UserThemePreference>();
    public DbSet<UserThemeProgress> UserThemeProgress => Set<UserThemeProgress>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        // â”€â”€â”€ Identity â€” snake_case table + column names â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        modelBuilder.Entity<ApplicationUser>(e =>
        {
            e.ToTable("asp_net_users");
            e.Property(u => u.Id).HasColumnName("id");
            e.Property(u => u.UserName).HasColumnName("user_name");
            e.Property(u => u.NormalizedUserName).HasColumnName("normalized_user_name");
            e.Property(u => u.Email).HasColumnName("email");
            e.Property(u => u.NormalizedEmail).HasColumnName("normalized_email");
            e.Property(u => u.EmailConfirmed).HasColumnName("email_confirmed");
            e.Property(u => u.PasswordHash).HasColumnName("password_hash");
            e.Property(u => u.SecurityStamp).HasColumnName("security_stamp");
            e.Property(u => u.ConcurrencyStamp).HasColumnName("concurrency_stamp");
            e.Property(u => u.PhoneNumber).HasColumnName("phone_number");
            e.Property(u => u.PhoneNumberConfirmed).HasColumnName("phone_number_confirmed");
            e.Property(u => u.TwoFactorEnabled).HasColumnName("two_factor_enabled");
            e.Property(u => u.LockoutEnd).HasColumnName("lockout_end");
            e.Property(u => u.LockoutEnabled).HasColumnName("lockout_enabled");
            e.Property(u => u.AccessFailedCount).HasColumnName("access_failed_count");
            e.Property(u => u.PreferredLanguage).HasColumnName("preferred_language");
            e.Property(u => u.CreatedAt).HasColumnName("created_at");
        });

        modelBuilder.Entity<IdentityRole<Guid>>(e =>
        {
            e.ToTable("asp_net_roles");
            e.Property(r => r.Id).HasColumnName("id");
            e.Property(r => r.Name).HasColumnName("name");
            e.Property(r => r.NormalizedName).HasColumnName("normalized_name");
            e.Property(r => r.ConcurrencyStamp).HasColumnName("concurrency_stamp");
        });

        modelBuilder.Entity<IdentityUserRole<Guid>>(e =>
        {
            e.ToTable("asp_net_user_roles");
            e.Property(ur => ur.UserId).HasColumnName("user_id");
            e.Property(ur => ur.RoleId).HasColumnName("role_id");
        });

        modelBuilder.Entity<IdentityUserClaim<Guid>>(e =>
        {
            e.ToTable("asp_net_user_claims");
            e.Property(uc => uc.Id).HasColumnName("id");
            e.Property(uc => uc.UserId).HasColumnName("user_id");
            e.Property(uc => uc.ClaimType).HasColumnName("claim_type");
            e.Property(uc => uc.ClaimValue).HasColumnName("claim_value");
        });

        modelBuilder.Entity<IdentityUserLogin<Guid>>(e =>
        {
            e.ToTable("asp_net_user_logins");
            e.Property(ul => ul.LoginProvider).HasColumnName("login_provider");
            e.Property(ul => ul.ProviderKey).HasColumnName("provider_key");
            e.Property(ul => ul.ProviderDisplayName).HasColumnName("provider_display_name");
            e.Property(ul => ul.UserId).HasColumnName("user_id");
        });

        modelBuilder.Entity<IdentityUserToken<Guid>>(e =>
        {
            e.ToTable("asp_net_user_tokens");
            e.Property(ut => ut.UserId).HasColumnName("user_id");
            e.Property(ut => ut.LoginProvider).HasColumnName("login_provider");
            e.Property(ut => ut.Name).HasColumnName("name");
            e.Property(ut => ut.Value).HasColumnName("value");
        });

        modelBuilder.Entity<IdentityRoleClaim<Guid>>(e =>
        {
            e.ToTable("asp_net_role_claims");
            e.Property(rc => rc.Id).HasColumnName("id");
            e.Property(rc => rc.RoleId).HasColumnName("role_id");
            e.Property(rc => rc.ClaimType).HasColumnName("claim_type");
            e.Property(rc => rc.ClaimValue).HasColumnName("claim_value");
        });

        modelBuilder.Entity<RefreshToken>(e =>
        {
            e.ToTable("refresh_tokens");
            e.HasKey(x => x.Id);
            e.Property(x => x.Id).HasColumnName("id").HasDefaultValueSql("gen_random_uuid()");
            e.Property(x => x.UserId).HasColumnName("user_id");
            e.Property(x => x.Token).HasColumnName("token");
            e.Property(x => x.ExpiresAt).HasColumnName("expires_at");
            e.Property(x => x.IsRevoked).HasColumnName("is_revoked").HasDefaultValue(false);
            e.Property(x => x.CreatedAt).HasColumnName("created_at").HasDefaultValueSql("NOW()");
            e.HasOne(x => x.User).WithMany().HasForeignKey(x => x.UserId).OnDelete(DeleteBehavior.Cascade);
        });

        // â”€â”€â”€ achievements â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        modelBuilder.Entity<Achievement>(e =>
        {
            e.ToTable("achievements");
            e.HasKey(x => x.Id);
            e.Property(x => x.Id).HasColumnName("id").HasDefaultValueSql("gen_random_uuid()");
            e.Property(x => x.Key).HasColumnName("key").IsRequired();
            e.Property(x => x.NameEn).HasColumnName("name_en").IsRequired();
            e.Property(x => x.NameFr).HasColumnName("name_fr").IsRequired();
            e.Property(x => x.DescriptionEn).HasColumnName("description_en").IsRequired();
            e.Property(x => x.DescriptionFr).HasColumnName("description_fr").IsRequired();
            e.Property(x => x.Icon).HasColumnName("icon").IsRequired();
            e.Property(x => x.Category).HasColumnName("category").HasDefaultValue("general");
            e.Property(x => x.ConditionType).HasColumnName("condition_type").IsRequired();
            e.Property(x => x.ConditionValue).HasColumnName("condition_value").HasDefaultValue(0);
            e.Property(x => x.XpReward).HasColumnName("xp_reward").HasDefaultValue(0);
            e.Property(x => x.CreatedAt).HasColumnName("created_at").HasDefaultValueSql("now()");
        });

        // â”€â”€â”€ ad_reward_transactions â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        modelBuilder.Entity<AdRewardTransaction>(e =>
        {
            e.ToTable("ad_reward_transactions");
            e.HasKey(x => x.TransactionId);
            e.Property(x => x.TransactionId).HasColumnName("transaction_id");
            e.Property(x => x.UserId).HasColumnName("user_id");
            e.Property(x => x.CreatedAt).HasColumnName("created_at").HasDefaultValueSql("now()");
        });

        // â”€â”€â”€ answers â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        modelBuilder.Entity<Answer>(e =>
        {
            e.ToTable("answers");
            e.HasKey(x => x.Id);
            e.Property(x => x.Id).HasColumnName("id").HasDefaultValueSql("gen_random_uuid()");
            e.Property(x => x.QuestionId).HasColumnName("question_id");
            e.Property(x => x.IsCorrect).HasColumnName("is_correct").HasDefaultValue(false);
            e.Property(x => x.DisplayOrder).HasColumnName("display_order").HasDefaultValue(0);
            e.Property(x => x.CreatedAt).HasColumnName("created_at").HasDefaultValueSql("now()");
            e.HasOne(x => x.Question).WithMany(q => q.Answers).HasForeignKey(x => x.QuestionId);
        });

        // â”€â”€â”€ answer_translations â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        modelBuilder.Entity<AnswerTranslation>(e =>
        {
            e.ToTable("answer_translations");
            e.HasKey(x => x.Id);
            e.Property(x => x.Id).HasColumnName("id").HasDefaultValueSql("gen_random_uuid()");
            e.Property(x => x.AnswerId).HasColumnName("answer_id");
            e.Property(x => x.LanguageCode).HasColumnName("language_code");
            e.Property(x => x.AnswerText).HasColumnName("answer_text");
            e.Property(x => x.CreatedAt).HasColumnName("created_at").HasDefaultValueSql("now()");
            e.HasOne(x => x.Answer).WithMany(a => a.Translations).HasForeignKey(x => x.AnswerId);
        });

        // â”€â”€â”€ pvp_invitations â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        modelBuilder.Entity<PvpInvitation>(e =>
        {
            e.ToTable("pvp_invitations");
            e.HasKey(x => x.Id);
            e.Property(x => x.Id).HasColumnName("id").HasDefaultValueSql("gen_random_uuid()");
            e.Property(x => x.SenderId).HasColumnName("sender_id");
            e.Property(x => x.RecipientId).HasColumnName("recipient_id");
            e.Property(x => x.Status).HasColumnName("status").HasDefaultValue("pending");
            e.Property(x => x.MatchId).HasColumnName("match_id");
            e.Property(x => x.CreatedAt).HasColumnName("created_at").HasDefaultValueSql("now()");
            e.Property(x => x.ExpiresAt).HasColumnName("expires_at").HasDefaultValueSql("(now() + '00:05:00'::interval)");
        });

        // â”€â”€â”€ pvp_matches â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        modelBuilder.Entity<PvpMatch>(e =>
        {
            e.ToTable("pvp_matches");
            e.HasKey(x => x.Id);
            e.Property(x => x.Id).HasColumnName("id").HasDefaultValueSql("gen_random_uuid()");
            e.Property(x => x.Player1Id).HasColumnName("player1_id");
            e.Property(x => x.Player2Id).HasColumnName("player2_id");
            e.Property(x => x.Status).HasColumnName("status");
            e.Property(x => x.CurrentRound).HasColumnName("current_round").HasDefaultValue(1);
            e.Property(x => x.Player1TotalScore).HasColumnName("player1_total_score").HasDefaultValue(0);
            e.Property(x => x.Player2TotalScore).HasColumnName("player2_total_score").HasDefaultValue(0);
            e.Property(x => x.WinnerId).HasColumnName("winner_id");
            e.Property(x => x.Player1RatingBefore).HasColumnName("player1_rating_before");
            e.Property(x => x.Player2RatingBefore).HasColumnName("player2_rating_before");
            e.Property(x => x.Player1RatingChange).HasColumnName("player1_rating_change").HasDefaultValue(0);
            e.Property(x => x.Player2RatingChange).HasColumnName("player2_rating_change").HasDefaultValue(0);
            e.Property(x => x.CreatedAt).HasColumnName("created_at").HasDefaultValueSql("now()");
            e.Property(x => x.StartedAt).HasColumnName("started_at");
            e.Property(x => x.CompletedAt).HasColumnName("completed_at");
            e.Property(x => x.UpdatedAt).HasColumnName("updated_at").HasDefaultValueSql("now()");
        });

        // â”€â”€â”€ pvp_matchmaking_queue â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        modelBuilder.Entity<PvpMatchmakingQueue>(e =>
        {
            e.ToTable("pvp_matchmaking_queue");
            e.HasKey(x => x.Id);
            e.Property(x => x.Id).HasColumnName("id").HasDefaultValueSql("gen_random_uuid()");
            e.Property(x => x.UserId).HasColumnName("user_id");
            e.Property(x => x.Rating).HasColumnName("rating");
            e.Property(x => x.PreferredLanguage).HasColumnName("preferred_language");
            e.Property(x => x.CreatedAt).HasColumnName("created_at").HasDefaultValueSql("now()");
            e.Property(x => x.LastSeen).HasColumnName("last_seen").HasDefaultValueSql("now()");
        });

        // â”€â”€â”€ pvp_rounds â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        modelBuilder.Entity<PvpRound>(e =>
        {
            e.ToTable("pvp_rounds");
            e.HasKey(x => x.Id);
            e.Property(x => x.Id).HasColumnName("id").HasDefaultValueSql("gen_random_uuid()");
            e.Property(x => x.MatchId).HasColumnName("match_id");
            e.Property(x => x.RoundNumber).HasColumnName("round_number");
            e.Property(x => x.QuestionIds).HasColumnName("question_ids").HasColumnType("text[]");
            e.Property(x => x.Player1Score).HasColumnName("player1_score").HasDefaultValue(0);
            e.Property(x => x.Player2Score).HasColumnName("player2_score").HasDefaultValue(0);
            e.Property(x => x.Player1Answers).HasColumnName("player1_answers").HasColumnType("jsonb").HasDefaultValueSql("'[]'::jsonb");
            e.Property(x => x.Player1CompletedAt).HasColumnName("player1_completed_at");
            e.Property(x => x.Player2Answers).HasColumnName("player2_answers").HasColumnType("jsonb").HasDefaultValueSql("'[]'::jsonb");
            e.Property(x => x.Player2CompletedAt).HasColumnName("player2_completed_at");
            e.Property(x => x.CreatedAt).HasColumnName("created_at").HasDefaultValueSql("now()");
            e.Property(x => x.ThemeId).HasColumnName("theme_id");
            e.HasOne(x => x.Match).WithMany(m => m.Rounds).HasForeignKey(x => x.MatchId);
        });

        // â”€â”€â”€ question_concepts â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        modelBuilder.Entity<QuestionConcept>(e =>
        {
            e.ToTable("question_concepts");
            e.HasKey(x => x.Id);
            e.Property(x => x.Id).HasColumnName("id").HasDefaultValueSql("gen_random_uuid()");
            e.Property(x => x.Concept).HasColumnName("concept");
            e.Property(x => x.ThemeId).HasColumnName("theme_id");
            e.Property(x => x.CreatedAt).HasColumnName("created_at").HasDefaultValueSql("now()");
            e.Property(x => x.ConceptEn).HasColumnName("concept_en");
            e.Property(x => x.ConceptFr).HasColumnName("concept_fr");
            e.HasOne(x => x.Theme).WithMany(t => t.Concepts).HasForeignKey(x => x.ThemeId);
        });

        // â”€â”€â”€ question_translations â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        modelBuilder.Entity<QuestionTranslation>(e =>
        {
            e.ToTable("question_translations");
            e.HasKey(x => x.Id);
            e.Property(x => x.Id).HasColumnName("id").HasDefaultValueSql("gen_random_uuid()");
            e.Property(x => x.QuestionId).HasColumnName("question_id");
            e.Property(x => x.LanguageCode).HasColumnName("language_code");
            e.Property(x => x.QuestionText).HasColumnName("question_text");
            e.Property(x => x.Explanation).HasColumnName("explanation");
            e.Property(x => x.CreatedAt).HasColumnName("created_at").HasDefaultValueSql("now()");
            e.HasOne(x => x.Question).WithMany(q => q.Translations).HasForeignKey(x => x.QuestionId);
        });

        // â”€â”€â”€ questions â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        modelBuilder.Entity<Question>(e =>
        {
            e.ToTable("questions");
            e.HasKey(x => x.Id);
            e.Property(x => x.Id).HasColumnName("id").HasDefaultValueSql("gen_random_uuid()");
            e.Property(x => x.ThemeId).HasColumnName("theme_id");
            e.Property(x => x.Difficulty).HasColumnName("difficulty");
            e.Property(x => x.TimesUsed).HasColumnName("times_used").HasDefaultValue(0);
            e.Property(x => x.CreatedAt).HasColumnName("created_at").HasDefaultValueSql("now()");
            e.Property(x => x.IsVerified).HasColumnName("is_verified").HasDefaultValue(false);
            e.Property(x => x.VerifiedAt).HasColumnName("verified_at");
            e.Property(x => x.ConceptId).HasColumnName("concept_id");
            e.HasOne(x => x.Theme).WithMany(t => t.Questions).HasForeignKey(x => x.ThemeId);
            e.HasOne(x => x.Concept).WithMany(c => c.Questions).HasForeignKey(x => x.ConceptId);
        });

        // â”€â”€â”€ survival_scores â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        modelBuilder.Entity<SurvivalScore>(e =>
        {
            e.ToTable("survival_scores");
            e.HasKey(x => x.Id);
            e.Property(x => x.Id).HasColumnName("id").HasDefaultValueSql("gen_random_uuid()");
            e.Property(x => x.UserId).HasColumnName("user_id");
            e.Property(x => x.ThemeId).HasColumnName("theme_id");
            e.Property(x => x.Score).HasColumnName("score").HasDefaultValue(0);
            e.Property(x => x.PlayedAt).HasColumnName("played_at").HasDefaultValueSql("now()");
        });

        // â”€â”€â”€ themes â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        modelBuilder.Entity<Theme>(e =>
        {
            e.ToTable("themes");
            e.HasKey(x => x.Id);
            e.Property(x => x.Id).HasColumnName("id").HasDefaultValueSql("gen_random_uuid()");
            e.Property(x => x.Icon).HasColumnName("icon");
            e.Property(x => x.Color).HasColumnName("color");
            e.Property(x => x.CreatedAt).HasColumnName("created_at").HasDefaultValueSql("now()");
        });

        // â”€â”€â”€ theme_translations â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        modelBuilder.Entity<ThemeTranslation>(e =>
        {
            e.ToTable("theme_translations");
            e.HasKey(x => x.Id);
            e.Property(x => x.Id).HasColumnName("id").HasDefaultValueSql("gen_random_uuid()");
            e.Property(x => x.ThemeId).HasColumnName("theme_id");
            e.Property(x => x.LanguageCode).HasColumnName("language_code");
            e.Property(x => x.Name).HasColumnName("name");
            e.Property(x => x.Description).HasColumnName("description");
            e.Property(x => x.CreatedAt).HasColumnName("created_at").HasDefaultValueSql("now()");
            e.HasOne(x => x.Theme).WithMany(t => t.Translations).HasForeignKey(x => x.ThemeId);
        });

        // â”€â”€â”€ user_achievements â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        modelBuilder.Entity<UserAchievement>(e =>
        {
            e.ToTable("user_achievements");
            e.HasKey(x => x.Id);
            e.Property(x => x.Id).HasColumnName("id").HasDefaultValueSql("gen_random_uuid()");
            e.Property(x => x.UserId).HasColumnName("user_id");
            e.Property(x => x.AchievementId).HasColumnName("achievement_id");
            e.Property(x => x.UnlockedAt).HasColumnName("unlocked_at").HasDefaultValueSql("now()");
            e.HasOne(x => x.Achievement).WithMany().HasForeignKey(x => x.AchievementId);
        });

        // â”€â”€â”€ user_answers â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        modelBuilder.Entity<UserAnswer>(e =>
        {
            e.ToTable("user_answers");
            e.HasKey(x => x.Id);
            e.Property(x => x.Id).HasColumnName("id").HasDefaultValueSql("gen_random_uuid()");
            e.Property(x => x.UserId).HasColumnName("user_id");
            e.Property(x => x.QuestionId).HasColumnName("question_id");
            e.Property(x => x.SelectedAnswerId).HasColumnName("selected_answer_id");
            e.Property(x => x.IsCorrect).HasColumnName("is_correct");
            e.Property(x => x.LanguageUsed).HasColumnName("language_used");
            e.Property(x => x.AnsweredAt).HasColumnName("answered_at").HasDefaultValueSql("now()");
            e.HasOne(x => x.Question).WithMany().HasForeignKey(x => x.QuestionId);
            e.HasOne(x => x.SelectedAnswer).WithMany().HasForeignKey(x => x.SelectedAnswerId);
        });

        // â”€â”€â”€ user_fcm_tokens â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        modelBuilder.Entity<UserFcmToken>(e =>
        {
            e.ToTable("user_fcm_tokens");
            e.HasKey(x => x.Id);
            e.Property(x => x.Id).HasColumnName("id").HasDefaultValueSql("gen_random_uuid()");
            e.Property(x => x.UserId).HasColumnName("user_id");
            e.Property(x => x.Token).HasColumnName("token");
            e.Property(x => x.Platform).HasColumnName("platform");
            e.Property(x => x.CreatedAt).HasColumnName("created_at").HasDefaultValueSql("now()");
            e.Property(x => x.UpdatedAt).HasColumnName("updated_at").HasDefaultValueSql("now()");
        });

        // â”€â”€â”€ user_follows â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        modelBuilder.Entity<UserFollow>(e =>
        {
            e.ToTable("user_follows");
            e.HasKey(x => x.Id);
            e.Property(x => x.Id).HasColumnName("id").HasDefaultValueSql("gen_random_uuid()");
            e.Property(x => x.FollowerId).HasColumnName("follower_id");
            e.Property(x => x.FollowingId).HasColumnName("following_id");
            e.Property(x => x.CreatedAt).HasColumnName("created_at").HasDefaultValueSql("now()");
        });

        // â”€â”€â”€ user_lives â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        modelBuilder.Entity<UserLife>(e =>
        {
            e.ToTable("user_lives");
            e.HasKey(x => x.Id);
            e.Property(x => x.Id).HasColumnName("id").HasDefaultValueSql("gen_random_uuid()");
            e.Property(x => x.UserId).HasColumnName("user_id");
            e.Property(x => x.CurrentLives).HasColumnName("current_lives").HasDefaultValue(10);
            e.Property(x => x.MaxLives).HasColumnName("max_lives").HasDefaultValue(10);
            e.Property(x => x.LastRegenAt).HasColumnName("last_regen_at").HasDefaultValueSql("now()");
            e.Property(x => x.CreatedAt).HasColumnName("created_at").HasDefaultValueSql("now()");
            e.Property(x => x.UpdatedAt).HasColumnName("updated_at").HasDefaultValueSql("now()");
            e.Property(x => x.LastAdLivesAt).HasColumnName("last_ad_lives_at");
        });

        // â”€â”€â”€ user_profiles â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        modelBuilder.Entity<UserProfile>(e =>
        {
            e.ToTable("user_profiles");
            e.HasKey(x => x.UserId);
            e.Property(x => x.UserId).HasColumnName("user_id");
            e.Property(x => x.DisplayName).HasColumnName("display_name");
            e.Property(x => x.CreatedAt).HasColumnName("created_at").HasDefaultValueSql("now()");
            e.Property(x => x.UpdatedAt).HasColumnName("updated_at").HasDefaultValueSql("now()");
        });

        // â”€â”€â”€ user_stats â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        modelBuilder.Entity<UserStat>(e =>
        {
            e.ToTable("user_stats");
            e.HasKey(x => x.UserId);
            e.Property(x => x.UserId).HasColumnName("user_id");
            e.Property(x => x.TotalQuestions).HasColumnName("total_questions").HasDefaultValue(0);
            e.Property(x => x.CorrectAnswers).HasColumnName("correct_answers").HasDefaultValue(0);
            e.Property(x => x.CurrentStreak).HasColumnName("current_streak").HasDefaultValue(0);
            e.Property(x => x.BestStreak).HasColumnName("best_streak").HasDefaultValue(0);
            e.Property(x => x.PreferredLanguage).HasColumnName("preferred_language").HasDefaultValue("en");
            e.Property(x => x.LastPlayedAt).HasColumnName("last_played_at");
            e.Property(x => x.UpdatedAt).HasColumnName("updated_at").HasDefaultValueSql("now()");
            e.Property(x => x.HasCompletedOnboarding).HasColumnName("has_completed_onboarding").HasDefaultValue(false);
            e.Property(x => x.PvpRating).HasColumnName("pvp_rating").HasDefaultValue(1000);
            e.Property(x => x.PvpWins).HasColumnName("pvp_wins").HasDefaultValue(0);
            e.Property(x => x.PvpLosses).HasColumnName("pvp_losses").HasDefaultValue(0);
            e.Property(x => x.PvpDraws).HasColumnName("pvp_draws").HasDefaultValue(0);
            e.Property(x => x.Username).HasColumnName("username");
            e.Property(x => x.LastDailyCompletedAt).HasColumnName("last_daily_completed_at");
            e.Property(x => x.TimezoneOffsetHours).HasColumnName("timezone_offset_hours").HasDefaultValue(0);
            e.Property(x => x.LastAnswerAt).HasColumnName("last_answer_at");
            e.Property(x => x.DailyStreak).HasColumnName("daily_streak").HasDefaultValue(0);
        });

        // â”€â”€â”€ user_theme_preferences â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        modelBuilder.Entity<UserThemePreference>(e =>
        {
            e.ToTable("user_theme_preferences");
            e.HasKey(x => x.Id);
            e.Property(x => x.Id).HasColumnName("id").HasDefaultValueSql("gen_random_uuid()");
            e.Property(x => x.UserId).HasColumnName("user_id");
            e.Property(x => x.ThemeId).HasColumnName("theme_id");
            e.Property(x => x.CreatedAt).HasColumnName("created_at").HasDefaultValueSql("now()");
            e.HasOne(x => x.Theme).WithMany().HasForeignKey(x => x.ThemeId);
        });

        // â”€â”€â”€ user_theme_progress â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        modelBuilder.Entity<UserThemeProgress>(e =>
        {
            e.ToTable("user_theme_progress");
            e.HasKey(x => x.Id);
            e.Property(x => x.Id).HasColumnName("id").HasDefaultValueSql("gen_random_uuid()");
            e.Property(x => x.UserId).HasColumnName("user_id");
            e.Property(x => x.ThemeId).HasColumnName("theme_id");
            e.Property(x => x.Xp).HasColumnName("xp").HasDefaultValue(0);
            e.Property(x => x.Level).HasColumnName("level").HasDefaultValue(1);
            e.Property(x => x.TotalQuestions).HasColumnName("total_questions").HasDefaultValue(0);
            e.Property(x => x.CorrectAnswers).HasColumnName("correct_answers").HasDefaultValue(0);
            e.Property(x => x.CreatedAt).HasColumnName("created_at").HasDefaultValueSql("now()");
            e.Property(x => x.UpdatedAt).HasColumnName("updated_at").HasDefaultValueSql("now()");
            e.HasOne(x => x.Theme).WithMany().HasForeignKey(x => x.ThemeId);
        });

    }
}

