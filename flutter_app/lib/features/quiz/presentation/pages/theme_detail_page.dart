import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/theme_model.dart';
import '../../../auth/data/repositories/auth_repository.dart';
import '../../../profile/data/repositories/profile_repository.dart';
import 'quiz_page.dart';
import 'timed_quiz_page.dart';
import '../../../leaderboard/presentation/pages/leaderboard_page.dart';
import '../../../lives/data/providers/lives_provider.dart';
import '../../../lives/presentation/widgets/no_lives_dialog.dart';
import '../../../lives/presentation/widgets/lives_indicator.dart';

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
    if (level >= 10) return AppColors.level10plus;
    if (level >= 7) return AppColors.level7_9;
    if (level >= 5) return AppColors.level5_6;
    if (level >= 3) return AppColors.level3_4;
    return AppColors.level1_2;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final themeColor = _getColorForLevel(level);
    final progressPercent = xp / xpForNextLevel;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              // Custom AppBar
              _buildAppBar(l10n),

              // Content
              Expanded(
                child: isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: AppColors.brainPurple),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            // Theme Hero Card
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [themeColor, themeColor.withOpacity(0.7)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: themeColor.withOpacity(0.4),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  // Theme Icon
                                  Container(
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        widget.theme.icon,
                                        style: const TextStyle(fontSize: 56),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  // Level Badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      '${l10n.level} $level',
                                      style: TextStyle(
                                        color: themeColor,
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
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                            ),
                                          ),
                                          Text(
                                            '${(progressPercent * 100).toStringAsFixed(0)}%',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white.withOpacity(0.9),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Stack(
                                        children: [
                                          Container(
                                            height: 12,
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(0.3),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                          ),
                                          FractionallySizedBox(
                                            widthFactor: progressPercent.clamp(0.0, 1.0),
                                            child: Container(
                                              height: 12,
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Start Quiz Button
                            Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                gradient: AppColors.primaryGradient,
                                boxShadow: AppColors.buttonShadow,
                              ),
                              child: ElevatedButton(
                                onPressed: () async {
                                  final livesProvider = context.read<LivesProvider>();

                                  if (livesProvider.currentLives <= 0) {
                                    showDialog(
                                      context: context,
                                      builder: (context) => const NoLivesDialog(),
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
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  padding: const EdgeInsets.all(20),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.play_arrow_rounded, size: 32, color: Colors.white),
                                    const SizedBox(width: 12),
                                    Text(
                                      l10n.startQuiz,
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Timed Quiz Button
                            Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFFF9800), Color(0xFFFF5722)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFFF9800).withOpacity(0.4),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: () => _showTimerSelectionDialog(context, l10n),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  padding: const EdgeInsets.all(20),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.timer, size: 28, color: Colors.white),
                                    const SizedBox(width: 12),
                                    Text(
                                      l10n.timedQuiz,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Leaderboard Button
                            Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: AppColors.cardShadow,
                                border: Border.all(
                                  color: const Color(0xFFFFD700).withOpacity(0.3),
                                  width: 2,
                                ),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
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
                                  mouseCursor: SystemMouseCursors.click,
                                  borderRadius: BorderRadius.circular(20),
                                  child: Padding(
                                    padding: const EdgeInsets.all(18),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                                            ),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: const Icon(Icons.leaderboard, color: Colors.white, size: 24),
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          l10n.viewLeaderboard,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // About Section
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: AppColors.cardShadow,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: AppColors.brainPurpleLight.withOpacity(0.3),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: const Icon(
                                          Icons.info_outline,
                                          color: AppColors.brainPurple,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        l10n.aboutThisTheme,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    widget.theme.description,
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: AppColors.textSecondary,
                                      height: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 32),
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

  void _showTimerSelectionDialog(BuildContext context, AppLocalizations l10n) {
    final livesProvider = context.read<LivesProvider>();

    if (livesProvider.currentLives <= 0) {
      showDialog(
        context: context,
        builder: (context) => const NoLivesDialog(),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
              // Timer Icon
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF9800), Color(0xFFFF5722)],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.timer,
                  color: Colors.white,
                  size: 40,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                l10n.timedQuiz,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.brainPurple,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.chooseYourTime,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warningLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: AppColors.warning, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.timedQuizDescription,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.warning,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Time options
              _buildTimeOption(
                context: dialogContext,
                seconds: 30,
                label: l10n.seconds30,
                bonus: '+20 XP',
                color: AppColors.error,
                livesProvider: livesProvider,
              ),
              const SizedBox(height: 12),
              _buildTimeOption(
                context: dialogContext,
                seconds: 45,
                label: l10n.seconds45,
                bonus: '+10 XP',
                color: AppColors.warning,
                livesProvider: livesProvider,
              ),
              const SizedBox(height: 12),
              _buildTimeOption(
                context: dialogContext,
                seconds: 60,
                label: l10n.seconds60,
                bonus: '+5 XP',
                color: AppColors.success,
                livesProvider: livesProvider,
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(
                  l10n.cancel,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeOption({
    required BuildContext context,
    required int seconds,
    required String label,
    required String bonus,
    required Color color,
    required LivesProvider livesProvider,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () async {
          await livesProvider.useLife();
          if (!mounted) return;
          Navigator.pop(context);
          Navigator.push(
            this.context,
            MaterialPageRoute(
              builder: (context) => TimedQuizPage(
                theme: widget.theme,
                totalSeconds: seconds,
              ),
            ),
          );
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.3), width: 2),
          ),
          child: Row(
            children: [
              Icon(Icons.timer, color: color, size: 28),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  bonus,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: AppColors.softShadow,
                ),
                child: const Icon(
                  Icons.arrow_back,
                  color: AppColors.brainPurple,
                  size: 22,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.theme.name,
              style: const TextStyle(
                color: AppColors.brainPurple,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: AppColors.softShadow,
            ),
            child: const LivesIndicator(),
          ),
        ],
      ),
    );
  }
}
