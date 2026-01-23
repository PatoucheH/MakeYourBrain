import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/providers/language_provider.dart';
import '../../data/repositories/quiz_repository.dart';
import '../../data/models/theme_model.dart';
import '../../../auth/data/repositories/auth_repository.dart';
import '../../../profile/data/repositories/profile_repository.dart';
import 'theme_detail_page.dart';

class AllThemesPage extends StatefulWidget {
  const AllThemesPage({super.key});

  @override
  State<AllThemesPage> createState() => _AllThemesPageState();
}

class _AllThemesPageState extends State<AllThemesPage> {
  final _quizRepo = QuizRepository();
  final _authRepo = AuthRepository();
  final _profileRepo = ProfileRepository();
  
  List<ThemeModel> themes = [];
  Map<String, Map<String, dynamic>> themeProgress = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadThemes();
  }

  Future<void> loadThemes() async {
    try {
      final languageCode = context.read<LanguageProvider>().currentLanguage;
      final themesResult = await _quizRepo.getThemes(languageCode);
      
      // Charger la progression pour chaque thème
      final userId = _authRepo.getCurrentUserId();
      if (userId != null) {
        final progress = await _profileRepo.getProgressByTheme(userId);
        
        final progressMap = <String, Map<String, dynamic>>{};
        for (var p in progress) {
          progressMap[p['theme_id']] = p;
        }
        
        setState(() {
          themes = themesResult;
          themeProgress = progressMap;
          isLoading = false;
        });
      } else {
        setState(() {
          themes = themesResult;
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading themes: $e')),
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

    return Scaffold(
      appBar: AppBar(
        title: Text('📚 ${l10n.allThemes}'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: themes.length,
              itemBuilder: (context, index) {
                final theme = themes[index];
                final progress = themeProgress[theme.id];
                final level = progress?['level'] ?? 1;
                final xp = progress?['xp'] ?? 0;
                final xpForNextLevel = progress?['xp_for_next_level'] ?? 100;
                final themeColor = _getColorForLevel(level);

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  elevation: 3,
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
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: themeColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                theme.icon,
                                style: const TextStyle(fontSize: 32),
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
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: themeColor,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '${l10n.level} $level',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                
                                // XP Bar
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: LinearProgressIndicator(
                                    value: xp / xpForNextLevel,
                                    minHeight: 6,
                                    backgroundColor: Colors.grey.shade200,
                                    valueColor: AlwaysStoppedAnimation<Color>(themeColor),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$xp / $xpForNextLevel ${l10n.xp}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
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
    );
  }
}