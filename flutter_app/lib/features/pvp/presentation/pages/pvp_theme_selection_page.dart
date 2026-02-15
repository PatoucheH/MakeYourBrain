import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/data/repositories/auth_repository.dart';
import '../../../quiz/data/models/theme_model.dart';
import '../../../quiz/data/repositories/quiz_repository.dart';
import '../../../quiz/data/repositories/theme_preferences_repository.dart';
import '../../data/providers/pvp_provider.dart';

class PvPThemeSelectionPage extends StatefulWidget {
  final int roundNumber;

  const PvPThemeSelectionPage({super.key, required this.roundNumber});

  @override
  State<PvPThemeSelectionPage> createState() => _PvPThemeSelectionPageState();
}

class _PvPThemeSelectionPageState extends State<PvPThemeSelectionPage> {
  final _quizRepo = QuizRepository();
  final _prefsRepo = ThemePreferencesRepository();
  final _authRepo = AuthRepository();

  List<ThemeModel> allThemes = [];
  List<String> favoriteThemeIds = [];
  List<String> usedThemeIds = [];
  bool isLoading = true;
  bool isSelecting = false;

  @override
  void initState() {
    super.initState();
    _loadThemes();
  }

  Future<void> _loadThemes() async {
    try {
      final userId = _authRepo.getCurrentUserId();
      if (userId == null) return;

      final pvpProvider = context.read<PvPProvider>();

      final userStats = await _authRepo.getUserStats();
      final language = userStats?.preferredLanguage ?? 'en';

      final results = await Future.wait([
        _quizRepo.getThemes(language),
        _prefsRepo.getPreferences(userId),
        pvpProvider.getUsedThemeIds(),
      ]);

      setState(() {
        allThemes = results[0] as List<ThemeModel>;
        favoriteThemeIds = results[1] as List<String>;
        usedThemeIds = results[2] as List<String>;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading themes: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> _selectTheme(ThemeModel theme) async {
    if (isSelecting) return;

    setState(() => isSelecting = true);

    try {
      final pvpProvider = context.read<PvPProvider>();
      await pvpProvider.selectTheme(theme.id);
      // Pas de Navigator.pop() ici : la page est rendue à l'intérieur de PvPGamePage
      // Le provider notifie, PvPGamePage se rebuild et affiche le quiz automatiquement
    } catch (e) {
      debugPrint('Error selecting theme: $e');
      if (mounted) {
        setState(() => isSelecting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Color _parseColor(String colorHex) {
    try {
      return Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return AppColors.brainPurple;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(l10n),
              Expanded(
                child: isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                            color: AppColors.brainPurple),
                      )
                    : isSelecting
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const CircularProgressIndicator(
                                    color: AppColors.brainPurple),
                                const SizedBox(height: 16),
                                Text(
                                  l10n.chooseTheme,
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : _buildThemeList(l10n),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: AppColors.softShadow,
                ),
                child: Text(
                  'Round ${widget.roundNumber}/3',
                  style: const TextStyle(
                    color: AppColors.brainPurple,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: AppColors.cardShadow,
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.brainPurple.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.category,
                    color: AppColors.brainPurple,
                    size: 36,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.selectThemeForRound(widget.roundNumber),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.chooseTheme,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeList(AppLocalizations l10n) {
    final favoriteThemes =
        allThemes.where((t) => favoriteThemeIds.contains(t.id)).toList();
    final otherThemes =
        allThemes.where((t) => !favoriteThemeIds.contains(t.id)).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (favoriteThemes.isNotEmpty) ...[
            _buildSectionTitle(l10n.yourFavoriteThemes, Icons.star,
                const Color(0xFFFFD700)),
            const SizedBox(height: 12),
            ...favoriteThemes.map((theme) =>
                _buildThemeCard(theme, true, usedThemeIds.contains(theme.id))),
            const SizedBox(height: 24),
          ],
          _buildSectionTitle(
              l10n.allThemesAvailable, Icons.grid_view, AppColors.brainPurple),
          const SizedBox(height: 12),
          ...otherThemes.map((theme) =>
              _buildThemeCard(theme, false, usedThemeIds.contains(theme.id))),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildThemeCard(ThemeModel theme, bool isFavorite, bool isUsed) {
    final themeColor = _parseColor(theme.color);

    return GestureDetector(
      onTap: isUsed ? null : () => _selectTheme(theme),
      child: Opacity(
        opacity: isUsed ? 0.4 : 1.0,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: isUsed ? null : AppColors.softShadow,
            border: Border.all(
              color: isUsed
                  ? AppColors.textLight.withValues(alpha: 0.3)
                  : isFavorite
                      ? const Color(0xFFFFD700).withValues(alpha: 0.4)
                      : themeColor.withValues(alpha: 0.2),
              width: isFavorite && !isUsed ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: themeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    theme.icon,
                    style: const TextStyle(fontSize: 28),
                  ),
                ),
              ),
              const SizedBox(width: 16),
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
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (isUsed)
                          const Icon(Icons.check_circle,
                              color: AppColors.textLight, size: 20)
                        else if (isFavorite)
                          const Icon(Icons.star,
                              color: Color(0xFFFFD700), size: 20),
                      ],
                    ),
                    if (theme.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        theme.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (!isUsed)
                Icon(
                  Icons.arrow_forward_ios,
                  color: themeColor.withValues(alpha: 0.5),
                  size: 16,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
