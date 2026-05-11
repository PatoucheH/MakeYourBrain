# MakeYourBrain — Backend ASP.NET Core

Migration du backend Supabase (Edge Functions + PostgreSQL) vers ASP.NET Core 9 + Entity Framework Core + Dapper.

## Stack

| Composant | Technologie |
|---|---|
| Framework | ASP.NET Core 9 |
| ORM | Entity Framework Core 9 + Npgsql |
| Requêtes RPCs | Dapper |
| Base de données | PostgreSQL (Supabase) |
| Authentification | JWT Supabase (HS256) via `Microsoft.AspNetCore.Authentication.JwtBearer` |
| Documentation | Swagger / OpenAPI |

## Prérequis

- .NET 9 SDK
- Accès à la base PostgreSQL Supabase (connection string)
- Clés API : Supabase JWT secret, Anthropic, Firebase service account, AdMob (configurer dans `appsettings.json`)

## Configuration

Copier `appsettings.json` et remplir les valeurs manquantes :

```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Host=db.gqicisbofczmmjogfogz.supabase.co;Port=5432;Database=postgres;Username=postgres;Password=YOUR_PASSWORD;SSL Mode=Require;Trust Server Certificate=true"
  },
  "Supabase": {
    "ProjectRef": "gqicisbofczmmjogfogz",
    "Url": "https://gqicisbofczmmjogfogz.supabase.co",
    "JwtSecret": "...",        // Dashboard Supabase → Settings → API → JWT Secret
    "ServiceRoleKey": "...",   // Dashboard Supabase → Settings → API → service_role key
    "AnonKey": "..."           // Dashboard Supabase → Settings → API → anon key
  },
  "Anthropic": {
    "ApiKey": "sk-ant-..."
  },
  "Firebase": {
    "ServiceAccountJson": "{\"type\":\"service_account\", ...}"  // JSON échappé en une seule ligne
  }
}
```

**Ne jamais committer `appsettings.json` avec des vraies clés.** Utiliser `appsettings.Development.json` ou des variables d'environnement.

## Lancer le projet

```bash
cd backend-csharp/MakeYourBrain.Api
dotnet restore
dotnet run
```

Swagger UI disponible sur : `https://localhost:5001/swagger`

## Structure

```
MakeYourBrain.Api/
├── Controllers/                  # 5 controllers (= Edge Functions migrées)
│   ├── GenerateQuestionsController.cs   POST /functions/v1/generate-questions
│   ├── SendNotificationController.cs    POST /functions/v1/send-notification
│   ├── SendStreakRemindersController.cs POST /functions/v1/send-streak-reminders
│   ├── VerifyAdRewardController.cs      GET  /functions/v1/verify-ad-reward
│   └── DeleteAccountController.cs      POST /functions/v1/delete-account
│
├── Services/                     # Logique métier + RPCs Dapper
│   ├── PvpService.cs             # 13 RPCs PvP (matchmaking, rounds, invitations)
│   ├── QuizService.cs            # Questions, daily quiz, XP, streaks
│   ├── LivesService.cs           # Vies (get, use, regen, ad reward)
│   ├── LeaderboardService.cs     # Classements (weekly, following, survival)
│   ├── SocialService.cs          # Follow/unfollow, search, display name
│   ├── AchievementService.cs     # check_achievements RPC
│   ├── ProfileService.cs         # Profil, XP, niveaux
│   ├── FirebaseFcmService.cs     # Envoi de notifications FCM v1
│   ├── AdMobVerificationService.cs  # Vérification signature ECDSA AdMob SSV
│   └── ClaudeApiService.cs       # Génération de questions via Claude API
│
├── Models/
│   ├── Entities/                 # 23 modèles EF Core (1 par table)
│   ├── Views/                    # 4 modèles pour les vues SQL (read-only)
│   └── Dtos/                     # DTOs request/response
│
└── Infrastructure/
    ├── AppDbContext.cs            # EF Core context (23 tables + 4 vues)
    ├── DapperConnectionFactory.cs # Factory de connexions Npgsql pour Dapper
    └── Extensions/
        └── ClaimsPrincipalExtensions.cs  # GetUserId(), IsServiceRole()
```

