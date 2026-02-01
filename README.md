# MakeYourBrain

An AI-powered multilingual quiz platform with PvP capabilities, built with Flutter and Supabase.

## Description

MakeYourBrain is a mobile quiz application that uses Anthropic's Claude AI to automatically generate multiple-choice questions organized by themes and difficulty levels. It supports both English and French, and features solo quiz modes, timed challenges, a PvP system with ELO ratings, leaderboards, and a lives/energy system.

## Tech Stack

### Frontend
- **Flutter** (Dart) - Cross-platform mobile framework
- **Provider** - State management
- **Flutter Localizations + intl** - Bilingual support (EN/FR)
- **Supabase Flutter SDK** - Backend integration
- **Google Sign-In / Sign in with Apple** - Social authentication

### Backend
- **Supabase** - Backend-as-a-Service (Auth, Database, Edge Functions, Realtime)
- **PostgreSQL 17** - Database
- **Deno 2** - Edge Functions runtime (TypeScript)
- **Claude API (Anthropic)** - AI-powered question generation

## Features

### Quiz System
- Multiple-choice questions (4 answers, 1 correct) with explanations
- Difficulty levels: Easy, Medium, Hard
- Adaptive difficulty scaling based on user level
- Themed categories (Animals, Geography, History, etc.)
- Standard and timed quiz modes
- User theme preferences and favorites

### PvP Mode
- Create and join matches against other players
- Turn-based gameplay with round tracking
- ELO rating system (starting at 1000)
- Win/loss/draw tracking and match history

### Lives System
- 10 max lives, 1 consumed per wrong answer
- Automatic life regeneration with countdown timer
- Ad-based life refill option

### Leaderboards
- Global, weekly, and per-theme rankings
- Medal system (Gold, Silver, Bronze)

### User Profile
- Statistics: accuracy, streaks, total answers, PvP record
- Per-theme progress and level tracking
- Language preference management

### Authentication
- Email/password registration and login
- Google and Apple social sign-in
- Username validation

### Localization
- Full English and French support
- Automatic language detection on first launch
- Manual language switching with persistent preference

### AI Question Generation
- Powered by Claude 3.5 Haiku
- Generates 10 bilingual questions per theme per call
- 3 difficulty levels with explanations
- Duplicate detection to avoid re-creating existing questions

## Project Structure

```
MakeYourBrain/
├── README.md
├── .vscode/
│   ├── settings.json
│   └── extensions.json
├── flutter_app/                          # Flutter mobile application
│   ├── pubspec.yaml
│   ├── l10n.yaml
│   ├── assets/
│   │   └── branding/
│   │       ├── logo/                     # App logo
│   │       ├── icons/                    # Theme icons
│   │       └── mascot/                   # Mascot expressions
│   └── lib/
│       ├── main.dart                     # App entry point
│       ├── config/
│       │   └── supabase_config.dart      # Supabase credentials
│       ├── core/
│       │   ├── providers/
│       │   │   └── language_provider.dart # Language state
│       │   └── theme/
│       │       └── app_colors.dart       # Design system colors
│       ├── l10n/                         # Generated localization files
│       │   ├── app_localizations.dart
│       │   ├── app_localizations_en.dart
│       │   └── app_localizations_fr.dart
│       ├── shared/
│       │   └── services/
│       │       └── supabase_service.dart  # Supabase singleton
│       └── features/
│           ├── auth/                      # Authentication
│           │   ├── data/
│           │   │   ├── models/user_model.dart
│           │   │   └── repositories/auth_repository.dart
│           │   └── presentation/pages/
│           │       ├── login_page.dart
│           │       └── register_page.dart
│           ├── quiz/                      # Quiz gameplay
│           │   ├── data/
│           │   │   ├── models/
│           │   │   │   ├── question_model.dart
│           │   │   │   └── theme_model.dart
│           │   │   └── repositories/
│           │   │       ├── quiz_repository.dart
│           │   │       └── theme_preferences_repository.dart
│           │   └── presentation/pages/
│           │       ├── home_page.dart
│           │       ├── quiz_page.dart
│           │       ├── timed_quiz_page.dart
│           │       ├── theme_detail_page.dart
│           │       ├── theme_preferences_page.dart
│           │       ├── all_themes_page.dart
│           │       └── add_theme_page.dart
│           ├── pvp/                       # Player vs Player
│           │   ├── data/
│           │   │   ├── models/
│           │   │   │   ├── pvp_match_model.dart
│           │   │   │   └── pvp_round_model.dart
│           │   │   ├── providers/pvp_provider.dart
│           │   │   └── repositories/pvp_repository.dart
│           │   └── presentation/pages/
│           │       ├── pvp_menu_page.dart
│           │       └── pvp_game_page.dart
│           ├── lives/                     # Lives/energy system
│           │   ├── data/
│           │   │   ├── providers/lives_provider.dart
│           │   │   └── repositories/lives_repository.dart
│           │   └── presentation/widgets/
│           │       ├── lives_indicator.dart
│           │       └── no_lives_dialog.dart
│           ├── leaderboard/               # Rankings
│           │   ├── data/repositories/leaderboard_repository.dart
│           │   └── presentation/pages/leaderboard_page.dart
│           └── profile/                   # User profile
│               ├── data/repositories/profile_repository.dart
│               └── presentation/pages/profile_page.dart
└── supabase/                              # Backend
    ├── config.toml
    └── functions/
        └── generate-questions/
            ├── index.ts
            ├── deno.json
            └── .npmrc
```

