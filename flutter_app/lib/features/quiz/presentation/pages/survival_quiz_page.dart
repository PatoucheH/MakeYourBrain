import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/repositories/quiz_repository.dart';
import '../../data/models/theme_model.dart';
import '../../data/models/question_model.dart';
import '../../../auth/data/repositories/auth_repository.dart';
import '../../../profile/data/repositories/profile_repository.dart';
import '../../../auth/providers/user_stats_provider.dart';
import '../../../lives/data/providers/lives_provider.dart';
import '../../../achievements/presentation/widgets/achievement_unlock_overlay.dart';
import 'survival_leaderboard_page.dart';

class SurvivalQuizPage extends StatefulWidget {
  final ThemeModel theme;

  const SurvivalQuizPage({super.key, required this.theme});

  @override
  State<SurvivalQuizPage> createState() => _SurvivalQuizPageState();
}

class _SurvivalQuizPageState extends State<SurvivalQuizPage> {
  static const int _maxErrors = 3;
  static const int _batchSize = 10;
  static const int _xpPerCorrect = 5;

  final _repository = QuizRepository();
  final _authRepo = AuthRepository();

  final List<QuestionModel> _questions = [];
  final Set<String> _shownIds = {};
  int _currentIndex = 0;
  int _score = 0;
  int _errors = 0;
  bool _isLoading = true;
  bool _isFetchingNext = false;
  bool _hasAnswered = false;
  String? _selectedAnswerId;
  bool _gameOver = false;
  int? _personalBest;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await Future.wait([_loadPersonalBest(), _loadBatch()]);
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadPersonalBest() async {
    final userId = _authRepo.getCurrentUserId();
    if (userId == null) return;
    _personalBest = await _repository.getUserBestSurvivalScore(
      userId: userId,
      themeId: widget.theme.id,
    );
  }

  Map<String, int> _difficultyForScore(int score) {
    if (score < 5) return {'easy': 100, 'medium': 0, 'hard': 0};
    if (score < 10) return {'easy': 50, 'medium': 50, 'hard': 0};
    if (score < 15) return {'easy': 20, 'medium': 60, 'hard': 20};
    if (score < 20) return {'easy': 0, 'medium': 60, 'hard': 40};
    return {'easy': 0, 'medium': 30, 'hard': 70};
  }

  Future<void> _loadBatch() async {
    if (_isFetchingNext) return;
    _isFetchingNext = true;
    try {
      final lang = context.read<LanguageProvider>().currentLanguage;
      final diff = _difficultyForScore(_score);
      final batch = await _repository.getQuestions(
        themeId: widget.theme.id,
        languageCode: lang,
        limit: _batchSize,
        easyPercent: diff['easy']!,
        mediumPercent: diff['medium']!,
        hardPercent: diff['hard']!,
        userId: _authRepo.getCurrentUserId(),
      );
      final fresh = batch.where((q) => !_shownIds.contains(q.id)).toList();
      final toAdd = fresh.isNotEmpty ? fresh : batch;
      if (mounted) {
        setState(() {
          for (final q in toAdd) {
            _shownIds.add(q.id);
          }
          _questions.addAll(toAdd);
        });
      }
    } catch (e) {
      debugPrint('Survival load batch error: $e');
    } finally {
      _isFetchingNext = false;
    }
  }

  Future<void> _selectAnswer(
      String answerId, bool isCorrect, String questionId) async {
    if (_hasAnswered || _gameOver) return;

    setState(() {
      _selectedAnswerId = answerId;
      _hasAnswered = true;
      if (isCorrect) _score++;
    });

    final lang = context.read<LanguageProvider>().currentLanguage;
    final userId = _authRepo.getCurrentUserId();
    if (userId != null) {
      try {
        await _repository.saveUserAnswer(
          userId: userId,
          questionId: questionId,
          selectedAnswerId: answerId,
          isCorrect: isCorrect,
          languageUsed: lang,
        );
      } catch (e) {
        debugPrint('Survival save answer error: $e');
      }
    }

    if (!isCorrect && mounted) {
      final livesProvider = context.read<LivesProvider>();
      await livesProvider.useLife();
      if (mounted) setState(() => _errors++);
    }

    if (mounted) _showAnswerDialog(isCorrect);
  }

