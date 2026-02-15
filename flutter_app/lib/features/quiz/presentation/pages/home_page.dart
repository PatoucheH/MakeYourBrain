import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/brain_app_bar.dart';
import '../../data/repositories/quiz_repository.dart';
import '../../data/repositories/theme_preferences_repository.dart';
import '../../data/models/theme_model.dart';
import '../../../auth/data/repositories/auth_repository.dart';
import '../../../profile/data/repositories/profile_repository.dart';
import 'theme_detail_page.dart';
import 'all_themes_page.dart';
import 'add_theme_page.dart';
import '../../../pvp/presentation/pages/pvp_menu_page.dart';

/// Mettre à false pour désactiver la modal Beta
const bool kShowBetaDialog = true;

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
    if (kShowBetaDialog) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showBetaDialog());
    }
  }

  void _showBetaDialog() {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Image.asset(
              'assets/branding/mascot/brainly_encourage.png',
              height: 40,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                l10n.betaTitle,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.betaMessage,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () {
                Clipboard.setData(const ClipboardData(text: 'hugo.patou@hotmail.com'));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Email copied!')),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.brainPurple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.brainPurple.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.email, color: AppColors.brainPurple, size: 18),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        l10n.betaEmail,
                        style: const TextStyle(
                          color: AppColors.brainPurple,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.copy, color: AppColors.brainPurple, size: 16),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.thanks,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.brainPurple,
                fontSize: 15,
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brainPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(l10n.understood, style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
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
        currentStreak = stats?.effectiveStreak ?? 0;
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
              const BrainAppBar(),

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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppColors.buttonShadow,
      ),
      child: Column(
        children: [
          Text(
            l10n.welcome,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Image.asset(
            'assets/branding/mascot/brainly_happy.png',
            height: 80,
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
                color: AppColors.brainPurple.withValues(alpha:0.1),
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
                color: const Color(0xFFFF6B35).withValues(alpha:0.4),
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
                  color: Colors.white.withValues(alpha:0.2),
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
                  color: Colors.white.withValues(alpha:0.2),
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
            border: Border.all(color: color.withValues(alpha:0.3), width: 2),
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
                        themeColor.withValues(alpha:0.2),
                        themeColor.withValues(alpha:0.1),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: themeColor.withValues(alpha:0.3),
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
                              color: themeColor.withValues(alpha:0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          FractionallySizedBox(
                            widthFactor: progressPercent.clamp(0.0, 1.0),
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
