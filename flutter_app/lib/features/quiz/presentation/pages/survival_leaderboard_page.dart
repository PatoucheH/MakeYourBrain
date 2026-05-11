import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/brain_app_bar.dart';
import '../../data/models/theme_model.dart';
import '../../data/repositories/quiz_repository.dart';
import '../../../auth/data/repositories/auth_repository.dart';
import '../../../social/presentation/widgets/clickable_username.dart';

class SurvivalLeaderboardPage extends StatefulWidget {
  final ThemeModel theme;

  const SurvivalLeaderboardPage({super.key, required this.theme});

  @override
  State<SurvivalLeaderboardPage> createState() =>
      _SurvivalLeaderboardPageState();
}

class _SurvivalLeaderboardPageState extends State<SurvivalLeaderboardPage> {
  final _repository = QuizRepository();
  final _authRepo = AuthRepository();

  List<Map<String, dynamic>> _entries = [];
  bool _isLoading = true;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _currentUserId = _authRepo.getCurrentUserId();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await _repository.getSurvivalLeaderboard(
        themeId: widget.theme.id,
      );
      if (mounted) setState(() { _entries = data; _isLoading = false; });
    } catch (e) {
      debugPrint('Survival leaderboard load error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: Container(
        decoration:
            BoxDecoration(gradient: AppColors.backgroundGradientOf(context)),
        child: SafeArea(
          child: Column(
            children: [
              const BrainAppBar(),
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFD32F2F), Color(0xFFFF5722)],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.bolt,
                          color: Colors.white, size: 32),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.survivalLeaderboard,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimaryOf(context),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.theme.name,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondaryOf(context),
                      ),
                    ),
                  ],
                ),
              ),
              // List
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                            color: Color(0xFFD32F2F)),
                      )
                    : _entries.isEmpty
                        ? Center(
                            child: Text(
                              l10n.noSurvivalScoresYet,
                              style: TextStyle(
                                color: AppColors.textSecondaryOf(context),
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: _entries.length,
                            itemBuilder: (context, index) {
                              final entry = _entries[index];
                              final rank =
                                  (entry['rank'] as num?)?.toInt() ?? index + 1;
                              final userId =
                                  entry['user_id']?.toString() ?? '';
                              final username =
                                  entry['username']?.toString() ?? 'User';
                              final score =
                                  (entry['best_score'] as num?)?.toInt() ?? 0;
                              final isMe = userId == _currentUserId;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 14),
                                decoration: BoxDecoration(
                                  color: isMe
                                      ? const Color(0xFFD32F2F)
                                          .withValues(alpha: 0.1)
                                      : AppColors.cardColorOf(context),
                                  borderRadius: BorderRadius.circular(16),
                                  border: isMe
                                      ? Border.all(
                                          color: const Color(0xFFD32F2F)
                                              .withValues(alpha: 0.4),
                                          width: 2,
                                        )
                                      : null,
                                  boxShadow: AppColors.softShadow,
                                ),
                                child: Row(
                                  children: [
                                    // Rank
                                    SizedBox(
                                      width: 36,
                                      child: rank <= 3
                                          ? Text(
                                              rank == 1
                                                  ? '🥇'
                                                  : rank == 2
                                                      ? '🥈'
                                                      : '🥉',
                                              style: const TextStyle(
                                                  fontSize: 22),
                                              textAlign: TextAlign.center,
                                            )
                                          : Text(
                                              '#$rank',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: AppColors
                                                    .textSecondaryOf(context),
                                                fontSize: 14,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                    ),
                                    const SizedBox(width: 12),
                                    // Username
                                    Expanded(
                                      child: ClickableUsername(
                                        userId: userId,
                                        displayName: username,
                                        style: TextStyle(
                                          fontWeight: isMe
                                              ? FontWeight.bold
                                              : FontWeight.w500,
                                          color: isMe
                                              ? const Color(0xFFD32F2F)
                                              : AppColors.textPrimaryOf(
                                                  context),
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                    // Score
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        gradient: isMe
                                            ? const LinearGradient(
                                                colors: [
                                                  Color(0xFFD32F2F),
                                                  Color(0xFFFF5722)
                                                ],
                                              )
                                            : null,
                                        color: isMe
                                            ? null
                                            : AppColors.innerCardColorOf(
                                                context),
                                        borderRadius:
                                            BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        '$score',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: isMe
                                              ? Colors.white
                                              : AppColors.textPrimaryOf(
                                                  context),
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ],
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
