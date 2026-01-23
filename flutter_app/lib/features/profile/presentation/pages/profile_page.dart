import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../auth/data/repositories/auth_repository.dart';
import '../../../auth/data/models/user_model.dart';
import '../../data/repositories/profile_repository.dart';
import '../../../quiz/data/repositories/theme_preferences_repository.dart';
import '../../../quiz/data/repositories/quiz_repository.dart';
import '../../../quiz/data/models/theme_model.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _authRepo = AuthRepository();
  final _profileRepo = ProfileRepository();
  final _prefsRepo = ThemePreferencesRepository();
  final _quizRepo = QuizRepository();
  
  UserModel? userStats;
  List<Map<String, dynamic>> progressByTheme = [];
  List<ThemeModel> favoriteThemes = [];
  List<String> favoriteThemeIds = [];
  bool isLoading = true;
  String selectedLanguage = 'en';

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  Future<void> loadProfile() async {
    try {
      final currentLang = context.read<LanguageProvider>().currentLanguage;
      final userId = _authRepo.getCurrentUserId()!;
      
      final stats = await _authRepo.getUserStats();
      final progress = await _profileRepo.getProgressByTheme(userId);
      
      // Charger les thèmes préférés
      final preferredIds = await _prefsRepo.getPreferences(userId);
      final allThemes = await _quizRepo.getThemes(currentLang);
      final preferred = allThemes
          .where((theme) => preferredIds.contains(theme.id))
          .toList();

      setState(() {
        userStats = stats;
        selectedLanguage = currentLang;
        progressByTheme = progress;
        favoriteThemes = preferred;
        favoriteThemeIds = preferredIds;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: $e')),
        );
      }
    }
  }

  Future<void> updateLanguage(String newLanguage) async {
    final l10n = AppLocalizations.of(context)!;
    
    try {
      await context.read<LanguageProvider>().setLanguage(newLanguage);
      setState(() => selectedLanguage = newLanguage);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.languageUpdated)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.errorLoadingProfile}: $e')),
        );
      }
    }
  }

  Future<void> removeThemeFromFavorites(BuildContext context, String themeId, String themeName) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final userId = _authRepo.getCurrentUserId()!;
      final updatedPreferences = favoriteThemeIds
          .where((id) => id != themeId)
          .toList();
      
      await _prefsRepo.savePreferences(userId, updatedPreferences);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$themeName removed from favorites')),
        );
        loadProfile();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error removing theme : $e')),
        );
      }
    }
  }

  Color _getColorForLevel(int level) {
    if (level >= 10) return Colors.purple;
    if (level >= 7) return Colors.red;
    if (level >= 5) return Colors.orange;
    if (level >= 3) return Colors.green;
    return Colors.blue;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.profile)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.profile),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Email
            Card(
              child: ListTile(
                leading: const Icon(Icons.email),
                title: Text(userStats?.email ?? 'No email'),
                subtitle: Text(l10n.email),
              ),
            ),
            const SizedBox(height: 16),

            // Language selector
            Card(
              child: ListTile(
                leading: const Icon(Icons.language),
                title: Text(l10n.preferredLanguage),
                trailing: DropdownButton<String>(
                  value: selectedLanguage,
                  items: const [
                    DropdownMenuItem(value: 'en', child: Text('🇬🇧 English')),
                    DropdownMenuItem(value: 'fr', child: Text('🇫🇷 Français')),
                  ],
                  onChanged: (value) {
                    if (value != null) updateLanguage(value);
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Stats section
            Text(
              l10n.statistics,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // Streak
            Card(
              color: Colors.orange.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.local_fire_department, size: 40, color: Colors.orange),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${userStats?.currentStreak ?? 0} ${l10n.days}',
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        Text(l10n.currentStreak),
                        Text(
                          '${l10n.bestStreak}: ${userStats?.bestStreak ?? 0} ${l10n.days}',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Overall stats
            Row(
              children: [
                Expanded(
                  child: Card(
                    color: Colors.blue.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Icon(Icons.quiz, size: 32),
                          const SizedBox(height: 8),
                          Text(
                            '${userStats?.totalQuestions ?? 0}',
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                          Text(l10n.questions),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Card(
                    color: Colors.green.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Icon(Icons.check_circle, size: 32),
                          const SizedBox(height: 8),
                          Text(
                            '${userStats?.accuracy.toStringAsFixed(0) ?? 0}%',
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                          Text(l10n.accuracy),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Progress by theme
            Text(
              l10n.progressByTheme,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            if (progressByTheme.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(l10n.noProgressYet),
                ),
              )
            else
              ...progressByTheme.map((theme) {
                final level = theme['level'] ?? 1;
                final xp = theme['xp'] ?? 0;
                final xpForNextLevel = theme['xp_for_next_level'] ?? 100;
                final xpProgress = xp / xpForNextLevel;
                final total = theme['total_questions'] ?? 0;
                final correct = theme['correct_answers'] ?? 0;

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              theme['icon'] ?? '❓',
                              style: const TextStyle(fontSize: 40),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    theme['theme_name'] ?? 'Unknown',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$correct / $total ${l10n.correct}',
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: _getColorForLevel(level),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${l10n.level} $level',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '$xp / $xpForNextLevel ${l10n.xp}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '${(xpProgress * 100).toStringAsFixed(0)}%',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: LinearProgressIndicator(
                                value: xpProgress,
                                minHeight: 10,
                                backgroundColor: Colors.grey.shade200,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  _getColorForLevel(level),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),

            const SizedBox(height: 24),

            // Manage Favorite Themes
            Text(
              l10n.manageFavoriteThemes,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            if (favoriteThemes.isEmpty)
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(l10n.noFavoriteThemesProfile),
                ),
              )
            else
              ...favoriteThemes.map((theme) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: Text(
                      theme.icon,
                      style: const TextStyle(fontSize: 32),
                    ),
                    title: Text(theme.name),
                    trailing: IconButton(
                      icon: const Icon(Icons.remove_circle, color: Colors.red),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text(l10n.removeFromFavorites),
                            content: Text('Remove ${theme.name} from your favorite themes?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text(l10n.cancel),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  removeThemeFromFavorites(context, theme.id, theme.name);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                ),
                                child: Text(l10n.remove),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                );
              }).toList(),
          ],
        ),
      ),
    );
  }
}