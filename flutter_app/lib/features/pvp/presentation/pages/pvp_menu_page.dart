import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/data/repositories/auth_repository.dart';
import '../../data/models/pvp_match_model.dart';
import '../../data/providers/pvp_provider.dart';
import '../../data/repositories/pvp_repository.dart';
import 'pvp_game_page.dart';

class PvPMenuPage extends StatefulWidget {
  const PvPMenuPage({super.key});

  @override
  State<PvPMenuPage> createState() => _PvPMenuPageState();
}

class _PvPMenuPageState extends State<PvPMenuPage> {
  final _authRepo = AuthRepository();
  final _pvpRepo = PvPRepository();

  bool isLoading = true;
  int rating = 1000;
  int wins = 0;
  int losses = 0;
  int draws = 0;
  List<PvPMatchModel> matchHistory = [];

  @override
  void initState() {
    super.initState();
    _loadData();
    // Écouter les changements du provider pour la navigation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final pvpProvider = context.read<PvPProvider>();
      pvpProvider.addListener(_onProviderChanged);
    });
  }

  void _onProviderChanged() {
    if (!mounted) return;
    final pvpProvider = context.read<PvPProvider>();
    // Si le match est prêt à être joué, naviguer
    if (pvpProvider.isReadyToPlay && pvpProvider.currentMatch != null) {
      pvpProvider.clearReadyToPlay(); // Éviter les navigations multiples
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const PvPGamePage()),
      );
    }
  }

  @override
  void dispose() {
    // Retirer le listener
    try {
      context.read<PvPProvider>().removeListener(_onProviderChanged);
    } catch (_) {}
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final userId = _authRepo.getCurrentUserId();
      if (userId == null) return;

      // Load stats and match history in parallel
      final results = await Future.wait([
        _pvpRepo.getPlayerPvPStats(userId),
        _pvpRepo.getMyMatches(userId, limit: 10),
      ]);

      final stats = results[0] as Map<String, dynamic>;
      final history = results[1] as List<PvPMatchModel>;

      setState(() {
        rating = stats['rating'] ?? 1000;
        wins = stats['wins'] ?? 0;
        losses = stats['losses'] ?? 0;
        draws = stats['draws'] ?? 0;
        matchHistory = history;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading PvP data: $e');
      setState(() => isLoading = false);
    }
  }

  int get totalGames => wins + losses + draws;

  double get winRate {
    if (totalGames == 0) return 0;
    return (wins / totalGames) * 100;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  // Custom AppBar
                  _buildAppBar(l10n),

                  // Content
                  Expanded(
                    child: isLoading
                        ? const Center(
                            child: CircularProgressIndicator(color: AppColors.brainPurple),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadData,
                            color: AppColors.brainPurple,
                            child: SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Stats Card
                                  _buildStatsCard(l10n),
                                  const SizedBox(height: 24),

                                  // Find Match Button
                                  _buildFindMatchButton(l10n),
                                  const SizedBox(height: 32),

                                  // Match History Section
                                  _buildMatchHistorySection(l10n),
                                ],
                              ),
                            ),
                          ),
                  ),
                ],
              ),
              // Matchmaking Overlay
              _buildMatchmakingOverlay(l10n),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMatchmakingOverlay(AppLocalizations l10n) {
    return Consumer<PvPProvider>(
      builder: (context, pvpProvider, child) {
        final isInQueue = pvpProvider.isInQueue;
        final matchFound = pvpProvider.matchFound;
        final searchDuration = pvpProvider.searchDuration;
        final countdown = pvpProvider.matchFoundCountdown;

        // Ne pas afficher si pas en recherche et pas de match trouvé
        if (!isInQueue && !matchFound) {
          return const SizedBox.shrink();
        }

        return Positioned(
          top: 60,
          right: 16,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: matchFound
                ? _buildMatchFoundPopup(l10n, countdown, pvpProvider)
                : _buildSearchingPopup(l10n, searchDuration, pvpProvider),
          ),
        );
      },
    );
  }

  Widget _buildSearchingPopup(AppLocalizations l10n, int searchDuration, PvPProvider pvpProvider) {
    final minutes = searchDuration ~/ 60;
    final seconds = searchDuration % 60;
    final timeStr = minutes > 0
        ? '${minutes}m ${seconds.toString().padLeft(2, '0')}s'
        : '${seconds}s';

    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 280,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.brainPurple.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                // Icône animée
                SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.brainPurple,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.searchingOpponent,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        timeStr,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.brainPurple,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Bouton annuler
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => pvpProvider.leaveMatchmaking(),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  backgroundColor: AppColors.error.withOpacity(0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.close, color: AppColors.error, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      l10n.cancel,
                      style: const TextStyle(
                        color: AppColors.error,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchFoundPopup(AppLocalizations l10n, int countdown, PvPProvider pvpProvider) {
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 280,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF10B981), Color(0xFF059669)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.matchFound,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.matchStartingIn(countdown),
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Barre de progression
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: countdown / 5,
                minHeight: 6,
                backgroundColor: Colors.white.withOpacity(0.3),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ],
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
              l10n.pvpArena,
              style: const TextStyle(
                color: AppColors.brainPurple,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Rating Display
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.emoji_events,
              color: Colors.white,
              size: 48,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.rating,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            rating.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 48,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),

          // W/L/D Stats Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatItem(l10n.wins, wins.toString(), AppColors.success),
                _buildStatDivider(),
                _buildStatItem(l10n.losses, losses.toString(), AppColors.error),
                _buildStatDivider(),
                _buildStatItem(l10n.draws, draws.toString(), Colors.grey),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Win Rate
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.trending_up, color: AppColors.success, size: 20),
                const SizedBox(width: 8),
                Text(
                  '${l10n.winRate}: ${winRate.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    color: Color(0xFF6366F1),
                    fontSize: 16,
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

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildStatDivider() {
    return Container(
      height: 40,
      width: 1,
      color: Colors.white.withOpacity(0.3),
    );
  }

  Widget _buildFindMatchButton(AppLocalizations l10n) {
    return Consumer<PvPProvider>(
      builder: (context, pvpProvider, child) {
        final isSearching = pvpProvider.isSearchingMatch || pvpProvider.isInQueue || pvpProvider.matchFound;

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: isSearching
                ? LinearGradient(
                    colors: [Colors.grey.shade400, Colors.grey.shade500],
                  )
                : AppColors.primaryGradient,
            boxShadow: isSearching ? null : AppColors.buttonShadow,
          ),
          child: ElevatedButton(
            onPressed: isSearching
                ? null
                : () => _startMatchmaking(context, pvpProvider),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              padding: const EdgeInsets.all(20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isSearching)
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                else
                  const Icon(Icons.sports_esports, size: 28, color: Colors.white),
                const SizedBox(width: 12),
                Text(
                  isSearching ? l10n.searchingMatch : l10n.findMatch,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _startMatchmaking(BuildContext context, PvPProvider pvpProvider) async {
    await pvpProvider.joinMatchmaking();
  }

  Widget _buildMatchHistorySection(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.brainPurpleLight.withOpacity(0.3),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.history,
                color: AppColors.brainPurple,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              l10n.matchHistory,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        if (matchHistory.isEmpty)
          _buildEmptyHistoryCard(l10n)
        else
          ...matchHistory.map((match) => _buildMatchHistoryItem(match, l10n)),
      ],
    );
  }

  Widget _buildEmptyHistoryCard(AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        children: [
          Icon(
            Icons.sports_esports_outlined,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 12),
          Text(
            l10n.noMatchesYet,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.startFirstMatch,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchHistoryItem(PvPMatchModel match, AppLocalizations l10n) {
    final userId = _authRepo.getCurrentUserId();
    final isWinner = match.winnerId == userId;
    final isDraw = match.winnerId == null && match.isCompleted;
    final isLoss = !isWinner && !isDraw && match.isCompleted;

    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (match.isCompleted) {
      if (isDraw) {
        statusColor = Colors.grey;
        statusText = l10n.draw;
        statusIcon = Icons.handshake;
      } else if (isWinner) {
        statusColor = AppColors.success;
        statusText = l10n.victory;
        statusIcon = Icons.emoji_events;
      } else {
        statusColor = AppColors.error;
        statusText = l10n.defeat;
        statusIcon = Icons.sentiment_dissatisfied;
      }
    } else if (match.isCancelled) {
      statusColor = Colors.grey;
      statusText = l10n.cancelled;
      statusIcon = Icons.cancel;
    } else {
      statusColor = AppColors.warning;
      statusText = l10n.inProgress;
      statusIcon = Icons.play_arrow;
    }

    final myScore = match.getPlayerScore(userId ?? '');
    final opponentScore = userId == match.player1Id
        ? match.player2TotalScore
        : match.player1TotalScore;
    final ratingChange = match.getPlayerRatingChange(userId ?? '');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.cardShadow,
        border: Border.all(
          color: statusColor.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          // Status Icon
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(statusIcon, color: statusColor, size: 24),
          ),
          const SizedBox(width: 16),

          // Match Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
                const SizedBox(height: 4),
                if (match.isCompleted)
                  Text(
                    '${l10n.score}: $myScore - $opponentScore',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                Text(
                  _formatDate(match.createdAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),

          // Rating Change
          if (ratingChange != null && match.isCompleted)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: ratingChange >= 0
                    ? AppColors.success.withOpacity(0.15)
                    : AppColors.error.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${ratingChange >= 0 ? '+' : ''}$ratingChange',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: ratingChange >= 0 ? AppColors.success : AppColors.error,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