## Authentification

Le middleware JWT valide les tokens Supabase (algorithme HS256). Le secret est la clé **JWT Secret** du dashboard Supabase (`Settings → API`).

Deux niveaux d'autorisation :
- `[Authorize]` : token utilisateur valide (`role = authenticated`)
- `User.IsServiceRole()` : token service_role uniquement (cron jobs, endpoints admin)

Le `sub` du JWT est l'UUID de l'utilisateur — extrait via `User.GetUserId()`.

## Endpoints (équivalents aux Edge Functions)

| Méthode | Route | Auth | Description |
|---|---|---|---|
| POST | `/functions/v1/generate-questions` | service_role | Génère 15 questions via Claude API (cron) |
| POST | `/functions/v1/send-notification` | JWT user | Envoie une notif FCM PvP à un utilisateur |
| POST | `/functions/v1/send-streak-reminders` | service_role | Rappels streak à 22h locale (cron) |
| GET | `/functions/v1/verify-ad-reward` | Aucune | Callback AdMob SSV (ECDSA + anti-replay) |
| POST | `/functions/v1/delete-account` | JWT user | Supprime le compte via Supabase Admin API |

## RPCs disponibles (via Services)

Les 45 fonctions PostgreSQL sont wrappées dans les services Dapper. Chaque méthode exécute directement le RPC via `SELECT function_name(...)`.

### PvpService (13 RPCs)
- `JoinQueueAsync`, `LeaveQueueAsync`, `CheckQueueStatusAsync`
- `CreateRoundAsync`, `SubmitRoundAnswersAsync`
- `UpdateMatchStatusAsync`, `CompleteMatchAsync`
- `GetRandomQuestionsAsync`, `GetRandomQuestionsByThemeAsync`, `GetRandomThemeAsync`, `GetQuestionsByIdsAsync`
- `SendInvitationAsync`, `RespondInvitationAsync`, `GetPendingInvitationsAsync`

### QuizService
- `GetRandomQuestionsAsync`, `GetDailyConceptAsync`, `GetDailyQuestionsAsync`, `CompleteDailyConceptAsync`
- `AddQuizCompletionXpAsync`, `IncrementUserStatsAsync`, `UpdateUserStreakAsync`, `GetUserProgressByThemeAsync`

### LivesService
- `GetUserLivesAsync`, `UseLifeAsync`, `RegenerateLivesAsync`, `AddLivesFromAdAsync`

### LeaderboardService
- `GetWeeklyLeaderboardAsync`, `GetFollowingLeaderboardAsync`, `GetSurvivalLeaderboardAsync`

### SocialService
- `FollowUserAsync`, `UnfollowUserAsync`, `GetFollowCountsAsync`, `GetFollowersAsync`, `GetFollowingAsync`
- `SearchUsersAsync`, `GetDisplayNameAsync`

## Notes de migration importantes

1. **RLS non repliquée** : les policies Supabase RLS ne s'appliquent plus en connexion directe PostgreSQL. L'autorisation est assurée par les `[Authorize]` + vérification `user_id` dans chaque requête Dapper.

2. **Service role** : les endpoints admin vérifient `User.IsServiceRole()` (claim `role = service_role` dans le JWT).

3. **UUIDs** : Npgsql mappe nativement `uuid` PostgreSQL ↔ `Guid` C#.

4. **JSONB** : stocké en `string` dans les entités, à désérialiser à la demande.

5. **Arrays PostgreSQL** : `uuid[]` mappé en `Guid[]` via Npgsql.

6. **Supabase Admin API** : `DeleteAccountController` appelle directement l'API REST Supabase (`/auth/v1/admin/users/{id}`) avec le `ServiceRoleKey`.
