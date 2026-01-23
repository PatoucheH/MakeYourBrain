import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/providers/language_provider.dart';
import '../../data/repositories/quiz_repository.dart';
import '../../data/repositories/theme_preferences_repository.dart';
import '../../data/models/theme_model.dart';
import '../../../auth/data/repositories/auth_repository.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../../../profile/presentation/pages/profile_page.dart';
import '../../../profile/data/repositories/profile_repository.dart';
import 'theme_detail_page.dart';
import 'all_themes_page.dart';
import 'add_theme_page.dart';
import '../../../leaderboard/presentation/pages/leaderboard_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _authRepo = AuthRepository();
  final _quizRepo = QuizRepository();
  final _prefsRepo = ThemePreferencesRepository();
  final _profileRepo = ProfileRepository();
  
  List<ThemeModel> favoriteThemes = [];
  List<String> favoriteThemeIds = [];
  Map<String, Map<String, dynamic>> themeProgress = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadFavoriteThemes();
  }

  Future<void> loadFavoriteThemes() async {
    try {
      final userId = _authRepo.getCurrentUserId()!;
      final languageCode = context.read<LanguageProvider>().currentLanguage;
      
      // Charger les IDs des thèmes préférés
      final preferredIds = await _prefsRepo.getPreferences(userId);
      
      // Charger tous les thèmes
      final allThemes = await _quizRepo.getThemes(languageCode);
      
      // Filtrer pour garder uniquement les préférés
      final preferred = allThemes
          .where((theme) => preferredIds.contains(theme.id))
          .toList();
      
      // Charger la progression
      final progress = await _profileRepo.getProgressByTheme(userId);
      final progressMap = <String, Map<String, dynamic>>{};
      for (var p in progress) {
        progressMap[p['theme_id']] = p;
      }
      
      setState(() {
        favoriteThemes = preferred;
        favoriteThemeIds = preferredIds;
        themeProgress = progressMap;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading favorites: $e')),
        );
      }
    }
  }

  Future<void> navigateToAddTheme() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddThemePage(currentPreferences: favoriteThemeIds),
      ),
    );
    
    // Si un thème a été ajouté, recharger
    if (result == true) {
      loadFavoriteThemes();
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

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appName),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            tooltip: l10n.profile,
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfilePage()),
              );
              // Recharger au retour du profil (si préférences modifiées)
              loadFavoriteThemes();
            },
          ),
          IconButton(
            icon: const Icon(Icons.leaderboard),
            tooltip: l10n.leaderboard,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LeaderboardPage()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: l10n.logout,
            onPressed: () async {
              await _authRepo.signOut();
              if (context.mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
              }
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Header avec boutons
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            '⭐',
                            style: TextStyle(fontSize: 24),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            l10n.myFavoriteThemes,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade900,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Boutons
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: navigateToAddTheme,
                              icon: const Icon(Icons.add),
                              label: Text(l10n.addTheme),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const AllThemesPage(),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.list),
                              label: Text(l10n.allThemes),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Liste des thèmes préférés
                Expanded(
                  child: favoriteThemes.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.star_border,
                                  size: 80,
                                  color: Colors.grey.shade300,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  l10n.noFavoriteThemes,
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  l10n.tapAddTheme,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: favoriteThemes.length,
                          itemBuilder: (context, index) {
                            final theme = favoriteThemes[index];
                            final progress = themeProgress[theme.id];
                            final level = progress?['level'] ?? 1;
                            final xp = progress?['xp'] ?? 0;
                            final xpForNextLevel = progress?['xp_for_next_level'] ?? 100;
                            final themeColor = _getColorForLevel(level);

                            return Card(
                              margin: const EdgeInsets.only(bottom: 16),
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ThemeDetailPage(theme: theme),
                                    ),
                                  );
                                },
                                borderRadius: BorderRadius.circular(16),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      // Icon
                                      Container(
                                        width: 70,
                                        height: 70,
                                        decoration: BoxDecoration(
                                          color: themeColor.withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(14),
                                          border: Border.all(
                                            color: themeColor.withOpacity(0.3),
                                            width: 2,
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            theme.icon,
                                            style: const TextStyle(fontSize: 36),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      
                                      // Info
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    theme.name,
                                                    style: const TextStyle(
                                                      fontSize: 20,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 6,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: themeColor,
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  child: Text(
                                                    '${l10n.level} $level',
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 13,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 10),
                                            
                                            // XP Bar
                                            ClipRRect(
                                              borderRadius: BorderRadius.circular(8),
                                              child: LinearProgressIndicator(
                                                value: xp / xpForNextLevel,
                                                minHeight: 8,
                                                backgroundColor: Colors.grey.shade200,
                                                valueColor: AlwaysStoppedAnimation<Color>(themeColor),
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  '$xp / $xpForNextLevel ${l10n.xp}',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w500,
                                                    color: Colors.grey.shade700,
                                                  ),
                                                ),
                                                Text(
                                                  '${((xp / xpForNextLevel) * 100).toStringAsFixed(0)}%',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    color: Colors.grey.shade600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      
                                      const SizedBox(width: 8),
                                      Icon(
                                        Icons.arrow_forward_ios,
                                        color: Colors.grey.shade400,
                                        size: 20,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}