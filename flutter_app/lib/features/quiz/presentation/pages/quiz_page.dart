import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../lives/data/providers/lives_provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/repositories/quiz_repository.dart';
import '../../data/models/theme_model.dart';
import '../../data/models/question_model.dart';
import '../../../auth/data/repositories/auth_repository.dart';
import '../../../../features/profile/data/repositories/profile_repository.dart';
import '../../../lives/presentation/widgets/no_lives_dialog.dart';
import '../../../lives/presentation/widgets/lives_indicator.dart';

class QuizPage extends StatefulWidget {
  final ThemeModel theme;
  final int userLevel;

  const QuizPage({super.key, required this.theme, required this.userLevel});

  @override
  State<QuizPage> createState() => _QuizPageState();
}

/// Returns difficulty percentages based on user level
/// Returns a map with 'easy', 'medium', 'hard' keys
Map<String, int> getDifficultyForLevel(int level) {
  if (level <= 3) {
    return {'easy': 100, 'medium': 0, 'hard': 0};
  } else if (level <= 6) {
    return {'easy': 80, 'medium': 20, 'hard': 0};
  } else if (level <= 9) {
    return {'easy': 60, 'medium': 35, 'hard': 5};
  } else if (level <= 12) {
    return {'easy': 50, 'medium': 40, 'hard': 10};
  } else if (level <= 15) {
    return {'easy': 40, 'medium': 45, 'hard': 15};
  } else if (level <= 18) {
    return {'easy': 30, 'medium': 50, 'hard': 20};
  } else if (level <= 21) {
    return {'easy': 25, 'medium': 50, 'hard': 25};
  } else if (level <= 24) {
    return {'easy': 20, 'medium': 40, 'hard': 40};
  } else if (level <= 27) {
    return {'easy': 15, 'medium': 45, 'hard': 40};
  } else if (level <= 30) {
    return {'easy': 10, 'medium': 40, 'hard': 50};
  } else {
    return {'easy': 5, 'medium': 45, 'hard': 50};
  }
}

class _QuizPageState extends State<QuizPage> {
  final _repository = QuizRepository();
  List<QuestionModel> questions = [];
  int currentQuestionIndex = 0;
  int score = 0;
  bool isLoading = true;
  bool hasAnswered = false;
  String? selectedAnswerId;

  @override
  void initState() {
    super.initState();
    loadQuestions();
  }

  Future<void> loadQuestions() async {
    try {
      final languageCode = context.read<LanguageProvider>().currentLanguage;
      final difficulty = getDifficultyForLevel(widget.userLevel);
      final result = await _repository.getQuestions(
        themeId: widget.theme.id,
        languageCode: languageCode,
        limit: 10,
        easyPercent: difficulty['easy']!,
        mediumPercent: difficulty['medium']!,
        hardPercent: difficulty['hard']!,
      );
      final authRepo = AuthRepository();
      final profileRepo = ProfileRepository();
      if (authRepo.isLoggedIn()) {
        await profileRepo.updateStreak(authRepo.getCurrentUserId()!);
      }
      setState(() {
        questions = result;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading questions: $e')),
        );
      }
    }
  }

  void selectAnswer(String answerId, bool isCorrect, String questionId) async {
    if (hasAnswered) return;

    setState(() {
      selectedAnswerId = answerId;
      hasAnswered = true;
      if (isCorrect) score++;
    });

    if (!isCorrect && mounted) {
      final livesProvider = context.read<LivesProvider>();
      await livesProvider.useLife();
      if (livesProvider.currentLives <= 0 && mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => NoLivesDialog(
            onClose: () {
              Navigator.pop(context);
            },
          ),
        );
        return;
      }
    }

    final authRepo = AuthRepository();
    if (authRepo.isLoggedIn()) {
      try {
        await _repository.saveUserAnswer(
          userId: authRepo.getCurrentUserId()!,
          questionId: questionId,
          selectedAnswerId: answerId,
          isCorrect: isCorrect,
          languageUsed: context.read<LanguageProvider>().currentLanguage,
        );
      } catch (e) {
        print('Error saving answer: $e');
      }
    }

    if (mounted) {
      showAnswerDialog(isCorrect);
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

  void showResultDialog() async {
    final l10n = AppLocalizations.of(context)!;
    final xpEarned = score * 10;
    final percentage = (score / questions.length) * 100;

    final authRepo = AuthRepository();
    if (authRepo.isLoggedIn() && score > 0) {
      try {
        await _repository.addQuizCompletionXp(
          userId: authRepo.getCurrentUserId()!,
          themeId: widget.theme.id,
          correctAnswers: score,
        );
      } catch (e) {
        print('Error adding XP: $e');
      }
    }

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
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
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    shape: BoxShape.circle,
                  ),
                  child: Image.asset(
                    'assets/branding/mascot/brainly_victory.png',
                    height: 80,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  l10n.quizCompleted,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.brainPurple,
                  ),
                ),
                const SizedBox(height: 24),

                // Score circle
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        percentage >= 70 ? AppColors.success : percentage >= 40 ? AppColors.warning : AppColors.error,
                        percentage >= 70 ? AppColors.success.withOpacity(0.7) : percentage >= 40 ? AppColors.warning.withOpacity(0.7) : AppColors.error.withOpacity(0.7),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (percentage >= 70 ? AppColors.success : percentage >= 40 ? AppColors.warning : AppColors.error).withOpacity(0.4),
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
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        '$score/${questions.length}',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // XP Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.amber.withOpacity(0.4),
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
                        '+$xpEarned ${l10n.xp}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).pop();
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: AppColors.brainPurple, width: 2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(l10n.backToThemes),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: AppColors.primaryGradient,
                        ),
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            setState(() {
                              currentQuestionIndex = 0;
                              score = 0;
                              hasAnswered = false;
                              selectedAnswerId = null;
                            });
                            loadQuestions();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text(
                            l10n.tryAgain,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void showAnswerDialog(bool isCorrect) {
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
                        style: const TextStyle(
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
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.explanation,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: isCorrect ? AppColors.success : AppColors.error,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          currentQuestion.explanation!,
                          style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      if (currentQuestionIndex < questions.length - 1) {
                        setState(() {
                          currentQuestionIndex++;
                          hasAnswered = false;
                          selectedAnswerId = null;
                        });
                      } else {
                        showResultDialog();
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
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
          decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
          child: const Center(
            child: CircularProgressIndicator(color: AppColors.brainPurple),
          ),
        ),
      );
    }

    if (questions.isEmpty) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
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
                          style: const TextStyle(
                            fontSize: 18,
                            color: AppColors.textSecondary,
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
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
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
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
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
                            style: const TextStyle(
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
                            color: AppColors.brainPurple.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: progress,
                          child: Container(
                            height: 8,
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient,
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
                      // Difficulty Badge
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: _getDifficultyColor(currentQuestion.difficulty).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _getDifficultyColor(currentQuestion.difficulty).withOpacity(0.3),
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
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Question Card
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: AppColors.cardShadow,
                        ),
                        child: Column(
                          children: [
                            Text(
                              widget.theme.icon,
                              style: const TextStyle(
                                fontSize: 40,
                                fontFamilyFallback: ['Apple Color Emoji', 'Segoe UI Emoji', 'Noto Color Emoji'],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              currentQuestion.questionText,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
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

                        Color bgColor = AppColors.white;
                        Color borderColor = AppColors.brainPurple.withOpacity(0.2);
                        Color textColor = AppColors.textPrimary;

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
                      }).toList(),
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
                fontSize: 18,
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
