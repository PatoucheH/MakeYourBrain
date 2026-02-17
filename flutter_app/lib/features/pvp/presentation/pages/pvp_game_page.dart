import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../quiz/data/models/question_model.dart';
import '../../data/providers/pvp_provider.dart';
import 'pvp_theme_selection_page.dart';

class PvPGamePage extends StatefulWidget {
  const PvPGamePage({super.key});

  @override
  State<PvPGamePage> createState() => _PvPGamePageState();
}

class _PvPGamePageState extends State<PvPGamePage>
    with TickerProviderStateMixin {
  static const int roundDurationSeconds = 90;

  Timer? _timer;
  int _secondsRemaining = roundDurationSeconds;
  int _displayedScore = 0;
  bool _scoreJustIncreased = false;
  bool _scoreJustDecreased = false;
  bool _answersVisible = false;
  late AnimationController _pulseController;
  bool _timerActive = false;
  bool _hasShownFinalResults = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final pvp = context.read<PvPProvider>();
      pvp.setOnGamePage(true);
      pvp.addListener(_onProviderChanged);
      _checkAndStartTimer();
    });
  }

  int _lastQuestionIndex = -1;

  void _onProviderChanged() {
    if (!mounted) return;
    _checkAndStartTimer();

    // Detect new question → hide answers then reveal after delay
    final pvp = context.read<PvPProvider>();
    if (pvp.currentQuestionIndex != _lastQuestionIndex) {
      _lastQuestionIndex = pvp.currentQuestionIndex;
      _answersVisible = false;
      if (mounted) setState(() {});
      Future.delayed(const Duration(milliseconds: 800), () {
        if (!mounted) return;
        setState(() => _answersVisible = true);
      });
    }
  }

  /// Starts the timer only when it's our turn, questions are loaded,
  /// and we haven't answered everything yet.
  void _checkAndStartTimer() {
    final pvpProvider = context.read<PvPProvider>();
    if (pvpProvider.isMyTurn &&
        pvpProvider.currentQuestions.isNotEmpty &&
        !pvpProvider.hasAnsweredAllQuestions &&
        !_timerActive) {
      _displayedScore = 0;
      _lastQuestionIndex = 0;
      _answersVisible = false;
      Future.delayed(const Duration(milliseconds: 800), () {
        if (!mounted) return;
        setState(() => _answersVisible = true);
      });
      _startTimer();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timerActive = true;
    _secondsRemaining = roundDurationSeconds;
    if (mounted) setState(() {});
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _secondsRemaining--;
      });
      context
          .read<PvPProvider>()
          .updateTimeSpent(roundDurationSeconds - _secondsRemaining);
      if (_secondsRemaining <= 0) {
        timer.cancel();
        _onTimeUp();
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timerActive = false;
  }

  void _onTimeUp() {
    context.read<PvPProvider>().finishRound();
  }

  void _selectAnswer(
      QuestionModel question, String answerId, bool isCorrect) {
    if (!_answersVisible) return; // Answers not yet revealed

    context.read<PvPProvider>().selectAnswer(
          question.id,
          answerId,
          isCorrect,
          question.difficulty,
        );

    final newScore = context.read<PvPProvider>().myRoundScore;
    final increased = newScore > _displayedScore;
    final decreased = newScore < _displayedScore;
    _displayedScore = newScore;

    if (increased || decreased) {
      setState(() {
        _scoreJustIncreased = increased;
        _scoreJustDecreased = decreased;
      });
      Future.delayed(const Duration(milliseconds: 600), () {
        if (!mounted) return;
        setState(() {
          _scoreJustIncreased = false;
          _scoreJustDecreased = false;
        });
      });
    }
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

  @override
  void dispose() {
    _timer?.cancel();
    try {
      final pvp = context.read<PvPProvider>();
      pvp.removeListener(_onProviderChanged);
      // Si le joueur quitte en plein quiz et n'a pas encore soumis,
      // auto-submit le round avec les réponses déjà données
      if (!pvp.roundSubmitted && pvp.currentRound != null && pvp.isMyTurn) {
        debugPrint('[PvP] GamePage dispose - player left during active quiz, auto-finishing round (${pvp.myAnswers.length} answers)');
        pvp.finishRound();
      }
      pvp.setOnGamePage(false);
    } catch (_) {}
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Consumer<PvPProvider>(
      builder: (context, pvpProvider, child) {
        final currentMatch = pvpProvider.currentMatch;

        // Match completed → show final results dialog once
        if (currentMatch?.isCompleted == true && !_hasShownFinalResults) {
          _hasShownFinalResults = true;
          _stopTimer();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _showFinalResultsDialog(pvpProvider, l10n);
          });
        }

        // Theme selection phase - my turn to choose
        if (pvpProvider.isMyThemeChoice) {
          _stopTimer();
          return _buildThemeSelectionScreen(pvpProvider, l10n);
        }

        // Theme selection phase - opponent choosing
        if (pvpProvider.currentMatch?.isChoosingTheme == true &&
            !pvpProvider.isMyThemeChoice) {
          _stopTimer();
          return _buildWaitingForThemeScreen(pvpProvider, l10n);
        }

        // All questions answered → round end screen
        if (pvpProvider.hasAnsweredAllQuestions &&
            pvpProvider.currentRound != null) {
          _stopTimer();
          return _buildRoundEndScreen(pvpProvider, l10n);
        }

        // Not my turn → waiting for opponent screen
        if (!pvpProvider.isMyTurn) {
          _stopTimer();
          return _buildWaitingForTurnScreen(pvpProvider, l10n);
        }

        // My turn but questions still loading
        if (pvpProvider.currentQuestions.isEmpty ||
            pvpProvider.currentQuestion == null) {
          return _buildLoadingScreen();
        }

        // My turn, questions loaded → quiz UI
        return Scaffold(
          body: Container(
            decoration:
                const BoxDecoration(gradient: AppColors.backgroundGradient),
            child: SafeArea(
              child: Column(
                children: [
                  _buildGameHeader(pvpProvider, l10n),
                  Expanded(
                    child:
                        _buildQuestionCard(pvpProvider.currentQuestion!, l10n),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ===================== SCREENS =====================

  Widget _buildThemeSelectionScreen(
      PvPProvider pvpProvider, AppLocalizations l10n) {
    final roundNumber = pvpProvider.currentMatch?.currentRound ?? 1;
    return PvPThemeSelectionPage(roundNumber: roundNumber);
  }

  Widget _buildWaitingForThemeScreen(
      PvPProvider pvpProvider, AppLocalizations l10n) {
    return Scaffold(
      body: Container(
        decoration:
            const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(pvpProvider, l10n),
              Expanded(
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
                        AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, child) {
                            return Transform.scale(
                              scale:
                                  1.0 + (_pulseController.value * 0.1),
                              child: Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: AppColors.brainPurple
                                      .withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.category,
                                  color: AppColors.brainPurple,
                                  size: 56,
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 24),
                        Text(
                          l10n.waitingForThemeSelection,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 24),
                        const SizedBox(
                          width: 32,
                          height: 32,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: AppColors.brainPurple,
                          ),
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.arrow_back),
                            label: Text(l10n.backToMenu),
                          ),
                        ),
                      ],
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

  Widget _buildWaitingForTurnScreen(
      PvPProvider pvpProvider, AppLocalizations l10n) {
    return Scaffold(
      body: Container(
        decoration:
            const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(pvpProvider, l10n),
              Expanded(
                child: SingleChildScrollView(
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
                        AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, child) {
                            return Transform.scale(
                              scale:
                                  1.0 + (_pulseController.value * 0.1),
                              child: Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: AppColors.brainPurple
                                      .withValues(alpha:0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.hourglass_top,
                                  color: AppColors.brainPurple,
                                  size: 56,
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 24),
                        Text(
                          l10n.opponentsTurn,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          l10n.waitingOpponentTurn,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 24),
                        const SizedBox(
                          width: 32,
                          height: 32,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: AppColors.brainPurple,
                          ),
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.arrow_back),
                            label: Text(l10n.backToMenu),
                          ),
                        ),
                      ],
                    ),
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

  Widget _buildLoadingScreen() {
    final pvpProvider = context.read<PvPProvider>();
    final error = pvpProvider.errorMessage;

    return Scaffold(
      body: Container(
        decoration:
            const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (error != null) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha:0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.error.withValues(alpha:0.3)),
                      ),
                      child: Text(
                        error,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.error, fontSize: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Back'),
                  ),
                ] else ...[
                  const CircularProgressIndicator(color: AppColors.brainPurple),
                  const SizedBox(height: 16),
                  const Text(
                    'Loading questions...',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===================== COMPONENTS =====================

  Widget _buildAppBar(PvPProvider pvpProvider, AppLocalizations l10n) {
    final currentMatch = pvpProvider.currentMatch;
    final currentRound = currentMatch?.currentRound ?? 1;
    final myScore = pvpProvider.myTotalScore;
    final opponentScore = pvpProvider.opponentTotalScore;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
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
              'Round $currentRound/3',
              style: const TextStyle(
                color: AppColors.brainPurple,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Spacer(),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                    color: Colors.white.withValues(alpha:0.9),
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
                    color: Colors.white.withValues(alpha:0.8),
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

  /// Header du quiz PvP : ligne 1 = Round + Timer centré + Score, ligne 2 = Question
  Widget _buildGameHeader(PvPProvider pvpProvider, AppLocalizations l10n) {
    final currentMatch = pvpProvider.currentMatch;
    final currentRound = currentMatch?.currentRound ?? 1;
    final progress = _secondsRemaining / roundDurationSeconds;
    final timerColor = _getTimerColor();

    final scoreColor = _scoreJustIncreased
        ? AppColors.success
        : _scoreJustDecreased
            ? AppColors.error
            : AppColors.brainPurple;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          // Ligne 1 : Round | Timer centré | Score
          Row(
            children: [
              // Round
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: AppColors.softShadow,
                ),
                child: Text(
                  'Round $currentRound/3',
                  style: const TextStyle(
                    color: AppColors.brainPurple,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              // Timer centré
              SizedBox(
                width: 52,
                height: 52,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 4,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(timerColor),
                    ),
                    Center(
                      child: Text(
                        '${_secondsRemaining}s',
                        style: TextStyle(
                          color: timerColor,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // Score du round
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: _scoreJustIncreased
                      ? AppColors.success.withValues(alpha: 0.15)
                      : _scoreJustDecreased
                          ? AppColors.error.withValues(alpha: 0.15)
                          : AppColors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: scoreColor.withValues(alpha: 0.4), width: 2),
                  boxShadow: AppColors.softShadow,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _scoreJustDecreased ? Icons.trending_down : Icons.star,
                      color: scoreColor,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (child, animation) => ScaleTransition(
                        scale: animation,
                        child: child,
                      ),
                      child: Text(
                        '$_displayedScore pts',
                        key: ValueKey<int>(_displayedScore),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: scoreColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(QuestionModel question, AppLocalizations l10n) {
    final difficultyColor = _getDifficultyColor(question.difficulty);
    final difficultyLabel =
        _getDifficultyLabel(question.difficulty, l10n);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
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
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: difficultyColor.withValues(alpha:0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: difficultyColor.withValues(alpha:0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.signal_cellular_alt,
                          color: difficultyColor, size: 16),
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
                          color: difficultyColor.withValues(alpha:0.8),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
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
          ...question.answers.map((answer) {
            return AnimatedOpacity(
              opacity: _answersVisible ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: MouseRegion(
                  cursor: _answersVisible
                      ? SystemMouseCursors.click
                      : SystemMouseCursors.basic,
                  child: GestureDetector(
                    onTap: _answersVisible
                        ? () => _selectAnswer(
                            question, answer.id, answer.isCorrect)
                        : null,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: Colors.grey.shade300, width: 2),
                        boxShadow: AppColors.softShadow,
                      ),
                      child: Text(
                        answer.text,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
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

  // ===================== ROUND END =====================

  Widget _buildRoundEndScreen(
      PvPProvider pvpProvider, AppLocalizations l10n) {
    final currentRound = pvpProvider.currentRound;
    final isRoundComplete = currentRound?.isRoundCompleted ?? false;
    final myRoundScore = pvpProvider.myRoundScore;
    final answeredCount = pvpProvider.myAnswers.length;

    final isPlayer1 = pvpProvider.isPlayer1;
    final opponentFinished = isPlayer1
        ? currentRound?.isPlayer2Completed ?? false
        : currentRound?.isPlayer1Completed ?? false;

    if (!isRoundComplete) {
      // Waiting for opponent to finish
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
              gradient: AppColors.backgroundGradient),
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
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: 1.0 +
                              (_pulseController.value * 0.1),
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppColors.brainPurple
                                  .withValues(alpha:0.1),
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
                    const SizedBox(height: 8),
                    Text(
                      '$answeredCount ${l10n.questionsAnswered}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
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
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back),
                        label: Text(l10n.backToMenu),
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

    return _buildRoundResultsScreen(pvpProvider, l10n);
  }

  Widget _buildRoundResultsScreen(
      PvPProvider pvpProvider, AppLocalizations l10n) {
    final currentRound = pvpProvider.currentRound;
    final isPlayer1 = pvpProvider.isPlayer1;

    final myScore = isPlayer1
        ? currentRound?.player1Score ?? 0
        : currentRound?.player2Score ?? 0;
    final opponentScore = isPlayer1
        ? currentRound?.player2Score ?? 0
        : currentRound?.player1Score ?? 0;

    final roundNumber = currentRound?.roundNumber ?? 1;
    final isLastRound = roundNumber >= 3;

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

    // For the last round, show final results dialog
    if (isLastRound && !_hasShownFinalResults) {
      _hasShownFinalResults = true;
      Future.delayed(const Duration(seconds: 2), () {
        if (!mounted) return;
        _showFinalResultsDialog(pvpProvider, l10n);
      });
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
            gradient: AppColors.backgroundGradient),
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
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: resultColor.withValues(alpha:0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(resultIcon,
                        color: resultColor, size: 48),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildScoreColumn(
                          l10n.you, myScore, AppColors.brainPurple),
                      Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 24),
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
                      _buildScoreColumn(
                          l10n.opponent, opponentScore, Colors.grey),
                    ],
                  ),
                  const SizedBox(height: 32),
                  if (isLastRound) ...[
                    Text(
                      l10n.finalResultsComing,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ] else ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back),
                        label: Text(l10n.backToMenu),
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
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 8),
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: color.withValues(alpha:0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha:0.3)),
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

  // ===================== FINAL RESULTS =====================

  void _showFinalResultsDialog(
      PvPProvider pvpProvider, AppLocalizations l10n) {
    final currentMatch = pvpProvider.currentMatch;
    if (currentMatch == null) return;

    final didWin = pvpProvider.didWin;
    final myScore = pvpProvider.myTotalScore;
    final opponentScore = pvpProvider.opponentTotalScore;
    final ratingChange = pvpProvider.myRatingChange ?? 0;

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
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24)),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
                            resultColor.withValues(alpha:0.3),
                            resultColor.withValues(alpha:0.1),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: resultColor.withValues(alpha:0.3),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Icon(resultIcon,
                          color: resultColor, size: 64),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
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
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Flexible(
                      child: Column(
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
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: AppColors.brainPurple,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Text(
                      '-',
                      style: TextStyle(
                        fontSize: 28,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Flexible(
                      child: Column(
                        children: [
                          Text(
                            l10n.opponent,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '$opponentScore',
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: ratingChange >= 0
                      ? AppColors.success.withValues(alpha:0.1)
                      : AppColors.error.withValues(alpha:0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: ratingChange >= 0
                        ? AppColors.success.withValues(alpha:0.3)
                        : AppColors.error.withValues(alpha:0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      ratingChange >= 0
                          ? Icons.trending_up
                          : Icons.trending_down,
                      color: ratingChange >= 0
                          ? AppColors.success
                          : AppColors.error,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        '${ratingChange >= 0 ? '+' : ''}$ratingChange ${l10n.rating}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: ratingChange >= 0
                              ? AppColors.success
                              : AppColors.error,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
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
