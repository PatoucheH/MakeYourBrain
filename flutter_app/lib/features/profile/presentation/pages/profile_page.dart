import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/brain_app_bar.dart';
import '../../../auth/data/repositories/auth_repository.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../../../pvp/data/providers/pvp_provider.dart';
import '../../../social/presentation/pages/follow_list_page.dart';
import '../../../social/providers/follow_provider.dart';
import '../../../auth/providers/user_stats_provider.dart';
import '../../../achievements/presentation/pages/achievements_page.dart';
import 'my_themes_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _authRepo = AuthRepository();

  UserModel? userStats;
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
      final stats = await _authRepo.getUserStats();
      if (!mounted) return;
      setState(() {
        userStats = stats;
        selectedLanguage = currentLang;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.errorLoadingProfile)),
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
          SnackBar(content: Text(l10n.errorLoadingProfile)),
        );
      }
    }
  }

  Future<void> _deleteAccount(AppLocalizations l10n) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppColors.error),
            const SizedBox(width: 8),
            Text(l10n.deleteAccount),
          ],
        ),
        content: Text(l10n.deleteAccountConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(l10n.deleteAccount),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!mounted) return;

    context.read<PvPProvider>().stopBackgroundChecks();
    context.read<PvPProvider>().reset();

    final success = await _authRepo.deleteAccount();
    if (!mounted) return;

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.deleteAccountError)),
      );
      return;
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (isLoading) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(gradient: AppColors.backgroundGradientOf(context)),
          child: const Center(
            child: CircularProgressIndicator(color: AppColors.brainPurple),
          ),
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.backgroundGradientOf(context)),
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

                        // Achievements
                        _buildSectionTitle(l10n.achievements),
                        const SizedBox(height: 12),
                        _buildAchievementsButton(l10n),
                        const SizedBox(height: 24),

                        // My Themes
                        _buildSectionTitle(l10n.progressByTheme),
                        const SizedBox(height: 12),
                        _buildMyThemesButton(l10n),
                        const SizedBox(height: 32),

                        // Appearance
                        _buildSectionTitle(l10n.appearance),
                        const SizedBox(height: 12),
                        _buildAppearanceSection(l10n),
                        const SizedBox(height: 24),

                        // Danger zone
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => _deleteAccount(l10n),
                            icon: const Icon(Icons.delete_forever,
                                color: Colors.white, size: 22),
                            label: Text(l10n.deleteAccount,
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.error,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                              elevation: 2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
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
                            style: TextStyle(
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
                            userStats?.email ?? l10n.noEmail,
                            style: TextStyle(
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
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                            items: [
                              DropdownMenuItem(value: 'en', child: Text(context.read<LanguageProvider>().getLanguageName('en'))),
                              DropdownMenuItem(value: 'fr', child: Text(context.read<LanguageProvider>().getLanguageName('fr'))),
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
    final followProvider = context.watch<FollowProvider>();
    final followingCount = followProvider.followingCount;
    final followersCount = followProvider.followersCount;
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
          color: AppColors.cardColorOf(context),
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
              style: TextStyle(
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
            color: AppColors.textSecondaryOf(context),
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
                errorMessage = l10n.usernameCheckFailed;
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
                    style: TextStyle(color: AppColors.textSecondaryOf(context), fontSize: 14),
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
                    style: TextStyle(color: AppColors.error, fontSize: 12),
                  ),
                ],
                if (isAvailable == true) ...[
                  const SizedBox(height: 8),
                  Text(
                    l10n.usernameAvailable,
                    style: TextStyle(color: AppColors.success, fontSize: 12),
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
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimaryOf(context),
      ),
    );
  }

  Widget _buildNavButton({
    required String label,
    required IconData icon,
    required List<Color> gradientColors,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.cardColorOf(context),
          borderRadius: BorderRadius.circular(18),
          boxShadow: AppColors.cardShadow,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: gradientColors),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimaryOf(context),
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: AppColors.textSecondaryOf(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementsButton(AppLocalizations l10n) {
    return _buildNavButton(
      label: l10n.achievements,
      icon: Icons.emoji_events_rounded,
      gradientColors: const [Color(0xFFFFD700), Color(0xFFFFA000)],
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AchievementsPage()),
      ),
    );
  }

  Widget _buildMyThemesButton(AppLocalizations l10n) {
    return _buildNavButton(
      label: l10n.progressByTheme,
      icon: Icons.bar_chart_rounded,
      gradientColors: [AppColors.brainPurple, AppColors.brainPurpleDark],
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const MyThemesPage()),
      ),
    );
  }

  Widget _buildAppearanceSection(AppLocalizations l10n) {
    final themeProvider = context.watch<ThemeProvider>();
    // Use actual rendered brightness — handles ThemeMode.system correctly
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardColorOf(context),
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.brainPurple.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
              color: AppColors.brainPurple,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.appearance,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimaryOf(context),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isDark ? l10n.darkMode : l10n.lightMode,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondaryOf(context),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: isDark,
            onChanged: (val) => themeProvider.setThemeMode(
              val ? ThemeMode.dark : ThemeMode.light,
            ),
            activeThumbColor: AppColors.brainPurple,
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards(AppLocalizations l10n) {
    final userStatsProvider = context.watch<UserStatsProvider>();
    return Column(
      children: [
        // Streak Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.cardColorOf(context),
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
                      '${userStatsProvider.effectiveStreak} ${l10n.days}',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimaryOf(context),
                      ),
                    ),
                    Text(
                      l10n.currentStreak,
                      style: TextStyle(color: AppColors.textSecondaryOf(context)),
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
                    '${l10n.bestStreak}: ${userStatsProvider.bestStreak}',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondaryOf(context),
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
        color: AppColors.cardColorOf(context),
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
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimaryOf(context),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondaryOf(context),
            ),
          ),
        ],
      ),
    );
  }

}

