import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../../core/theme/app_colors.dart';
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
import '../../../lives/presentation/widgets/lives_indicator.dart';
import '../../../pvp/presentation/pages/pvp_menu_page.dart';

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
  int currentStreak = 0;
  int pvpRating = 1000;

  @override
  void initState() {
    super.initState();
    loadFavoriteThemes();
  }

  Future<void> loadFavoriteThemes() async {
    try {
      final userId = _authRepo.getCurrentUserId()!;
      final languageCode = context.read<LanguageProvider>().currentLanguage;

      final preferredIds = await _prefsRepo.getPreferences(userId);
      final allThemes = await _quizRepo.getThemes(languageCode);

      final preferred = allThemes
          .where((theme) => preferredIds.contains(theme.id))
          .toList();

      final progress = await _profileRepo.getProgressByTheme(userId);
      final progressMap = <String, Map<String, dynamic>>{};
      for (var p in progress) {
        progressMap[p['theme_id']] = p;
      }

      final stats = await _authRepo.getUserStats();

      setState(() {
        favoriteThemes = preferred;
        favoriteThemeIds = preferredIds;
        themeProgress = progressMap;
        currentStreak = stats?.currentStreak ?? 0;
        pvpRating = stats?.pvpRating ?? 1000;
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

    if (result == true) {
      loadFavoriteThemes();
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

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom AppBar
              _buildAppBar(l10n),

              // Content
              Expanded(
                child: isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.brainPurple,
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: loadFavoriteThemes,
                        color: AppColors.brainPurple,
                        child: CustomScrollView(
                          slivers: [
                            // Header Section
                            SliverToBoxAdapter(
                              child: _buildHeaderSection(l10n),
                            ),

                            // Themes Grid/List
                            favoriteThemes.isEmpty
                                ? SliverFillRemaining(
                                    hasScrollBody: false,
                                    child: _buildEmptyState(l10n),
                                  )
                                : SliverPadding(
                                    padding: const EdgeInsets.all(16),
                                    sliver: SliverList(
                                      delegate: SliverChildBuilderDelegate(
                                        (context, index) {
                                          final theme = favoriteThemes[index];
                                          return _buildThemeCard(theme, l10n);
                                        },
                                        childCount: favoriteThemes.length,
                                      ),
                                    ),
                                  ),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          // Logo + Title
          Expanded(
            child: Row(
              children: [
                Image.asset(
                  'assets/branding/logo/brainly_logo.png',
                  height: 28,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    l10n.appName,
                    style: const TextStyle(
                      color: AppColors.brainPurple,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // Streak
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppColors.softShadow,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.local_fire_department,
                  color: Color(0xFFFF6B6B),
                  size: 18,
                ),
                const SizedBox(width: 2),
                Text(
                  '$currentStreak',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),

          // Lives Indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppColors.softShadow,
            ),
            child: const LivesIndicator(),
          ),
          const SizedBox(width: 6),

          // Menu Button with all actions
          Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: AppColors.softShadow,
            ),
            child: PopupMenuButton<String>(
              icon: const Icon(
                Icons.menu,
                color: AppColors.brainPurple,
                size: 20,
              ),
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onSelected: (value) async {
                if (value == 'profile') {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ProfilePage()),
                  );
                  loadFavoriteThemes();
                } else if (value == 'leaderboard') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LeaderboardPage()),
                  );
                } else if (value == 'logout') {
                  await _authRepo.signOut();
                  if (context.mounted) {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (context) => const LoginPage()),
                    );
                  }
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'profile',
                  child: Row(
                    children: [
                      const Icon(Icons.person_outline, color: AppColors.brainPurple),
                      const SizedBox(width: 12),
                      Text(l10n.profile),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'leaderboard',
                  child: Row(
                    children: [
                      const Icon(Icons.leaderboard_outlined, color: AppColors.brainPurple),
                      const SizedBox(width: 12),
                      Text(l10n.viewLeaderboard),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: [
                      const Icon(Icons.logout, color: AppColors.error),
                      const SizedBox(width: 12),
                      Text(l10n.logout, style: const TextStyle(color: AppColors.error)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton(IconData icon, VoidCallback onTap, {Color? color}) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: AppColors.softShadow,
          ),
          child: Icon(
            icon,
            color: color ?? AppColors.brainPurple,
            size: 22,
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Mascot Welcome Card
          _buildMascotCard(l10n),
          const SizedBox(height: 16),

          // PvP Arena Button
          _buildPvPButton(l10n),
          const SizedBox(height: 16),

          // Themes Section Header
          _buildThemesHeader(l10n),
        ],
      ),
    );
  }

  Widget _buildMascotCard(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppColors.buttonShadow,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.welcome,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.moreFeaturesComingSoon.split('\n').first,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Image.asset(
            'assets/branding/mascot/brainly_happy.png',
            height: 70,
          ),
        ],
      ),
    );
  }

  Widget _buildThemesHeader(AppLocalizations l10n) {
    return Column(
      children: [
        // Title row
        Row(
          children: [
            const Icon(Icons.star, color: AppColors.brainPurple, size: 22),
            const SizedBox(width: 8),
            Text(
              l10n.myFavoriteThemes,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.brainPurple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${favoriteThemes.length}/3',
                style: const TextStyle(
                  color: AppColors.brainPurple,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Action Buttons
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                icon: favoriteThemes.length >= 3 ? Icons.block : Icons.add_circle_outline,
                label: l10n.addTheme,
                color: favoriteThemes.length >= 3 ? AppColors.textLight : AppColors.success,
                onTap: favoriteThemes.length >= 3
                    ? () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(l10n.maxThemesMessage),
                            backgroundColor: AppColors.warning,
                          ),
                        );
                      }
                    : navigateToAddTheme,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                icon: Icons.grid_view_rounded,
                label: l10n.allThemes,
                color: AppColors.accentBlue,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AllThemesPage(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPvPButton(AppLocalizations l10n) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const PvPMenuPage(),
            ),
          );
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFF6B35), Color(0xFFE91E63)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF6B35).withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.sports_kabaddi,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                l10n.pvpArena,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.emoji_events, color: Color(0xFFFFD700), size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '$pvpRating',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppColors.cardShadow,
            border: Border.all(color: color.withOpacity(0.3), width: 2),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.white,
                shape: BoxShape.circle,
                boxShadow: AppColors.cardShadow,
              ),
              child: Image.asset(
                'assets/branding/mascot/brainly_thinking.png',
                height: 100,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.noFavoriteThemes,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              l10n.tapAddTheme,
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: AppColors.primaryGradient,
                boxShadow: AppColors.buttonShadow,
              ),
              child: ElevatedButton.icon(
                onPressed: navigateToAddTheme,
                icon: const Icon(Icons.add, color: Colors.white),
                label: Text(
                  l10n.addTheme,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeCard(ThemeModel theme, AppLocalizations l10n) {
    final progress = themeProgress[theme.id];
    final level = progress?['level'] ?? 1;
    final xp = progress?['xp'] ?? 0;
    final xpForNextLevel = progress?['xp_for_next_level'] ?? 100;
    final themeColor = _getColorForLevel(level);
    final progressPercent = xp / xpForNextLevel;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ThemeDetailPage(theme: theme),
              ),
            );
          },
          mouseCursor: SystemMouseCursors.click,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Theme Icon
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        themeColor.withOpacity(0.2),
                        themeColor.withOpacity(0.1),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: themeColor.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      theme.icon,
                      style: const TextStyle(
                        fontSize: 36,
                        fontFamilyFallback: ['Apple Color Emoji', 'Segoe UI Emoji', 'Noto Color Emoji'],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Theme Info
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
                                color: AppColors.textPrimary,
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
                              boxShadow: [
                                BoxShadow(
                                  color: themeColor.withOpacity(0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
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
                      const SizedBox(height: 12),

                      // Progress Bar
                      Stack(
                        children: [
                          Container(
                            height: 8,
                            decoration: BoxDecoration(
                              color: themeColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          FractionallySizedBox(
                            widthFactor: progressPercent.clamp(0.0, 1.0),
                            child: Container(
                              height: 8,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [themeColor, themeColor.withOpacity(0.7)],
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // XP Info
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '$xp / $xpForNextLevel ${l10n.xp}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            '${(progressPercent * 100).toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: themeColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: AppColors.textLight,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
