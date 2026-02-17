import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/brain_app_bar.dart';
import '../../../auth/data/repositories/auth_repository.dart';
import '../../../auth/data/models/user_model.dart';
import '../../data/repositories/profile_repository.dart';
import '../../../quiz/data/repositories/theme_preferences_repository.dart';
import '../../../quiz/data/repositories/quiz_repository.dart';
import '../../../quiz/data/models/theme_model.dart';
import '../../../social/data/repositories/follow_repository.dart';
import '../../../social/presentation/pages/follow_list_page.dart';

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
  final _followRepo = FollowRepository();

  UserModel? userStats;
  List<Map<String, dynamic>> progressByTheme = [];
  List<ThemeModel> favoriteThemes = [];
  List<ThemeModel> allThemes = [];
  List<String> favoriteThemeIds = [];
  bool isLoading = true;
  String selectedLanguage = 'en';
  int followersCount = 0;
  int followingCount = 0;

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

      final preferredIds = await _prefsRepo.getPreferences(userId);
      final themes = await _quizRepo.getThemes(currentLang);
      final preferred = themes
          .where((theme) => preferredIds.contains(theme.id))
          .toList();
      final counts = await _followRepo.getFollowCounts(userId);

      setState(() {
        userStats = stats;
        selectedLanguage = currentLang;
        progressByTheme = progress;
        allThemes = themes;
        favoriteThemes = preferred;
        favoriteThemeIds = preferredIds;
        followersCount = counts['followers'] ?? 0;
        followingCount = counts['following'] ?? 0;
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
    try {
      final userId = _authRepo.getCurrentUserId()!;
      final updatedPreferences = favoriteThemeIds
          .where((id) => id != themeId)
          .toList();

      await _prefsRepo.savePreferences(userId, updatedPreferences);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$themeName removed from favorites')),
        );
        loadProfile();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error removing theme : $e')),
        );
      }
    }
  }

  Color _getColorForLevel(int level) {
    if (level >= 10) return AppColors.level10plus;
    if (level >= 7) return AppColors.level7_9;
    if (level >= 5) return AppColors.level5_6;
    if (level >= 3) return AppColors.level3_4;
    return AppColors.level1_2;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (isLoading) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
          child: const Center(
            child: CircularProgressIndicator(color: AppColors.brainPurple),
          ),
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              const BrainAppBar(currentPage: AppPage.profile),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: loadProfile,
                  color: AppColors.brainPurple,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Profile Header Card
                        _buildProfileHeader(l10n),
                        const SizedBox(height: 16),

                        // Social Section
                        _buildSocialSection(l10n),
                        const SizedBox(height: 24),

                        // Statistics Section
                        _buildSectionTitle(l10n.statistics),
                        const SizedBox(height: 12),
                        _buildStatsCards(l10n),
                        const SizedBox(height: 24),

                        // Progress by Theme
                        _buildSectionTitle(l10n.progressByTheme),
                        const SizedBox(height: 12),
                        _buildProgressSection(l10n),
                        const SizedBox(height: 24),

                        // Favorite Themes Management
                        _buildSectionTitle(l10n.manageFavoriteThemes),
                        const SizedBox(height: 12),
                        _buildFavoriteThemesSection(l10n),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppColors.buttonShadow,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha:0.2),
                  shape: BoxShape.circle,
                ),
                child: Image.asset(
                  'assets/branding/mascot/brainly_happy.png',
                  height: 60,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Username with edit button
                    Row(
                      children: [
                        const Icon(Icons.person, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            userStats?.displayName ?? 'Player',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: () => _showChangeUsernameDialog(l10n),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.white.withValues(alpha:0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.edit,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Email
                    Row(
                      children: [
                        const Icon(Icons.email_outlined, color: Colors.white70, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            userStats?.email ?? 'No email',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.white.withValues(alpha:0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.language, color: Colors.white, size: 18),
                          const SizedBox(width: 8),
                          DropdownButton<String>(
                            value: selectedLanguage,
                            dropdownColor: AppColors.brainPurple,
                            underline: const SizedBox(),
                            icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                            items: const [
                              DropdownMenuItem(value: 'en', child: Text('English')),
                              DropdownMenuItem(value: 'fr', child: Text('Francais')),
                            ],
                            onChanged: (value) {
                              if (value != null) updateLanguage(value);
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSocialSection(AppLocalizations l10n) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const FollowListPage()),
        ).then((_) => loadProfile());
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppColors.cardShadow,
        ),
        child: Row(
          children: [
            Expanded(
              child: _buildSocialCounter(
                '$followingCount',
                l10n.following,
                Icons.people,
              ),
            ),
            Container(
              width: 1,
              height: 40,
              color: AppColors.backgroundGray,
            ),
            Expanded(
              child: _buildSocialCounter(
                '$followersCount',
                l10n.followers,
                Icons.person,
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppColors.textLight,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialCounter(String count, String label, IconData icon) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.brainPurple, size: 18),
            const SizedBox(width: 6),
            Text(
              count,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.brainPurple,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  void _showChangeUsernameDialog(AppLocalizations l10n) {
    final controller = TextEditingController(text: userStats?.username ?? '');
    bool isChecking = false;
    bool? isAvailable;
    String? errorMessage;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          Future<void> checkUsername(String username) async {
            if (username.isEmpty || username == userStats?.username) {
              setDialogState(() {
                isAvailable = null;
                errorMessage = null;
              });
              return;
            }

            final normalized = username.toLowerCase().trim();

            if (normalized.length < 3) {
              setDialogState(() {
                isAvailable = false;
                errorMessage = l10n.usernameMinLength;
              });
              return;
            }

            if (normalized.length > 20) {
              setDialogState(() {
                isAvailable = false;
                errorMessage = l10n.usernameMaxLength;
              });
              return;
            }

            final validPattern = RegExp(r'^[a-z0-9_]+$');
            if (!validPattern.hasMatch(normalized)) {
              setDialogState(() {
                isAvailable = false;
                errorMessage = l10n.usernameAllowedChars;
              });
              return;
            }

            setDialogState(() {
              isChecking = true;
              errorMessage = null;
            });

            try {
              final available = await _authRepo.isUsernameAvailable(normalized);
              setDialogState(() {
                isAvailable = available;
                isChecking = false;
                errorMessage = available ? null : l10n.usernameTaken;
              });
            } catch (e) {
              setDialogState(() {
                isChecking = false;
                errorMessage = 'Error checking username';
              });
            }
          }

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                const Icon(Icons.edit, color: AppColors.brainPurple),
                const SizedBox(width: 8),
                Text(l10n.changeUsername),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (userStats?.username != null) ...[
                  Text(
                    '${l10n.currentUsername}: ${userStats!.username}',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                ],
                TextField(
                  controller: controller,
                  onChanged: checkUsername,
                  decoration: InputDecoration(
                    labelText: l10n.newUsername,
                    hintText: 'ex: brain_master42',
                    prefixIcon: const Icon(Icons.person_outline, color: AppColors.brainPurple),
                    suffixIcon: isChecking
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : isAvailable == true
                            ? const Icon(Icons.check_circle, color: AppColors.success)
                            : isAvailable == false
                                ? const Icon(Icons.cancel, color: AppColors.error)
                                : null,
                    filled: true,
                    fillColor: AppColors.brainPurpleLight.withValues(alpha:0.3),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: isAvailable == true
                          ? const BorderSide(color: AppColors.success, width: 2)
                          : isAvailable == false
                              ? const BorderSide(color: AppColors.error, width: 2)
                              : BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isAvailable == false ? AppColors.error : AppColors.brainPurple,
                        width: 2,
                      ),
                    ),
                  ),
                ),
                if (errorMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    errorMessage!,
                    style: const TextStyle(color: AppColors.error, fontSize: 12),
                  ),
                ],
                if (isAvailable == true) ...[
                  const SizedBox(height: 8),
                  Text(
                    l10n.usernameAvailable,
                    style: const TextStyle(color: AppColors.success, fontSize: 12),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.cancel),
              ),
              ElevatedButton(
                onPressed: isAvailable == true
                    ? () async {
                        final newUsername = controller.text.trim();
                        Navigator.pop(context);

                        final success = await _authRepo.updateUsername(newUsername);
                        if (context.mounted) {
                          if (success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(l10n.usernameUpdated),
                                backgroundColor: AppColors.success,
                              ),
                            );
                            loadProfile();
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(l10n.usernameUpdateFailed),
                                backgroundColor: AppColors.error,
                              ),
                            );
                          }
                        }
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brainPurple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(l10n.changeUsername),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildStatsCards(AppLocalizations l10n) {
    return Column(
      children: [
        // Streak Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: AppColors.cardShadow,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.local_fire_department, size: 32, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${userStats?.effectiveStreak ?? 0} ${l10n.days}',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      l10n.currentStreak,
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Icon(Icons.emoji_events, color: Color(0xFFFFD700), size: 24),
                  const SizedBox(height: 4),
                  Text(
                    '${l10n.bestStreak}: ${userStats?.bestStreak ?? 0}',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Stats Row
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.quiz_outlined,
                value: '${userStats?.totalQuestions ?? 0}',
                label: l10n.questions,
                color: AppColors.accentBlue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                icon: Icons.check_circle_outline,
                value: '${userStats?.accuracy.toStringAsFixed(0) ?? 0}%',
                label: l10n.accuracy,
                color: AppColors.success,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha:0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 28, color: color),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection(AppLocalizations l10n) {
    if (progressByTheme.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppColors.cardShadow,
        ),
        child: Column(
          children: [
            Image.asset(
              'assets/branding/mascot/brainly_thinking.png',
              height: 80,
            ),
            const SizedBox(height: 12),
            Text(
              l10n.noProgressYet,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      children: progressByTheme.map((theme) {
        final level = theme['level'] ?? 1;
        final xp = theme['xp'] ?? 0;
        final xpForNextLevel = theme['xp_for_next_level'] ?? 100;
        final xpProgress = xp / xpForNextLevel;
        final total = theme['total_questions'] ?? 0;
        final correct = theme['correct_answers'] ?? 0;
        final themeColor = _getColorForLevel(level);

        // Get translated theme name
        final themeId = theme['theme_id'];
        final translatedTheme = allThemes.where((t) => t.id == themeId).firstOrNull;
        final themeName = translatedTheme?.name ?? theme['theme_name'] ?? 'Unknown';

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: AppColors.cardShadow,
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          themeColor.withValues(alpha:0.2),
                          themeColor.withValues(alpha:0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: themeColor.withValues(alpha:0.3)),
                    ),
                    child: Center(
                      child: Text(
                        theme['icon'] ?? '?',
                        style: const TextStyle(fontSize: 28),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          themeName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$correct / $total ${l10n.correct}',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: themeColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: themeColor.withValues(alpha:0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      '${l10n.level} $level',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(
                    '$xp / $xpForNextLevel ${l10n.xp}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${(xpProgress * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: themeColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Stack(
                children: [
                  Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: themeColor.withValues(alpha:0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: xpProgress.clamp(0.0, 1.0),
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [themeColor, themeColor.withValues(alpha:0.7)],
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFavoriteThemesSection(AppLocalizations l10n) {
    if (favoriteThemes.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppColors.cardShadow,
        ),
        child: Text(
          l10n.noFavoriteThemesProfile,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 16,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Column(
      children: favoriteThemes.map((theme) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppColors.softShadow,
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.brainPurpleLight.withValues(alpha:0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  theme.icon,
                  style: const TextStyle(
                    fontSize: 24,
                    fontFamilyFallback: ['Apple Color Emoji', 'Segoe UI Emoji', 'Noto Color Emoji'],
                  ),
                ),
              ),
            ),
            title: Text(
              theme.name,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            trailing: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.errorLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.remove, color: AppColors.error, size: 20),
              ),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                          backgroundColor: AppColors.error,
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
    );
  }
}
