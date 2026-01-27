import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../quiz/data/models/question_model.dart';
import '../../data/providers/pvp_provider.dart';

class PvPGamePage extends StatefulWidget {
  const PvPGamePage({super.key});

  @override
  State<PvPGamePage> createState() => _PvPGamePageState();
}

class _PvPGamePageState extends State<PvPGamePage> with TickerProviderStateMixin {
  static const int roundDurationSeconds = 90;

  Timer? _timer;
  int _secondsRemaining = roundDurationSeconds;
  String? _selectedAnswerId;
  bool _showingFeedback = false;
  bool _isCorrectAnswer = false;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _startTimer();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  void _startTimer() {
    _timer?.cancel();
    _secondsRemaining = roundDurationSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        _secondsRemaining--;
      });

      // Update time spent in provider
      final pvpProvider = context.read<PvPProvider>();
      pvpProvider.updateTimeSpent(roundDurationSeconds - _secondsRemaining);

      if (_secondsRemaining <= 0) {
        timer.cancel();
        _onTimeUp();
      }
    });
  }

  void _onTimeUp() {
    final pvpProvider = context.read<PvPProvider>();

    // Skip remaining questions
    while (!pvpProvider.hasAnsweredAllQuestions) {
      pvpProvider.skipQuestion();
    }
  }

  void _selectAnswer(QuestionModel question, String answerId, bool isCorrect) {
    if (_showingFeedback) return;

    setState(() {
      _selectedAnswerId = answerId;
      _showingFeedback = true;
      _isCorrectAnswer = isCorrect;
    });

    // Record the answer
    final pvpProvider = context.read<PvPProvider>();
    pvpProvider.selectAnswer(
      question.id,
      answerId,
      isCorrect,
      question.difficulty,
    );

    // Wait 1 second then move to next question
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (!mounted) return;
      setState(() {
        _selectedAnswerId = null;
        _showingFeedback = false;
      });
    });
  }

  Color _getTimerColor() {
    if (_secondsRemaining > 60) return AppColors.success;
    if (_secondsRemaining > 30) return AppColors.warning;
    return AppColors.error;
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

  String _getDifficultyLabel(String difficulty, AppLocalizations l10n) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return 'Easy';
      case 'medium':
        return 'Medium';
      case 'hard':
        return 'Hard';
      default:
        return difficulty;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Consumer<PvPProvider>(
      builder: (context, pvpProvider, child) {
        final currentMatch = pvpProvider.currentMatch;
        final currentRound = pvpProvider.currentRound;
        final currentQuestion = pvpProvider.currentQuestion;

        // Check if round is complete
        if (pvpProvider.hasAnsweredAllQuestions && currentRound != null) {
          return _buildRoundEndScreen(pvpProvider, l10n);
        }

        // Check if match is complete
        if (currentMatch?.isCompleted == true) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showFinalResultsDialog(pvpProvider, l10n);
          });
        }

        return Scaffold(
          body: Container(
            decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
            child: SafeArea(
              child: Column(
                children: [
                  // AppBar with round and score
                  _buildAppBar(pvpProvider, l10n),

                  // Timer
                  _buildTimer(),

                  // Progress indicator
                  _buildProgressIndicator(pvpProvider, l10n),

                  // Question card
                  Expanded(
                    child: currentQuestion != null
                        ? _buildQuestionCard(currentQuestion, l10n)
                        : const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.brainPurple,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAppBar(PvPProvider pvpProvider, AppLocalizations l10n) {
    final currentMatch = pvpProvider.currentMatch;
    final currentRound = currentMatch?.currentRound ?? 1;
    final myScore = pvpProvider.myTotalScore;
    final opponentScore = pvpProvider.opponentTotalScore;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Round indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: AppColors.softShadow,
            ),
            child: Text(
              'Round $currentRound/3',
              style: const TextStyle(
                color: AppColors.brainPurple,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const Spacer(),

          // Score
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: AppColors.softShadow,
            ),
            child: Row(
              children: [
                Text(
                  '${l10n.score}: ',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
                Text(
                  '$myScore',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  ' - ',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                  ),
                ),
                Text(
                  '$opponentScore',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimer() {
    final progress = _secondsRemaining / roundDurationSeconds;
    final timerColor = _getTimerColor();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: SizedBox(
          width: 100,
          height: 100,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background circle
              CircularProgressIndicator(
                value: 1,
                strokeWidth: 8,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.grey.shade200),
              ),
              // Progress circle
              CircularProgressIndicator(
                value: progress,
                strokeWidth: 8,
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation<Color>(timerColor),
              ),
              // Time text
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.timer,
                      color: timerColor,
                      size: 20,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_secondsRemaining}s',
                      style: TextStyle(
                        color: timerColor,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(PvPProvider pvpProvider, AppLocalizations l10n) {
    final currentIndex = pvpProvider.currentQuestionIndex;
    final totalQuestions = pvpProvider.currentQuestions.length;
    final progress = totalQuestions > 0 ? (currentIndex / totalQuestions) : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Question ${currentIndex + 1}/$totalQuestions',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: const TextStyle(
                  color: AppColors.brainPurple,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.brainPurple),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(QuestionModel question, AppLocalizations l10n) {
    final difficultyColor = _getDifficultyColor(question.difficulty);
    final difficultyLabel = _getDifficultyLabel(question.difficulty, l10n);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Question card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: AppColors.cardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Difficulty badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: difficultyColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: difficultyColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.signal_cellular_alt,
                        color: difficultyColor,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        difficultyLabel,
                        style: TextStyle(
                          color: difficultyColor,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _getPointsForDifficulty(question.difficulty),
                        style: TextStyle(
                          color: difficultyColor.withOpacity(0.8),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Question text
                Text(
                  question.questionText,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Answer buttons
          ...question.answers.map((answer) {
            final isSelected = _selectedAnswerId == answer.id;
            final showCorrect = _showingFeedback && answer.isCorrect;
            final showIncorrect = _showingFeedback && isSelected && !answer.isCorrect;

            Color buttonColor = AppColors.white;
            Color borderColor = Colors.grey.shade300;
            Color textColor = AppColors.textPrimary;

            if (showCorrect) {
              buttonColor = AppColors.success.withOpacity(0.15);
              borderColor = AppColors.success;
              textColor = AppColors.success;
            } else if (showIncorrect) {
              buttonColor = AppColors.error.withOpacity(0.15);
              borderColor = AppColors.error;
              textColor = AppColors.error;
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: MouseRegion(
                cursor: _showingFeedback
                    ? SystemMouseCursors.basic
                    : SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: _showingFeedback
                      ? null
                      : () => _selectAnswer(question, answer.id, answer.isCorrect),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: buttonColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderColor, width: 2),
                      boxShadow: isSelected || showCorrect || showIncorrect
                          ? [
                              BoxShadow(
                                color: borderColor.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : AppColors.softShadow,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            answer.answerText,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: textColor,
                            ),
                          ),
                        ),
                        if (showCorrect)
                          const Icon(Icons.check_circle, color: AppColors.success, size: 24)
                        else if (showIncorrect)
                          const Icon(Icons.cancel, color: AppColors.error, size: 24),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  String _getPointsForDifficulty(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return '+1 pt';
      case 'medium':
        return '+2 pts';
      case 'hard':
        return '+3 pts';
      default:
        return '+1 pt';
    }
  }

  Widget _buildRoundEndScreen(PvPProvider pvpProvider, AppLocalizations l10n) {
    final currentRound = pvpProvider.currentRound;
    final isRoundComplete = currentRound?.isRoundCompleted ?? false;
    final myRoundScore = pvpProvider.myRoundScore;

    // Check if opponent finished
    final isPlayer1 = pvpProvider.isPlayer1;
    final opponentFinished = isPlayer1
        ? currentRound?.isPlayer2Completed ?? false
        : currentRound?.isPlayer1Completed ?? false;

    if (!isRoundComplete) {
      // Waiting for opponent
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
          child: SafeArea(
            child: Center(
              child: Container(
                margin: const EdgeInsets.all(24),
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: AppColors.cardShadow,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Animated waiting icon
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: 1.0 + (_pulseController.value * 0.1),
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppColors.brainPurple.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.hourglass_top,
                              color: AppColors.brainPurple,
                              size: 48,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),

                    Text(
                      l10n.score,
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      '$myRoundScore ${l10n.points}',
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: AppColors.brainPurple,
                      ),
                    ),
                    const SizedBox(height: 24),

                    Text(
                      opponentFinished
                          ? l10n.opponentFinished
                          : l10n.waitingForOpponent,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: opponentFinished
                            ? AppColors.warning
                            : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),

                    if (!opponentFinished)
                      const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.brainPurple,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Round complete - show results
    return _buildRoundResultsScreen(pvpProvider, l10n);
  }

  Widget _buildRoundResultsScreen(PvPProvider pvpProvider, AppLocalizations l10n) {
    final currentRound = pvpProvider.currentRound;
    final currentMatch = pvpProvider.currentMatch;
    final isPlayer1 = pvpProvider.isPlayer1;

    final myScore = isPlayer1
        ? currentRound?.player1Score ?? 0
        : currentRound?.player2Score ?? 0;
    final opponentScore = isPlayer1
        ? currentRound?.player2Score ?? 0
        : currentRound?.player1Score ?? 0;

    final roundNumber = currentRound?.roundNumber ?? 1;
    final isLastRound = roundNumber >= 3;

    // Determine round result
    String resultText;
    Color resultColor;
    IconData resultIcon;

    if (myScore > opponentScore) {
      resultText = l10n.victory;
      resultColor = AppColors.success;
      resultIcon = Icons.emoji_events;
    } else if (myScore < opponentScore) {
      resultText = l10n.defeat;
      resultColor = AppColors.error;
      resultIcon = Icons.sentiment_dissatisfied;
    } else {
      resultText = l10n.draw;
      resultColor = Colors.grey;
      resultIcon = Icons.handshake;
    }

    // Auto transition after 3 seconds (if not last round)
    if (!isLastRound) {
      Future.delayed(const Duration(seconds: 3), () {
        if (!mounted) return;
        // Move to next round
        pvpProvider.loadRound(roundNumber + 1);
        _startTimer();
      });
    } else {
      // Show final results dialog
      Future.delayed(const Duration(seconds: 2), () {
        if (!mounted) return;
        _showFinalResultsDialog(pvpProvider, l10n);
      });
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Center(
            child: Container(
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: AppColors.cardShadow,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.roundComplete(roundNumber),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Result icon
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: resultColor.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      resultIcon,
                      color: resultColor,
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 16),

                  Text(
                    resultText,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: resultColor,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Score comparison
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildScoreColumn(l10n.you, myScore, AppColors.brainPurple),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 24),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: const Text(
                          'VS',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      _buildScoreColumn(l10n.opponent, opponentScore, Colors.grey),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Next round info
                  if (!isLastRound) ...[
                    Text(
                      l10n.nextRoundStarting,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.brainPurple,
                      ),
                    ),
                  ] else ...[
                    Text(
                      l10n.finalResultsComing,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScoreColumn(String label, int score, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Text(
            '$score',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  void _showFinalResultsDialog(PvPProvider pvpProvider, AppLocalizations l10n) {
    final currentMatch = pvpProvider.currentMatch;
    if (currentMatch == null) return;

    final didWin = pvpProvider.didWin;
    final myScore = pvpProvider.myTotalScore;
    final opponentScore = pvpProvider.opponentTotalScore;
    final ratingChange = pvpProvider.myRatingChange ?? 0;

    // Determine result
    String resultText;
    Color resultColor;
    IconData resultIcon;

    if (didWin == true) {
      resultText = l10n.victory;
      resultColor = AppColors.success;
      resultIcon = Icons.emoji_events;
    } else if (didWin == false) {
      resultText = l10n.defeat;
      resultColor = AppColors.error;
      resultIcon = Icons.sentiment_dissatisfied;
    } else {
      resultText = l10n.draw;
      resultColor = Colors.grey;
      resultIcon = Icons.handshake;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Trophy/Result Icon with animation
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 800),
                curve: Curves.elasticOut,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            resultColor.withOpacity(0.3),
                            resultColor.withOpacity(0.1),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: resultColor.withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Icon(
                        resultIcon,
                        color: resultColor,
                        size: 64,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),

              // Result text
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOut,
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Text(
                      resultText,
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: resultColor,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),

              // Score
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Column(
                      children: [
                        Text(
                          l10n.you,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          '$myScore',
                          style: const TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: AppColors.brainPurple,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 24),
                      child: const Text(
                        '-',
                        style: TextStyle(
                          fontSize: 32,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    Column(
                      children: [
                        Text(
                          l10n.opponent,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          '$opponentScore',
                          style: TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Rating change
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  color: ratingChange >= 0
                      ? AppColors.success.withOpacity(0.1)
                      : AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: ratingChange >= 0
                        ? AppColors.success.withOpacity(0.3)
                        : AppColors.error.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      ratingChange >= 0 ? Icons.trending_up : Icons.trending_down,
                      color: ratingChange >= 0 ? AppColors.success : AppColors.error,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${ratingChange >= 0 ? '+' : ''}$ratingChange ${l10n.rating}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: ratingChange >= 0 ? AppColors.success : AppColors.error,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Back button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    pvpProvider.reset();
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brainPurple,
                    padding: const EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    l10n.backToMenu,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
