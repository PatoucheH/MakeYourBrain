# MakeYourBrain

Backend d'une application de quiz intelligent avec génération automatique de questions par IA.

## Description

MakeYourBrain est une plateforme de quiz multilingue (FR/EN) qui utilise l'IA Claude d'Anthropic pour générer automatiquement des questions à choix multiples organisées par thèmes et niveaux de difficulté.

## Stack Technique

- **Supabase** - Infrastructure backend (Auth, Database, Edge Functions, Storage)
- **PostgreSQL 17** - Base de données
- **Deno 2** - Runtime pour les Edge Functions
- **TypeScript** - Langage de programmation
- **Claude API (Anthropic)** - Génération de questions par IA

## Structure du Projet

```
MakeYourBrain/
├── README.md
├── .vscode/
│   ├── settings.json
│   └── extensions.json
└── supabase/
    ├── config.toml
    └── functions/
        └── generate-questions/
            ├── index.ts
            ├── deno.json
            └── .npmrc
```

## Base de Données

### Schéma

| Table | Description |
|-------|-------------|
| `themes` | Thèmes des quiz (icône, couleur) |
| `theme_translations` | Traductions des thèmes (FR/EN) |
| `questions` | Questions (thème, difficulté, compteur d'utilisation) |
| `question_translations` | Traductions des questions et explications |
| `answers` | Réponses (correct/incorrect, ordre d'affichage) |
| `answer_translations` | Traductions des réponses |

### Ajouter un Thème

```sql
-- Créer le thème
INSERT INTO themes (icon, color) VALUES ('🔬', '#8B5CF6');

-- Récupérer son ID
SELECT id FROM themes WHERE icon = '🔬';

-- Ajouter les traductions
INSERT INTO theme_translations (theme_id, language_code, name, description) VALUES
  ('theme-id-ici', 'en', 'Science', 'Physics, chemistry, biology and technology'),
  ('theme-id-ici', 'fr', 'Sciences', 'Physique, chimie, biologie et technologie');
```

## Edge Functions

### generate-questions

Génère automatiquement des questions de quiz via Claude AI.

**Endpoint:** `POST /functions/v1/generate-questions`

**Fonctionnalités:**
- Génère 5 questions uniques par thème
- Supporte 3 niveaux de difficulté (easy, medium, hard)
- Questions bilingues (FR/EN)
- 4 réponses par question avec une seule correcte
- Inclut des explications pour chaque question
- Évite les doublons en vérifiant les questions existantes

**Réponse:**
```json
{
  "success": true,
  "message": "Question generation completed",
  "themes_processed": 5
}
```

## Installation

### Prérequis

- [Supabase CLI](https://supabase.com/docs/guides/cli)
- [Deno](https://deno.land/)

### Configuration

1. Cloner le repository
```bash
git clone <repo-url>
cd MakeYourBrain
```

2. Démarrer Supabase en local
```bash
supabase start
```

3. Configurer les variables d'environnement pour les Edge Functions
```bash
# Dans supabase/functions/.env
ANTHROPIC_API_KEY=your_anthropic_api_key
```

4. Déployer les fonctions
```bash
supabase functions deploy generate-questions
```

## Ports (Développement Local)

| Service | Port |
|---------|------|
| API REST/GraphQL | 54321 |
| PostgreSQL | 54322 |
| Supabase Studio | 54323 |
| Inbucket (Email) | 54324 |
| Analytics | 54327 |

## API

### REST API

Base URL: `http://127.0.0.1:54321/rest/v1/`

Tous les endpoints CRUD sont auto-générés par Supabase pour chaque table.

### GraphQL

Endpoint: `http://127.0.0.1:54321/graphql/v1`

## Variables d'Environnement

| Variable | Description |
|----------|-------------|
| `SUPABASE_URL` | URL du projet Supabase |
| `SUPABASE_SERVICE_ROLE_KEY` | Clé admin pour les opérations database |
| `ANTHROPIC_API_KEY` | Clé API pour Claude (génération de questions) |

## Frontend

Le frontend Flutter est en cours de développement et sera ajouté prochainement.

## Licence

Projet privé - Tous droits réservés
