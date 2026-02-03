import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/brain_app_bar.dart';
import '../../data/repositories/quiz_repository.dart';
import '../../data/repositories/theme_preferences_repository.dart';
import '../../data/models/theme_model.dart';
import '../../../auth/data/repositories/auth_repository.dart';
import '../../../../l10n/app_localizations.dart';

class AddThemePage extends StatefulWidget {
  final List<String> currentPreferences;

  const AddThemePage({super.key, required this.currentPreferences});

  @override
  State<AddThemePage> createState() => _AddThemePageState();
}

class _AddThemePageState extends State<AddThemePage> {
  static const int maxFavoriteThemes = 3;

  final _quizRepo = QuizRepository();
  final _prefsRepo = ThemePreferencesRepository();
  final _authRepo = AuthRepository();

  List<ThemeModel> availableThemes = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadAvailableThemes();
  }

  Future<void> loadAvailableThemes() async {
    try {
      final languageCode = context.read<LanguageProvider>().currentLanguage;
      final allThemes = await _quizRepo.getThemes(languageCode);
      
      final available = allThemes
          .where((theme) => !widget.currentPreferences.contains(theme.id))
          .toList();
      
      setState(() {
        availableThemes = available;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading themes: $e')),
        );
      }
    }
  }

  Future<void> addThemeToPreferences(ThemeModel theme) async {
    try {
      final userId = _authRepo.getCurrentUserId()!;
      final updatedPreferences = [...widget.currentPreferences, theme.id];
      
      await _prefsRepo.savePreferences(userId, updatedPreferences);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${theme.name} added to favorites! ⭐')),
        );
        
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding theme: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hasReachedLimit = widget.currentPreferences.length >= maxFavoriteThemes;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              const BrainAppBar(),
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.brainPurple))
          : hasReachedLimit
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.warningLight,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.block,
                            size: 60,
                            color: AppColors.warning,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          l10n.maxThemesReached,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          l10n.maxThemesMessage,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back),
                          label: Text(l10n.backToThemes),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.brainPurple,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : availableThemes.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              size: 80,
                              color: Colors.green.shade300,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              l10n.allThemesInFavorites,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: availableThemes.length,
                  itemBuilder: (context, index) {
                    final theme = availableThemes[index];

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: InkWell(
                        onTap: () => addThemeToPreferences(theme),
                        mouseCursor: SystemMouseCursors.click,
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: AppColors.brainLightPurple.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Text(
                                    theme.icon,
                                    style: const TextStyle(
                                      fontSize: 32,
                                      fontFamilyFallback: ['Apple Color Emoji', 'Segoe UI Emoji', 'Noto Color Emoji'],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      theme.name,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      theme.description,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade600,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.add,
                                  color: Colors.green.shade700,
                                  size: 24,
                                ),
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
        ),
      ),
    );
  }
}