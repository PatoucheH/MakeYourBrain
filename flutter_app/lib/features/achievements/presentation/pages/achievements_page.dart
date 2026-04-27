import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../auth/data/repositories/auth_repository.dart';
import '../../data/models/achievement_model.dart';
import '../../data/repositories/achievement_repository.dart';

class AchievementsPage extends StatefulWidget {
  const AchievementsPage({super.key});

  @override
  State<AchievementsPage> createState() => _AchievementsPageState();
}

class _AchievementsPageState extends State<AchievementsPage> {
  final _repo = AchievementRepository();
  final _authRepo = AuthRepository();
  List<AchievementModel> _achievements = [];
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
      final data = await _repo.getAllWithUserStatus(userId);
      if (!mounted) return;
      setState(() {
        _achievements = data;
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Map<String, List<AchievementModel>> _grouped() {
    final map = <String, List<AchievementModel>>{};
    for (final a in _achievements) {
      map.putIfAbsent(a.category, () => []).add(a);
    }
    return map;
  }

  String _categoryLabel(String category, String lang) {
    const labels = {
      'quiz': {'en': 'Quiz', 'fr': 'Quiz'},
      'streak': {'en': 'Streak', 'fr': 'Streak'},
      'accuracy': {'en': 'Accuracy', 'fr': 'Précision'},
      'pvp': {'en': 'PvP Arena', 'fr': 'Arène PvP'},
    };
    return labels[category]?[lang] ?? category;
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'quiz':
        return Icons.quiz_rounded;
      case 'streak':
        return Icons.local_fire_department_rounded;
      case 'accuracy':
        return Icons.gps_fixed_rounded;
      case 'pvp':
        return Icons.sports_esports_rounded;
      default:
        return Icons.star_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final lang = context.watch<LanguageProvider>().currentLanguage;
    final grouped = _grouped();
    final categoryOrder = ['quiz', 'streak', 'accuracy', 'pvp'];

    final unlockedCount = _achievements.where((a) => a.isUnlocked).length;

    return Scaffold(
      body: Container(
        decoration:
            BoxDecoration(gradient: AppColors.backgroundGradientOf(context)),
        child: SafeArea(
          child: Column(
            children: [
              // App bar
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.arrow_back_ios_new_rounded,
                          color: AppColors.textPrimaryOf(context)),
                    ),
                    Expanded(
                      child: Text(
                        l10n.achievements,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimaryOf(context),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    // Counter
                    if (!_isLoading)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$unlockedCount / ${_achievements.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      )
                    else
                      const SizedBox(width: 48),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                            color: AppColors.brainPurple),
                      )
                    : _achievements.isEmpty
                        ? Center(
                            child: Text(
                              l10n.noAchievementsYet,
                              style: TextStyle(
                                color: AppColors.textSecondaryOf(context),
                                fontSize: 16,
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                            itemCount: categoryOrder
                                .where((c) => grouped.containsKey(c))
                                .length,
                            itemBuilder: (context, idx) {
                              final category = categoryOrder
                                  .where((c) => grouped.containsKey(c))
                                  .elementAt(idx);
                              final items = grouped[category]!;
                              return _buildCategory(
                                  category, items, lang, l10n);
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategory(
    String category,
    List<AchievementModel> items,
    String lang,
    AppLocalizations l10n,
  ) {
    final unlocked = items.where((a) => a.isUnlocked).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Row(
          children: [
            Icon(_categoryIcon(category),
                color: AppColors.brainPurple, size: 20),
            const SizedBox(width: 8),
            Text(
              _categoryLabel(category, lang),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimaryOf(context),
              ),
            ),
            const Spacer(),
            Text(
              '$unlocked / ${items.length}',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondaryOf(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: AppColors.cardColorOf(context),
            borderRadius: BorderRadius.circular(18),
            boxShadow: AppColors.cardShadow,
          ),
          child: Column(
            children: items.asMap().entries.map((entry) {
              final isLast = entry.key == items.length - 1;
              return _buildAchievementRow(entry.value, lang, isLast);
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildAchievementRow(
    AchievementModel achievement,
    String lang,
    bool isLast,
  ) {
    final unlocked = achievement.isUnlocked;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              // Icon with glow when unlocked
              Stack(
                alignment: Alignment.center,
                children: [
                  if (unlocked)
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(0xFFFFD700).withValues(alpha: 0.3),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                        ],
                        gradient: const RadialGradient(
                          colors: [
                            Color(0x33FFD700),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  Opacity(
                    opacity: unlocked ? 1.0 : 0.35,
                    child: Text(
                      achievement.icon,
                      style: const TextStyle(fontSize: 36),
                    ),
                  ),
                  if (!unlocked)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: AppColors.cardColorOf(context),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.lock_rounded,
                          size: 13,
                          color: AppColors.textSecondaryOf(context),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 14),
              // Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      achievement.nameFor(lang),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: unlocked
                            ? AppColors.textPrimaryOf(context)
                            : AppColors.textSecondaryOf(context),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      achievement.descriptionFor(lang),
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondaryOf(context),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              if (unlocked)
                Icon(Icons.check_circle_rounded,
                    color: AppColors.success, size: 22),
            ],
          ),
        ),
        if (!isLast)
          Divider(
            height: 1,
            indent: 16,
            endIndent: 16,
            color: AppColors.brainPurple.withValues(alpha: 0.08),
          ),
      ],
    );
  }
}