## Architecture

The Flutter app follows a **feature-based modular architecture** with the **Repository pattern**:

```
feature/
├── data/
│   ├── models/          # Data structures (JSON serializable)
│   ├── repositories/    # Business logic & Supabase queries
│   └── providers/       # State management (ChangeNotifier)
└── presentation/
    ├── pages/           # Full-screen routes
    └── widgets/         # Reusable UI components
```

State management uses **Provider** (ChangeNotifier) for reactive UI updates across `LanguageProvider`, `LivesProvider`, and `PvPProvider`.

## Database Schema

| Table | Description |
|-------|-------------|
| `themes` | Quiz categories (icon, color) |
| `theme_translations` | Theme names and descriptions (EN/FR) |
| `questions` | Questions (theme, difficulty, usage count) |
| `question_translations` | Question text and explanations (EN/FR) |
| `answers` | Answer options (correct/incorrect, display order) |
| `answer_translations` | Answer text (EN/FR) |
| `user_stats` | User profile and statistics |
| `user_answers` | Quiz answer history |
| `pvp_matches` | PvP match records |
| `pvp_rounds` | PvP round-by-round data |
| `leaderboards` | Cached leaderboard rankings |

### Adding a Theme

```sql
-- Create the theme
INSERT INTO themes (icon, color) VALUES ('🔬', '#8B5CF6');

-- Get its ID
SELECT id FROM themes WHERE icon = '🔬';

-- Add translations
INSERT INTO theme_translations (theme_id, language_code, name, description) VALUES
  ('<theme-id>', 'en', 'Science', 'Physics, chemistry, biology and technology'),
  ('<theme-id>', 'fr', 'Sciences', 'Physique, chimie, biologie et technologie');
```

## Edge Functions

### generate-questions

Automatically generates quiz questions using Claude AI.

**Endpoint:** `POST /functions/v1/generate-questions`

**Capabilities:**
- Generates 10 unique questions per theme
- Supports 3 difficulty levels (easy, medium, hard)
- Bilingual output (EN/FR)
- 4 answers per question with 1 correct
- Includes explanations for each question
- Deduplication against existing questions

**Response:**
```json
{
  "success": true,
  "message": "Question generation completed",
  "themes_processed": 5
}
```

## Getting Started

### Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install) (>= 3.10.7)
- [Supabase CLI](https://supabase.com/docs/guides/cli)
- [Deno](https://deno.land/)

### Setup

1. Clone the repository
```bash
git clone <repo-url>
cd MakeYourBrain
```

2. Start Supabase locally
```bash
supabase start
```

3. Configure environment variables for Edge Functions
```bash
# In supabase/functions/.env
ANTHROPIC_API_KEY=your_anthropic_api_key
```

4. Deploy the Edge Functions
```bash
supabase functions deploy generate-questions
```

5. Install Flutter dependencies and run the app
```bash
cd flutter_app
flutter pub get
flutter run
```

## Environment Variables

| Variable | Description |
|----------|-------------|
| `SUPABASE_URL` | Supabase project URL |
| `SUPABASE_ANON_KEY` | Supabase anonymous/public key |
| `SUPABASE_SERVICE_ROLE_KEY` | Admin key for database operations |
| `ANTHROPIC_API_KEY` | Anthropic API key for question generation |

## Local Development Ports

| Service | Port |
|---------|------|
| REST / GraphQL API | 54321 |
| PostgreSQL | 54322 |
| Supabase Studio | 54323 |
| Inbucket (Email) | 54324 |
| Analytics | 54327 |

## License

Private project - All rights reserved
