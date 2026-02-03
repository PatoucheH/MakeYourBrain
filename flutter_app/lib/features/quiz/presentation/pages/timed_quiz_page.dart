import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/repositories/quiz_repository.dart';
import '../../data/models/theme_model.dart';
import '../../data/models/question_model.dart';
import '../../../auth/data/repositories/auth_repository.dart';
import '../../../../features/profile/data/repositories/profile_repository.dart';
import '../../../lives/presentation/widgets/lives_indicator.dart';

class TimedQuizPage extends StatefulWidget {
  final ThemeModel theme;
  final int totalSeconds;
  final int userLevel;

  const TimedQuizPage({
    super.key,
    required this.theme,
    required this.totalSeconds,
    required this.userLevel,
  });

  @override
  State<TimedQuizPage> createState() => _TimedQuizPageState();
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

class _TimedQuizPageState extends State<TimedQuizPage> {
  final _repository = QuizRepository();
  List<QuestionModel> questions = [];
  int currentQuestionIndex = 0;
  int score = 0;
  bool isLoading = true;
  bool hasAnswered = false;
  String? selectedAnswerId;

  // Timer state
  late int remainingSeconds;
  Timer? _timer;
  bool isQuizEnded = false;

  @override
  void initState() {
    super.initState();
    remainingSeconds = widget.totalSeconds;
    loadQuestions();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  int _getTimeBonus() {
    switch (widget.totalSeconds) {
      case 30:
        return 20;
      case 45:
        return 10;
      case 60:
        return 5;
      default:
        return 0;
    }
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
      _startTimer();
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

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        remainingSeconds--;
      });

      if (remainingSeconds <= 0) {
        timer.cancel();
        _onTimeUp();
      }
    });
  }

  void _onTimeUp() {
    if (isQuizEnded) return;
    isQuizEnded = true;
    showResultDialog();
  }

  void selectAnswer(String answerId, bool isCorrect, String questionId) async {
    if (hasAnswered || isQuizEnded) return;

    setState(() {
      selectedAnswerId = answerId;
      hasAnswered = true;
      if (isCorrect) score++;
    });

    // Save answer to database
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
        debugPrint('Error saving answer: $e');
      }
    }

    // Go to next question immediately
    if (currentQuestionIndex < questions.length - 1) {
      setState(() {
        currentQuestionIndex++;
        hasAnswered = false;
        selectedAnswerId = null;
      });
    } else {
      // All questions answered
      _timer?.cancel();
      isQuizEnded = true;
      showResultDialog();
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
    final timeBonus = _getTimeBonus();
    final percentage = questions.isEmpty ? 0.0 : (score / questions.length) * 100;

    final authRepo = AuthRepository();
    if (authRepo.isLoggedIn() && score > 0) {
      try {
        await _repository.addQuizCompletionXp(
          userId: authRepo.getCurrentUserId()!,
          themeId: widget.theme.id,
          correctAnswers: score,
          bonusXp: timeBonus,
        );
      } catch (e) {
        debugPrint('Error adding XP: $e');
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
                // Timer icon with result
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF9800), Color(0xFFFF5722)],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Image.asset(
                    'assets/branding/mascot/brainly_victory.png',
                    height: 80,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  remainingSeconds <= 0 ? l10n.timesUp : l10n.quizCompleted,
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
                        percentage >= 70 ? AppColors.success.withValues(alpha:0.7) : percentage >= 40 ? AppColors.warning.withValues(alpha:0.7) : AppColors.error.withValues(alpha:0.7),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (percentage >= 70 ? AppColors.success : percentage >= 40 ? AppColors.warning : AppColors.error).withValues(alpha:0.4),
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
                const SizedBox(height: 16),

                // Questions answered info
                Text(
                  '${l10n.questionsAnswered}: ${currentQuestionIndex + (hasAnswered ? 1 : 0)}/${questions.length}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 20),

                // XP Badges
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Score XP
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_rounded, color: Colors.white, size: 20),
                          const SizedBox(width: 4),
                          Text(
                            '+${score * 10} ${l10n.xp}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Time Bonus XP
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF9800), Color(0xFFFF5722)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.timer, color: Colors.white, size: 20),
                          const SizedBox(width: 4),
                          Text(
                            '+$timeBonus ${l10n.xp}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${l10n.timeBonus}: ${widget.totalSeconds}s',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
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
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF9800), Color(0xFFFF5722)],
                          ),
                        ),
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            setState(() {
                              currentQuestionIndex = 0;
                              score = 0;
                              hasAnswered = false;
                              selectedAnswerId = null;
                              remainingSeconds = widget.totalSeconds;
                              isQuizEnded = false;
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

  Widget _buildTimerDisplay() {
    final minutes = remainingSeconds ~/ 60;
    final seconds = remainingSeconds % 60;
    final isLow = remainingSeconds <= 10;
    final isVeryLow = remainingSeconds <= 5;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isVeryLow
              ? [AppColors.error, AppColors.error.withValues(alpha:0.8)]
              : isLow
                  ? [AppColors.warning, AppColors.warning.withValues(alpha:0.8)]
                  : [const Color(0xFFFF9800), const Color(0xFFFF5722)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (isVeryLow ? AppColors.error : isLow ? AppColors.warning : const Color(0xFFFF9800)).withValues(alpha:0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timer,
            color: Colors.white,
            size: isLow ? 28 : 24,
          ),
          const SizedBox(width: 8),
          Text(
            minutes > 0
                ? '$minutes:${seconds.toString().padLeft(2, '0')}'
                : '${seconds}s',
            style: TextStyle(
              fontSize: isLow ? 24 : 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
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

              // Timer Display (prominent)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: _buildTimerDisplay(),
              ),

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
                            color: AppColors.brainPurple.withValues(alpha:0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: progress,
                          child: Container(
                            height: 8,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFF9800), Color(0xFFFF5722)],
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
              const SizedBox(height: 16),

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
                              color: _getDifficultyColor(currentQuestion.difficulty).withValues(alpha:0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _getDifficultyColor(currentQuestion.difficulty).withValues(alpha:0.3),
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
                        Color borderColor = AppColors.brainPurple.withValues(alpha:0.2);
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () {
                _timer?.cancel();
                Navigator.pop(context);
              },
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
            child: Row(
              children: [
                const Icon(Icons.timer, color: Color(0xFFFF9800), size: 20),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    widget.theme.name,
                    style: const TextStyle(
                      color: AppColors.brainPurple,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
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