  void _showAnswerDialog(bool isCorrect) {
    final l10n = AppLocalizations.of(context)!;
    final question = _questions[_currentIndex];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => Dialog(
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
                if (!isCorrect) ...[
                  const SizedBox(height: 12),
                  Text(
                    '${_errors}/$_maxErrors ${l10n.survivalMistakes}',
                    style: TextStyle(
                      color: AppColors.error,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                if (question.explanation != null) ...[
                  _ExplanationToggle(
                    explanation: question.explanation!,
                    isCorrect: isCorrect,
                    label: l10n.explanation,
                  ),
                  const SizedBox(height: 20),
                ],
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.of(dialogCtx).pop();
                      await _onContinue();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isCorrect ? AppColors.success : AppColors.error,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      l10n.continueButton,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
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

  Future<void> _onContinue() async {
    if (_gameOver) return;

    final livesProvider = context.read<LivesProvider>();
    final isGameOver =
        _errors >= _maxErrors || livesProvider.currentLives <= 0;

    if (isGameOver) {
      await _handleGameOver();
      return;
    }

    // Preload next batch when nearing the end
    if (_currentIndex >= _questions.length - 3 && !_isFetchingNext) {
      _loadBatch();
    }

    if (mounted) {
      setState(() {
        _currentIndex++;
        _hasAnswered = false;
        _selectedAnswerId = null;
      });
    }
  }

  Future<void> _handleGameOver() async {
    if (_gameOver) return;
    if (mounted) setState(() => _gameOver = true);

    final userId = _authRepo.getCurrentUserId();
    bool isNewRecord = false;

    if (userId != null) {
      try {
        await _repository.saveSurvivalScore(
          userId: userId,
          themeId: widget.theme.id,
          score: _score,
        );
        final xp = _score * _xpPerCorrect;
        if (xp > 0) {
          await _repository.addSurvivalXp(
            userId: userId,
            themeId: widget.theme.id,
            xp: xp,
          );
        }
        await ProfileRepository().updateStreak(userId);
        if (mounted) context.read<UserStatsProvider>().loadFromServer();
        isNewRecord = _personalBest == null || _score > _personalBest!;
      } catch (e) {
        debugPrint('Survival game over save error: $e');
      }
    }

    if (!mounted) return;
    final lang = context.read<LanguageProvider>().currentLanguage;
    if (userId != null) {
      await AchievementUnlockOverlay.checkAndShow(context, userId, lang);
    }
    if (!mounted) return;
    _showGameOverDialog(isNewRecord);
  }

  void _showGameOverDialog(bool isNewRecord) {
    final l10n = AppLocalizations.of(context)!;
    final xpEarned = _score * _xpPerCorrect;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
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
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFD32F2F), Color(0xFFFF5722)],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Image.asset(
                      'assets/branding/mascot/brainly_fail.png',
                      height: 80),
                ),
                const SizedBox(height: 20),
                Text(
                  l10n.survivalGameOver,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFD32F2F),
                  ),
                ),
                if (isNewRecord) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      l10n.newRecord,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatChip(
                      Icons.check_circle_outline,
                      AppColors.success,
                      '$_score',
                      l10n.score,
                    ),
                    _buildStatChip(
                      Icons.cancel_outlined,
                      AppColors.error,
                      '$_errors',
                      l10n.survivalMistakes,
                    ),
                    _buildStatChip(
                      Icons.star_rounded,
                      const Color(0xFF1B8A3C),
                      '+$xpEarned',
                      l10n.xp,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Leaderboard button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(dialogCtx).pop();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SurvivalLeaderboardPage(
                            theme: widget.theme,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.leaderboard,
                        color: Color(0xFFFFD700)),
                    label: Text(l10n.survivalLeaderboard),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(
                          color: Color(0xFFFFD700), width: 2),
                      foregroundColor: AppColors.textPrimaryOf(context),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(dialogCtx).pop();
                          Navigator.of(context).pop();
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(
                            color: AppColors.textSecondaryOf(context),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(l10n.backToThemes,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: AppColors.textSecondaryOf(context))),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: const LinearGradient(
                            colors: [Color(0xFFD32F2F), Color(0xFFFF5722)],
                          ),
                        ),
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(dialogCtx).pop();
                            _resetAndRestart();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text(
                            l10n.playAgain,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
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

  void _resetAndRestart() {
    setState(() {
      _questions.clear();
      _shownIds.clear();
      _currentIndex = 0;
      _score = 0;
      _errors = 0;
      _isLoading = true;
      _isFetchingNext = false;
      _hasAnswered = false;
      _selectedAnswerId = null;
      _gameOver = false;
    });
    _init();
  }

  Widget _buildStatChip(
      IconData icon, Color color, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimaryOf(context),
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondaryOf(context),
          ),
        ),
      ],
    );
  }

  Color _difficultyColor(String difficulty) {
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (_isLoading || _questions.isEmpty) {
      return Scaffold(
        body: Container(
          decoration:
              BoxDecoration(gradient: AppColors.backgroundGradientOf(context)),
          child: const Center(
            child: CircularProgressIndicator(color: Color(0xFFD32F2F)),
          ),
        ),
      );
    }

    // Wait for next batch if we've exhausted loaded questions
    if (_currentIndex >= _questions.length) {
      return Scaffold(
        body: Container(
          decoration:
              BoxDecoration(gradient: AppColors.backgroundGradientOf(context)),
          child: const Center(
            child: CircularProgressIndicator(color: Color(0xFFD32F2F)),
          ),
        ),
      );
    }

    final question = _questions[_currentIndex];

    return Scaffold(
      body: Container(
        decoration:
            BoxDecoration(gradient: AppColors.backgroundGradientOf(context)),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(l10n),
              // Lives + score bar
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    // Hearts (survival lives)
                    Row(
                      children: List.generate(
                        _maxErrors,
                        (i) => Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Icon(
                            i < (_maxErrors - _errors)
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: i < (_maxErrors - _errors)
                                ? const Color(0xFFD32F2F)
                                : AppColors.textSecondaryOf(context),
                            size: 28,
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFD32F2F), Color(0xFFFF5722)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${l10n.score}: $_score',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // Question + answers
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Difficulty badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: _difficultyColor(question.difficulty)
                              .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _difficultyColor(question.difficulty)
                                .withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              question.difficulty.toUpperCase(),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color:
                                    _difficultyColor(question.difficulty),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Question card
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppColors.cardColorOf(context),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: AppColors.cardShadow,
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.bolt,
                                size: 40, color: Color(0xFFD32F2F)),
                            const SizedBox(height: 16),
                            Text(
                              question.questionText,
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
                      // Answers
                      ...question.answers.map((answer) {
                        final isSelected = _selectedAnswerId == answer.id;
                        final showCorrect =
                            _hasAnswered && answer.isCorrect;
                        final showWrong = _hasAnswered &&
                            isSelected &&
                            !answer.isCorrect;

                        Color bgColor = AppColors.cardColorOf(context);
                        Color borderColor =
                            const Color(0xFFD32F2F).withValues(alpha: 0.2);
                        Color textColor =
                            AppColors.textPrimaryOf(context);

                        if (showCorrect) {
                          bgColor = AppColors.successLight;
                          borderColor = AppColors.success;
                          textColor = AppColors.success;
                        } else if (showWrong) {
                          bgColor = AppColors.errorLight;
                          borderColor = AppColors.error;
                          textColor = AppColors.error;
                        } else if (isSelected) {
                          borderColor = const Color(0xFFD32F2F);
                        }

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: MouseRegion(
                            cursor: _hasAnswered
                                ? SystemMouseCursors.basic
                                : SystemMouseCursors.click,
                            child: GestureDetector(
                              onTap: _hasAnswered
                                  ? null
                                  : () => _selectAnswer(answer.id,
                                      answer.isCorrect, question.id),
                              child: AnimatedContainer(
                                duration:
                                    const Duration(milliseconds: 200),
                                padding: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                  color: bgColor,
                                  borderRadius:
                                      BorderRadius.circular(16),
                                  border: Border.all(
                                      color: borderColor, width: 2),
                                  boxShadow: isSelected && !_hasAnswered
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
                                      const Icon(Icons.check_circle,
                                          color: AppColors.success),
                                    if (showWrong)
                                      const Icon(Icons.cancel,
                                          color: AppColors.error),
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

  Widget _buildAppBar(AppLocalizations l10n) {
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
                  color: AppColors.cardColorOf(context),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: AppColors.softShadow,
                ),
                child: const Icon(Icons.arrow_back,
                    color: Color(0xFFD32F2F), size: 22),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color:
                        const Color(0xFFD32F2F).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    l10n.survivalMode.toUpperCase(),
                    style: const TextStyle(
                      color: Color(0xFFD32F2F),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  widget.theme.name,
                  style: const TextStyle(
                    color: Color(0xFFD32F2F),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Question counter
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.cardColorOf(context),
              borderRadius: BorderRadius.circular(20),
              boxShadow: AppColors.softShadow,
            ),
            child: Text(
              'Q${_currentIndex + 1}',
              style: const TextStyle(
                color: Color(0xFFD32F2F),
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
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
  static const int _previewLength = 80;
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.isCorrect ? AppColors.success : AppColors.error;
    final isLong = widget.explanation.length > _previewLength;
    final preview = isLong
        ? '${widget.explanation.substring(0, _previewLength).trimRight()}...'
        : widget.explanation;

    return GestureDetector(
      onTap: isLong ? () => setState(() => _expanded = !_expanded) : null,
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lightbulb_outline, size: 16, color: color),
                const SizedBox(width: 6),
                Text(
                  widget.label,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _expanded ? widget.explanation : preview,
              style: TextStyle(
                  fontSize: 14, color: AppColors.textPrimaryOf(context)),
            ),
            if (isLong)
              Align(
                alignment: Alignment.centerRight,
                child: Icon(
                  _expanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  size: 20,
                  color: color,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
