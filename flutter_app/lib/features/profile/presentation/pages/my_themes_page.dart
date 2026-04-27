import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/data/repositories/auth_repository.dart';
import '../../../quiz/data/repositories/theme_preferences_repository.dart';
import '../../../quiz/data/repositories/quiz_repository.dart';
import '../../../quiz/data/models/theme_model.dart';
import '../../data/repositories/profile_repository.dart';

class MyThemesPage extends StatefulWidget {
  const MyThemesPage({super.key});

  @override
  State<MyThemesPage> createState() => _MyThemesPageState();
}

class _MyThemesPageState extends State<MyThemesPage> {
  final _authRepo = AuthRepository();
  final _profileRepo = ProfileRepository();
  final _prefsRepo = ThemePreferencesRepository();
  final _quizRepo = QuizRepository();

  List<Map<String, dynamic>> _progressByTheme = [];
  List<ThemeModel> _allThemes = [];
  List<String> _favoriteThemeIds = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final userId = _authRepo.getCurrentUserId();
    if (userId == null) return;
    try {
      final lang = context.read<LanguageProvider>().currentLanguage;
      final progress = await _profileRepo.getProgressByTheme(userId);
      final preferredIds = await _prefsRepo.getPreferences(userId);
      final themes = await _quizRepo.getThemes(lang);
      if (!mounted) return;
      setState(() {
        _progressByTheme = progress;
        _allThemes = themes;
        _favoriteThemeIds = preferredIds;
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _removeFromFavorites(String themeId, String themeName) async {
    final l10n = AppLocalizations.of(context)!;
    final userId = _authRepo.getCurrentUserId();
    if (userId == null) return;
    try {
      final updated = _favoriteThemeIds.where((id) => id != themeId).toList();
      await _prefsRepo.savePreferences(userId, updated);
      if (!mounted) return;
      setState(() => _favoriteThemeIds = updated);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.themeRemovedFromFavorites(themeName))),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.themeRemoveError)),
        );
      }
    }
  }

  Color _colorForLevel(int level) {
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
        decoration: BoxDecoration(gradient: AppColors.backgroundGradientOf(context)),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.arrow_back_ios_new_rounded,
                          color: AppColors.textPrimaryOf(context)),
                    ),
                    Expanded(
                      child: Text(
                        l10n.progressByTheme,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimaryOf(context),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: AppColors.brainPurple),
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        color: AppColors.brainPurple,
                        child: _progressByTheme.isEmpty
                            ? ListView(
                                children: [
                                  const SizedBox(height: 80),
                                  Center(
                                    child: Column(
                                      children: [
                                        Image.asset(
                                          'assets/branding/mascot/brainly_thinking.png',
                                          height: 100,
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          l10n.noProgressYet,
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: AppColors.textSecondaryOf(context),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                                itemCount: _progressByTheme.length,
                                itemBuilder: (context, index) =>
                                    _buildThemeCard(_progressByTheme[index], l10n),
                              ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThemeCard(Map<String, dynamic> theme, AppLocalizations l10n) {
    final level = theme['level'] ?? 1;
    final xp = theme['xp'] ?? 0;
    final xpForNextLevel = theme['xp_for_next_level'] ?? 100;
    final xpProgress = xpForNextLevel > 0 ? (xp / xpForNextLevel).clamp(0.0, 1.0) : 0.0;
    final total = theme['total_questions'] ?? 0;
    final correct = theme['correct_answers'] ?? 0;
    final themeId = theme['theme_id'];
    final themeColor = _colorForLevel(level);
    final isFavorite = _favoriteThemeIds.contains(themeId);

    final translatedTheme = _allThemes.where((t) => t.id == themeId).firstOrNull;
    final themeName = translatedTheme?.name ?? theme['theme_name'] ?? 'Unknown';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardColorOf(context),
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
                      themeColor.withValues(alpha: 0.2),
                      themeColor.withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: themeColor.withValues(alpha: 0.3)),
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
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimaryOf(context),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$correct / $total ${l10n.correct}',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondaryOf(context),
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
                      color: themeColor.withValues(alpha: 0.4),
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
                  color: AppColors.textSecondaryOf(context),
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
                  color: themeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              FractionallySizedBox(
                widthFactor: xpProgress,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [themeColor, themeColor.withValues(alpha: 0.7)],
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
          if (isFavorite) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _confirmRemove(themeId, themeName, l10n),
                icon: const Icon(Icons.star_border_rounded, size: 16),
                label: Text(l10n.removeFromFavorites),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: AppColors.error,
                  side: BorderSide.none,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  textStyle: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _confirmRemove(String themeId, String themeName, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(l10n.removeFromFavorites),
        content: Text(l10n.removeFavoriteConfirm(themeName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _removeFromFavorites(themeId, themeName);
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
  }
}
