using System.Text;
using Hangfire;
using Hangfire.PostgreSql;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;
using MakeYourBrain.Api.Infrastructure;
using MakeYourBrain.Api.Jobs;
using MakeYourBrain.Api.Models.Entities;
using MakeYourBrain.Api.Services;

var builder = WebApplication.CreateBuilder(args);

// ─── Database ────────────────────────────────────────────────────────────────
builder.Services.AddDbContext<AppDbContext>(options =>
    options.UseNpgsql(builder.Configuration.GetConnectionString("DefaultConnection")));

builder.Services.AddSingleton<DapperConnectionFactory>();

// ─── ASP.NET Identity ────────────────────────────────────────────────────────
builder.Services.AddIdentityCore<ApplicationUser>(options =>
{
    options.Password.RequireDigit           = false;
    options.Password.RequiredLength         = 8;
    options.Password.RequireNonAlphanumeric = false;
    options.Password.RequireUppercase       = false;
    options.User.RequireUniqueEmail         = true;
})
.AddRoles<IdentityRole<Guid>>()
.AddEntityFrameworkStores<AppDbContext>();

// ─── Authentication — own HS256 JWT ──────────────────────────────────────────
var jwtSecret = builder.Configuration["Jwt:Secret"]
    ?? throw new InvalidOperationException("Jwt:Secret is not configured");
var jwtIssuer = builder.Configuration["Jwt:Issuer"] ?? "makeyourbrain";
var signingKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtSecret));

builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuerSigningKey = true,
            IssuerSigningKey         = signingKey,
            ValidateIssuer           = true,
            ValidIssuer              = jwtIssuer,
            ValidateAudience         = false,
            ValidateLifetime         = true,
            ClockSkew                = TimeSpan.FromSeconds(30),
            // Map "sub" → NameIdentifier and "role" → Role for ClaimsPrincipalExtensions
            NameClaimType            = "sub",
            RoleClaimType            = "role",
        };
    });

builder.Services.AddAuthorization();

// ─── Services ─────────────────────────────────────────────────────────────
builder.Services.AddHttpClient();
builder.Services.AddScoped<TokenService>();
builder.Services.AddScoped<UserProvisioningService>();
builder.Services.AddScoped<SocialAuthService>();
builder.Services.AddScoped<PvpService>();
builder.Services.AddScoped<QuizService>();
builder.Services.AddScoped<LivesService>();
builder.Services.AddScoped<LeaderboardService>();
builder.Services.AddScoped<SocialService>();
builder.Services.AddScoped<AchievementService>();
builder.Services.AddScoped<ProfileService>();
builder.Services.AddScoped<FirebaseFcmService>();
builder.Services.AddScoped<AdMobVerificationService>();
builder.Services.AddScoped<ClaudeApiService>();

// ─── Hangfire ─────────────────────────────────────────────────────────────
builder.Services.AddHangfire(cfg => cfg
    .SetDataCompatibilityLevel(CompatibilityLevel.Version_180)
    .UseSimpleAssemblyNameTypeSerializer()
    .UseRecommendedSerializerSettings()
    .UsePostgreSqlStorage(o => o.UseNpgsqlConnection(
        builder.Configuration.GetConnectionString("DefaultConnection")!)));
builder.Services.AddHangfireServer();

// ─── CORS ─────────────────────────────────────────────────────────────────
var allowedOrigins = builder.Configuration.GetSection("Cors:AllowedOrigins").Get<string[]>() ?? [];
builder.Services.AddCors(options =>
    options.AddDefaultPolicy(policy =>
        policy.WithOrigins(allowedOrigins)
              .AllowAnyHeader()
              .AllowAnyMethod()));

// ─── API ──────────────────────────────────────────────────────────────────
builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =>
{
    c.EnableAnnotations();
    c.SwaggerDoc("v1", new OpenApiInfo { Title = "MakeYourBrain API", Version = "v1" });
    c.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
    {
        Description = "JWT Authorization header using the Bearer scheme. Enter: Bearer {token}",
        Name        = "Authorization",
        In          = ParameterLocation.Header,
        Type        = SecuritySchemeType.Http,
        Scheme      = "bearer",
        BearerFormat = "JWT",
    });
    c.AddSecurityRequirement(new OpenApiSecurityRequirement
    {
        {
            new OpenApiSecurityScheme { Reference = new OpenApiReference { Type = ReferenceType.SecurityScheme, Id = "Bearer" } },
            Array.Empty<string>()
        }
    });
});

var app = builder.Build();

app.UseSwagger();
app.UseSwaggerUI();

app.UseCors();
app.UseAuthentication();
app.UseAuthorization();
app.MapControllers();

// ─── Hangfire dashboard & recurring jobs ──────────────────────────────────
app.UseHangfireDashboard("/hangfire");

RecurringJob.AddOrUpdate<GenerateQuestionsJob>(
    "generate-questions",
    job => job.ExecuteAsync(),
    "0 0 * * *",                       // daily at midnight UTC
    new RecurringJobOptions { TimeZone = TimeZoneInfo.Utc });

RecurringJob.AddOrUpdate<SendStreakRemindersJob>(
    "send-streak-reminders",
    job => job.ExecuteAsync(),
    "0 * * * *",                       // every hour
    new RecurringJobOptions { TimeZone = TimeZoneInfo.Utc });

RecurringJob.AddOrUpdate<CleanupMatchmakingQueueJob>(
    "cleanup-matchmaking-queue",
    job => job.ExecuteAsync(),
    "*/5 * * * *",                     // every 5 minutes
    new RecurringJobOptions { TimeZone = TimeZoneInfo.Utc });

app.Run();
