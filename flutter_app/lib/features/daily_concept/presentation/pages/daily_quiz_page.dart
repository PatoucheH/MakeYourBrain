import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:confetti/confetti.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../quiz/data/repositories/quiz_repository.dart';
import '../../../quiz/data/models/question_model.dart';
import '../../../auth/data/repositories/auth_repository.dart';
import '../../../profile/data/repositories/profile_repository.dart';
import '../../../auth/providers/user_stats_provider.dart';
import '../../data/models/daily_concept_model.dart';
import '../../data/repositories/daily_concept_repository.dart';

class DailyQuizPage extends StatefulWidget {
  final DailyConceptModel concept;
  final String languageCode;

  const DailyQuizPage({
    super.key,
    required this.concept,
    required this.languageCode,
  });

  @override
  State<DailyQuizPage> createState() => _DailyQuizPageState();
}

class _DailyQuizPageState extends State<DailyQuizPage> {
  final _dailyRepo = DailyConceptRepository();
  final _quizRepo = QuizRepository();
  late final ConfettiController _confettiController;
  final _audioPlayer = AudioPlayer();
  List<QuestionModel> questions = [];
  int currentQuestionIndex = 0;
  int score = 0;
  bool isLoading = true;
  bool hasAnswered = false;
  bool _completed = false; // guard: XP + completion are only triggered once
  String? selectedAnswerId;
  final List<String> _questionIds = [];
  final List<String> _answerIds = [];

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 4));
    _loadQuestions();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadQuestions() async {
    try {
      // Fixed difficulty for the daily: 5 easy / 3 medium / 2 hard
      final result = await _dailyRepo.getDailyQuestions(
        languageCode: widget.languageCode,
        limit: 10,
        easyPercent: 50,
        mediumPercent: 30,
        hardPercent: 20,
      );

      if (!mounted) return;
      setState(() {
        questions = result;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.errorLoadingQuestions)),
        );
      }
    }
  }

  Future<void> selectAnswer(String answerId, bool isCorrect, String questionId) async {
    if (hasAnswered) return;

    _questionIds.add(questionId);
    _answerIds.add(answerId);

    setState(() {
      selectedAnswerId = answerId;
      hasAnswered = true;
      if (isCorrect) score++;
    });

    final currentLanguage = context.read<LanguageProvider>().currentLanguage;

    // NO useLife() here - the daily quiz does not cost a life

    final authRepo = AuthRepository();
    if (authRepo.isLoggedIn()) {
      try {
        await _quizRepo.saveUserAnswer(
          userId: authRepo.getCurrentUserId()!,
          questionId: questionId,
          selectedAnswerId: answerId,
          isCorrect: isCorrect,
          languageUsed: currentLanguage,
        );
      } catch (e) {
        debugPrint('Error saving answer: $e');
      }
    }

    if (mounted) {
      _showAnswerDialog(isCorrect);
    }
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return AppColors.success;
      case 'medium':
        return AppColors.warning;
      case 'hard':
        return AppColors.error;
      default:
        return AppColors.brainPurple;
    }
  }

  Future<void> _showResultDialog() async {
    final l10n = AppLocalizations.of(context)!;
    final xpEarned = score * 10 * 3; // XP x3
    final percentage = (score / questions.length) * 100;

    final authRepo = AuthRepository();
    if (authRepo.isLoggedIn()) {
      try {
        await ProfileRepository().updateStreak(authRepo.getCurrentUserId()!);
        if (mounted) {
          context.read<UserStatsProvider>().loadFromServer();
        }
      } catch (e) {
        debugPrint('Error updating streak: $e');
      }
      try {
        // The RPC verifies each (question, answer) pair server-side.
        // The daily x3 bonus is handled via bonusXp.
        if (_questionIds.isNotEmpty) {
          await _quizRepo.addQuizCompletionXp(
            userId: authRepo.getCurrentUserId()!,
            themeId: widget.concept.themeId,
            questionIds: List.unmodifiable(_questionIds),
            answerIds: List.unmodifiable(_answerIds),
            bonusXp: score * 20, // equivalent to x3 (10 XP base × 2 bonus)
          );
        }
        // Mark the daily quiz as complete
        await _dailyRepo.completeDailyConcept(authRepo.getCurrentUserId()!);
      } catch (e) {
        debugPrint('Error adding XP / completing daily: $e');
      }
    }

    if (!mounted) return;

    final starCount = percentage >= 80 ? 3 : percentage >= 50 ? 2 : 1;
    final mascotImage = percentage >= 80
        ? 'assets/branding/mascot/brainly_victory.png'
        : percentage >= 50
            ? 'assets/branding/mascot/brainly_happy.png'
            : 'assets/branding/mascot/brainly_encourage.png';
    final resultTitle = percentage >= 80
        ? l10n.resultExcellent
        : percentage >= 50
            ? l10n.resultGoodJob
            : l10n.resultKeepGoing;

    if (percentage >= 50) {
      _confettiController.play();
    }
    if (percentage >= 80) {
      _audioPlayer.play(AssetSource('sounds/victory_epic.mp3')).catchError((_) {});
    } else if (percentage >= 50) {
      _audioPlayer.play(AssetSource('sounds/victory.mp3')).catchError((_) {});
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Stack(
          alignment: Alignment.topCenter,
          clipBehavior: Clip.none,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.cardColorOf(context),
                borderRadius: BorderRadius.circular(24),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        shape: BoxShape.circle,
                      ),
                      child: Image.asset(mascotImage, height: 80),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      resultTitle,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.brainPurple,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(3, (i) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(
                          i < starCount ? Icons.star_rounded : Icons.star_outline_rounded,
                          color: i < starCount ? const Color(0xFFFFD700) : Colors.grey.shade300,
                          size: 36,
                        ),
                      )),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            percentage >= 70 ? AppColors.success : percentage >= 40 ? AppColors.warning : AppColors.error,
                            (percentage >= 70 ? AppColors.success : percentage >= 40 ? AppColors.warning : AppColors.error).withValues(alpha: 0.7),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (percentage >= 70 ? AppColors.success : percentage >= 40 ? AppColors.warning : AppColors.error).withValues(alpha: 0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${percentage.toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            '$score/${questions.length}',
                            style: TextStyle(fontSize: 16, color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1B8A3C), Color(0xFF52BE80)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF1B8A3C).withValues(alpha: 0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_rounded, color: Colors.white, size: 28),
                          const SizedBox(width: 8),
                          Text(
                            '+$xpEarned ${l10n.xp} (x3!)',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: AppColors.primaryGradient,
                        ),
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            Navigator.of(context).pop();
                            Navigator.of(context).pop(true);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text(
                            l10n.backToThemes,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (percentage >= 50)
              ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                numberOfParticles: percentage >= 80 ? 18 : 8,
                gravity: 0.25,
                emissionFrequency: percentage >= 80 ? 0.05 : 0.02,
                colors: percentage >= 80
                    ? const [Color(0xFFFFD700), Colors.white, Color(0xFFC0C0C0), Color(0xFFFFE066)]
                    : const [Color(0xFFFFD700), Color(0xFFFFA500), Colors.white],
              ),
          ],
        ),
      ),
    );
  }

  void _showAnswerDialog(bool isCorrect) {
    final l10n = AppLocalizations.of(context)!;
    final currentQuestion = questions[currentQuestionIndex];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isCorrect ? AppColors.successLight : AppColors.errorLight,
            borderRadius: BorderRadius.circular(24),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  isCorrect
                      ? 'assets/branding/mascot/brainly_happy.png'
                      : 'assets/branding/mascot/brainly_fail.png',
                  height: 80,
                ),
                const SizedBox(height: 16),

                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: isCorrect ? AppColors.success : AppColors.error,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isCorrect ? Icons.check_circle : Icons.cancel,
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isCorrect ? l10n.correctAnswer : l10n.incorrectAnswer,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                if (currentQuestion.explanation != null) ...[
                  _ExplanationToggle(
                    explanation: currentQuestion.explanation!,
                    isCorrect: isCorrect,
                    label: l10n.explanation,
                  ),
                  const SizedBox(height: 20),
                ],

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.of(context).pop();
                      if (currentQuestionIndex < questions.length - 1) {
                        setState(() {
                          currentQuestionIndex++;
                          hasAnswered = false;
                          selectedAnswerId = null;
                        });
                      } else if (!_completed) {
                        setState(() => _completed = true);
                        await _showResultDialog();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isCorrect ? AppColors.success : AppColors.error,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      l10n.continueButton,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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

    if (questions.isEmpty) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(gradient: AppColors.backgroundGradientOf(context)),
          child: SafeArea(
            child: Column(
              children: [
                _buildCustomAppBar(l10n),
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/branding/mascot/brainly_thinking.png',
                          height: 120,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          l10n.noQuestionsAvailable,
                          style: TextStyle(
                            fontSize: 18,
                            color: AppColors.textSecondaryOf(context),
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

    final currentQuestion = questions[currentQuestionIndex];
    final progress = (currentQuestionIndex + 1) / questions.length;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.backgroundGradientOf(context)),
        child: SafeArea(
          child: Column(
            children: [
              _buildCustomAppBar(l10n),

              // Progress Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Question ${currentQuestionIndex + 1}/${questions.length}',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondaryOf(context),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.brainPurpleLight,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${l10n.yourScore}: $score',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.brainPurple,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Stack(
                      children: [
                        Container(
                          height: 8,
                          decoration: BoxDecoration(
                            color: AppColors.brainPurple.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: progress,
                          child: Container(
                            height: 8,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF1B8A3C), Color(0xFF52BE80)],
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Question Card
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Difficulty Badge + XP x3 badge
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: _getDifficultyColor(currentQuestion.difficulty).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _getDifficultyColor(currentQuestion.difficulty).withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              currentQuestion.difficulty.toUpperCase(),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _getDifficultyColor(currentQuestion.difficulty),
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF1B8A3C), Color(0xFF52BE80)],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              l10n.xpTriple,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Question Card
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppColors.cardColorOf(context),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: AppColors.cardShadow,
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.auto_awesome, size: 40, color: Color(0xFF1B8A3C)),
                            const SizedBox(height: 16),
                            Text(
                              currentQuestion.questionText,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimaryOf(context),
                                height: 1.4,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Answer Options
                      ...currentQuestion.answers.map((answer) {
                        final isSelected = selectedAnswerId == answer.id;
                        final showCorrect = hasAnswered && answer.isCorrect;
                        final showWrong = hasAnswered && isSelected && !answer.isCorrect;

                        Color bgColor = AppColors.cardColorOf(context);
                        Color borderColor = AppColors.brainPurple.withValues(alpha: 0.2);
                        Color textColor = AppColors.textPrimaryOf(context);

                        if (showCorrect) {
                          bgColor = AppColors.successLight;
                          borderColor = AppColors.success;
                          textColor = AppColors.success;
                        } else if (showWrong) {
                          bgColor = AppColors.errorLight;
                          borderColor = AppColors.error;
                          textColor = AppColors.error;
                        } else if (isSelected) {
                          borderColor = AppColors.brainPurple;
                        }

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: MouseRegion(
                            cursor: hasAnswered ? SystemMouseCursors.basic : SystemMouseCursors.click,
                            child: GestureDetector(
                              onTap: hasAnswered
                                  ? null
                                  : () => selectAnswer(answer.id, answer.isCorrect, currentQuestion.id),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                  color: bgColor,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: borderColor, width: 2),
                                  boxShadow: isSelected && !hasAnswered
                                      ? AppColors.cardShadow
                                      : AppColors.softShadow,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        answer.text,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          color: textColor,
                                        ),
                                      ),
                                    ),
                                    if (showCorrect)
                                      const Icon(Icons.check_circle, color: AppColors.success),
                                    if (showWrong)
                                      const Icon(Icons.cancel, color: AppColors.error),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 20),
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

  Widget _buildCustomAppBar(AppLocalizations l10n) {
    final themeName = widget.concept.themeName;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.cardColorOf(context),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Badge "Discovery Quiz"
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B8A3C).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    l10n.discoveryQuizBadge,
                    style: TextStyle(
                      color: Color(0xFF1B8A3C),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                // Concept name
                Text(
                  widget.concept.conceptName,
                  style: TextStyle(
                    color: AppColors.brainPurple,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (themeName.isNotEmpty)
                  Text(
                    themeName,
                    style: TextStyle(
                      color: AppColors.textSecondaryOf(context).withValues(alpha: 0.8),
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Badge XP x3
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1B8A3C), Color(0xFF52BE80)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: AppColors.softShadow,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 4),
                Text(
                  l10n.xpTriple,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ExplanationToggle extends StatefulWidget {
  final String explanation;
  final bool isCorrect;
  final String label;

  const _ExplanationToggle({
    required this.explanation,
    required this.isCorrect,
    required this.label,
  });

  @override
  State<_ExplanationToggle> createState() => _ExplanationToggleState();
}

class _ExplanationToggleState extends State<_ExplanationToggle> {
  bool _showExplanation = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.isCorrect ? AppColors.success : AppColors.error;

    return GestureDetector(
      onTap: () => setState(() => _showExplanation = !_showExplanation),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardColorOf(context),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.label,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: color,
                  ),
                ),
                Icon(
                  _showExplanation ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: color,
                ),
              ],
            ),
            if (_showExplanation) ...[
              const SizedBox(height: 8),
              Text(
                widget.explanation,
                style: TextStyle(fontSize: 14, color: AppColors.textPrimaryOf(context)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
