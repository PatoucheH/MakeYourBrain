import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/models/theme_model.dart';
import '../../../auth/data/repositories/auth_repository.dart';
import '../../../profile/data/repositories/profile_repository.dart';
import 'quiz_page.dart';
import '../../../leaderboard/presentation/pages/leaderboard_page.dart';
import '../../../lives/data/providers/lives_provider.dart';

class ThemeDetailPage extends StatefulWidget {
  final ThemeModel theme;

  const ThemeDetailPage({super.key, required this.theme});

  @override
  State<ThemeDetailPage> createState() => _ThemeDetailPageState();
}

class _ThemeDetailPageState extends State<ThemeDetailPage> {
  final _authRepo = AuthRepository();
  final _profileRepo = ProfileRepository();
  
  int level = 1;
  int xp = 0;
  int xpForNextLevel = 100;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadThemeProgress();
  }

  Future<void> loadThemeProgress() async {
    try {
      final userId = _authRepo.getCurrentUserId();
      if (userId != null) {
        final progress = await _profileRepo.getProgressByTheme(userId);
        
        final themeProgress = progress.firstWhere(
          (p) => p['theme_id'] == widget.theme.id,
          orElse: () => {},
        );

        if (themeProgress.isNotEmpty) {
          setState(() {
            level = themeProgress['level'] ?? 1;
            xp = themeProgress['xp'] ?? 0;
            xpForNextLevel = themeProgress['xp_for_next_level'] ?? 100;
          });
        }
      }
    } catch (e) {
      print('Error loading theme progress: $e');
    } finally {
      setState(() => isLoading = false);
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
    final themeColor = _getColorForLevel(level);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text(widget.theme.icon, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(child: Text(widget.theme.name)),
          ],
        ),
        backgroundColor: themeColor.withOpacity(0.1),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  // XP & Level Section
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          themeColor.withOpacity(0.2),
                          themeColor.withOpacity(0.05),
                        ],
                      ),
                    ),
                    child: Column(
                      children: [
                        // Level Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: themeColor,
                            borderRadius: BorderRadius.circular(25),
                            boxShadow: [
                              BoxShadow(
                                color: themeColor.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Text(
                            '${l10n.level} $level',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // XP Progress
                        Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '$xp / $xpForNextLevel ${l10n.xp}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '${((xp / xpForNextLevel) * 100).toStringAsFixed(0)}%',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: LinearProgressIndicator(
                                value: xp / xpForNextLevel,
                                minHeight: 12,
                                backgroundColor: Colors.grey.shade200,
                                valueColor: AlwaysStoppedAnimation<Color>(themeColor),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Start Quiz Button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          final livesProvider = context.read<LivesProvider>();
                          
                          if (livesProvider.currentLives <= 0) {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('❤️ No Lives Left'),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text('You need at least 1 life to play.'),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Next life in: ${livesProvider.getTimeUntilNextLife()}',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue,
                                      ),
                                    ),
                                  ],
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('OK'),
                                  ),
                                  // TODO: Bouton "Watch Ad" pour plus tard
                                ],
                              ),
                            );
                            return;
                          }
                          
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => QuizPage(theme: widget.theme),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: themeColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.all(20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 4,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.play_arrow, size: 32),
                            const SizedBox(width: 12),
                            Text(
                              l10n.startQuiz,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Leaderboard Button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => LeaderboardPage(
                                themeId: widget.theme.id,
                                themeName: widget.theme.name,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.leaderboard, size: 24),
                        label: Text(
                          l10n.viewLeaderboard,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                          side: BorderSide(color: themeColor, width: 2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Theme Description
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.aboutThisTheme,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              widget.theme.description,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  // Placeholder for future features
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      l10n.moreFeaturesComingSoon,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}