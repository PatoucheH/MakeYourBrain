import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../lives/data/providers/lives_provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/providers/language_provider.dart';
import '../../data/repositories/quiz_repository.dart';
import '../../data/models/theme_model.dart';
import '../../data/models/question_model.dart';
import '../../../auth/data/repositories/auth_repository.dart';
import '../../../../features/profile/data/repositories/profile_repository.dart';
import '../../../lives/presentation/widgets/no_lives_dialog.dart';

class QuizPage extends StatefulWidget {
  final ThemeModel theme;

  const QuizPage({super.key, required this.theme});

  @override
  State<QuizPage> createState() => _QuizPageState();
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
      final result = await _repository.getQuestions(
        themeId: widget.theme.id,
        languageCode: languageCode,
        limit: 10,
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
          themeId: widget.theme.id,
        );
      } catch (e) {
        print('Error saving answer: $e');
      }
    }

    if (mounted) {
      showAnswerDialog(isCorrect);
    }
  }

  void showResultDialog() {
    final l10n = AppLocalizations.of(context)!;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Column(
          children: [
            Image.asset(
              'assets/branding/mascot/brainly_victory.png',
              height: 120,
            ),
            const SizedBox(height: 12),
            Text(l10n.quizCompleted),
          ],
        ),
        content: Text(
          '${l10n.yourScore}: $score/${questions.length}\n'
          '${((score / questions.length) * 100).toStringAsFixed(0)}%',
          style: const TextStyle(fontSize: 18),
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: Text(l10n.backToThemes),
          ),
          ElevatedButton(
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
            child: Text(l10n.tryAgain),
          ),
        ],
      ),
    );
  }

  void showAnswerDialog(bool isCorrect) {
    final l10n = AppLocalizations.of(context)!;
    final currentQuestion = questions[currentQuestionIndex];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: isCorrect ? Colors.green.shade50 : Colors.red.shade50,
        title: Column(
          children: [
            Image.asset(
              isCorrect 
                ? 'assets/branding/mascot/brainly_happy.png'
                : 'assets/branding/mascot/brainly_fail.png',
              height: 100,
            ),
            const SizedBox(height: 12),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isCorrect ? Icons.check_circle : Icons.cancel,
                  color: isCorrect ? Colors.green : Colors.red,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Text(
                  isCorrect ? l10n.correctAnswer : l10n.incorrectAnswer,
                  style: TextStyle(
                    color: isCorrect ? Colors.green.shade900 : Colors.red.shade900,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (currentQuestion.explanation != null) ...[
                Text(
                  l10n.explanation,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  currentQuestion.explanation!,
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ],
          ),
        ),
        actions: [
          ElevatedButton(
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
              backgroundColor: isCorrect ? Colors.green : Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text(
              l10n.continueButton,
              style: const TextStyle(fontSize: 16),
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
        appBar: AppBar(title: Text(widget.theme.name)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.theme.name)),
        body: Center(
          child: Text(l10n.noQuestionsAvailable),
        ),
      );
    }

    final currentQuestion = questions[currentQuestionIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.theme.name),
        actions: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: Text(
                '${currentQuestionIndex + 1}/${questions.length}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  '${l10n.yourScore}: $score/${questions.length}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(height: 20),

            Chip(
              label: Text(
                currentQuestion.difficulty.toUpperCase(),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              backgroundColor: currentQuestion.difficulty == 'easy'
                  ? Colors.green.shade100
                  : currentQuestion.difficulty == 'medium'
                      ? Colors.orange.shade100
                      : Colors.red.shade100,
            ),
            const SizedBox(height: 20),

            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  currentQuestion.questionText,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                ),
              ),
            ),
            const SizedBox(height: 30),

            ...currentQuestion.answers.map((answer) {
              final isSelected = selectedAnswerId == answer.id;
              final showCorrect = hasAnswered && answer.isCorrect;
              final showWrong = hasAnswered && isSelected && !answer.isCorrect;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: ElevatedButton(
                  onPressed: hasAnswered
                      ? null
                      : () => selectAnswer(answer.id, answer.isCorrect, currentQuestion.id),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    backgroundColor: showCorrect
                        ? Colors.green
                        : showWrong
                            ? Colors.red
                            : null,
                    foregroundColor: showCorrect || showWrong ? Colors.white : null,
                  ),
                  child: Text(
                    answer.text,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}