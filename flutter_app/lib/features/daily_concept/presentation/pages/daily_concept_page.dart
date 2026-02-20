import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/providers/language_provider.dart';
import '../../data/models/daily_concept_model.dart';
import 'daily_quiz_page.dart';

class DailyConceptPage extends StatefulWidget {
  final DailyConceptModel concept;

  const DailyConceptPage({super.key, required this.concept});

  @override
  State<DailyConceptPage> createState() => _DailyConceptPageState();
}

class _DailyConceptPageState extends State<DailyConceptPage> {
  @override
  void initState() {
    super.initState();
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
              // App bar
              Container(
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
                        l10n.dailyQuiz,
                        style: const TextStyle(
                          color: AppColors.brainPurple,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Concept card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1B8A3C), Color(0xFF52BE80)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF1B8A3C).withValues(alpha: 0.4),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.auto_awesome, color: Colors.white, size: 48),
                            const SizedBox(height: 12),
                            Text(
                              l10n.todaysConcept,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              widget.concept.conceptName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Description (cachée si vide)
                      if (widget.concept.conceptDescription.isNotEmpty) ...[
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
                                  const Icon(Icons.menu_book, color: AppColors.brainPurple, size: 22),
                                  const SizedBox(width: 8),
                                  Text(
                                    l10n.explanation.replaceAll('💡 ', '').replaceAll(' :', ''),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.brainPurple,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                widget.concept.conceptDescription,
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: AppColors.textPrimary,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Info badges
                      Row(
                        children: [
                          Expanded(
                            child: _buildInfoBadge(
                              icon: Icons.star_rounded,
                              text: l10n.xpTriple,
                              color: const Color(0xFF52BE80),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildInfoBadge(
                              icon: Icons.favorite,
                              text: l10n.noLivesNeeded,
                              color: AppColors.success,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Info text
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.infoLight,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline, color: AppColors.info, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                l10n.dailyQuizInfo,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.info,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Start button
                      SizedBox(
                        width: double.infinity,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: const LinearGradient(
                              colors: [Color(0xFF1B8A3C), Color(0xFF52BE80)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF1B8A3C).withValues(alpha: 0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton.icon(
                            onPressed: widget.concept.alreadyCompleted
                                ? null
                                : () {
                                    final languageCode = context.read<LanguageProvider>().currentLanguage;
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => DailyQuizPage(
                                          concept: widget.concept,
                                          languageCode: languageCode,
                                        ),
                                      ),
                                    );
                                  },
                            icon: Icon(
                              widget.concept.alreadyCompleted
                                  ? Icons.check_circle
                                  : Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                            label: Text(
                              widget.concept.alreadyCompleted
                                  ? l10n.dailyQuizCompleted
                                  : l10n.startDailyQuiz,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              disabledBackgroundColor: Colors.transparent,
                              disabledForegroundColor: Colors.white70,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
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

  Widget _buildInfoBadge({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
