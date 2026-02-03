import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/brain_app_bar.dart';
import '../../../auth/data/repositories/auth_repository.dart';
import '../../data/repositories/pvp_repository.dart';
import '../../../social/data/repositories/follow_repository.dart';
import '../../../social/presentation/widgets/clickable_username.dart';

class PvPLeaderboardPage extends StatefulWidget {
  const PvPLeaderboardPage({super.key});

  @override
  State<PvPLeaderboardPage> createState() => _PvPLeaderboardPageState();
}

class _PvPLeaderboardPageState extends State<PvPLeaderboardPage> {
  final _pvpRepo = PvPRepository();
  final _authRepo = AuthRepository();
  final _followRepo = FollowRepository();

  List<Map<String, dynamic>> leaderboard = [];
  List<Map<String, dynamic>> followingLeaderboard = [];
  bool isLoading = true;
  int? myRank;
  int? myFollowingRank;
  bool showFollowingOnly = false;

  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
  }

  Future<void> _loadLeaderboard() async {
    try {
      final data = await _pvpRepo.getPvPLeaderboard(limit: 100);
      final followingData = await _followRepo.getPvPFollowingLeaderboard();
      final userId = _authRepo.getCurrentUserId();

      int? rank;
      int? followRank;
      if (userId != null) {
        final index = data.indexWhere((item) => item['user_id'] == userId);
        if (index >= 0) rank = index + 1;

        final followIndex = followingData.indexWhere((item) => item['user_id'] == userId);
        if (followIndex >= 0) followRank = followIndex + 1;
      }

      setState(() {
        leaderboard = data;
        followingLeaderboard = followingData;
        myRank = rank;
        myFollowingRank = followRank;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Color _getMedalColor(int rank) {
    switch (rank) {
      case 1:
        return const Color(0xFFFFD700);
      case 2:
        return const Color(0xFFC0C0C0);
      case 3:
        return const Color(0xFFCD7F32);
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final userId = _authRepo.getCurrentUserId();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              // AppBar
              const BrainAppBar(),

              // Following filter
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    FilterChip(
                      label: Text(l10n.global),
                      selected: !showFollowingOnly,
                      onSelected: (_) => setState(() => showFollowingOnly = false),
                      selectedColor: AppColors.brainPurpleLight,
                      checkmarkColor: AppColors.brainPurple,
                      labelStyle: TextStyle(
                        color: !showFollowingOnly ? AppColors.brainPurple : AppColors.textSecondary,
                        fontWeight: !showFollowingOnly ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: Text(l10n.followingLeaderboard),
                      selected: showFollowingOnly,
                      onSelected: (_) => setState(() => showFollowingOnly = true),
                      selectedColor: AppColors.brainPurpleLight,
                      checkmarkColor: AppColors.brainPurple,
                      labelStyle: TextStyle(
                        color: showFollowingOnly ? AppColors.brainPurple : AppColors.textSecondary,
                        fontWeight: showFollowingOnly ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),

              // My rank card
              if (!isLoading && (showFollowingOnly ? myFollowingRank : myRank) != null)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: AppColors.buttonShadow,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.person, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        children: [
                          Text(
                            l10n.yourGlobalRank,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                          Text(
                            '#${showFollowingOnly ? myFollowingRank : myRank}',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

              // List
              Expanded(
                child: isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: AppColors.brainPurple),
                      )
                    : (showFollowingOnly ? followingLeaderboard : leaderboard).isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Image.asset(
                                  'assets/branding/mascot/brainly_thinking.png',
                                  height: 80,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  l10n.noMatchesYet,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadLeaderboard,
                            color: AppColors.brainPurple,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: (showFollowingOnly ? followingLeaderboard : leaderboard).length,
                              itemBuilder: (context, index) {
                                final item = (showFollowingOnly ? followingLeaderboard : leaderboard)[index];
                                final rank = index + 1;
                                final isMe = item['user_id'] == userId;
                                final rating = item['pvp_rating'] ?? 1000;
                                final wins = item['pvp_wins'] ?? 0;
                                final losses = item['pvp_losses'] ?? 0;
                                final username = item['username'];
                                final displayName = (username != null && username.toString().isNotEmpty)
                                    ? username.toString()
                                    : (item['email'] ?? 'Unknown').toString().split('@').first;

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  decoration: BoxDecoration(
                                    color: isMe
                                        ? AppColors.brainPurpleLight.withOpacity(0.3)
                                        : AppColors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: isMe
                                        ? Border.all(color: AppColors.brainPurple, width: 2)
                                        : null,
                                    boxShadow: AppColors.cardShadow,
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(14),
                                    child: Row(
                                      children: [
                                        // Rank
                                        Container(
                                          width: 44,
                                          height: 44,
                                          decoration: BoxDecoration(
                                            gradient: rank <= 3
                                                ? LinearGradient(
                                                    colors: [
                                                      _getMedalColor(rank),
                                                      _getMedalColor(rank).withOpacity(0.7),
                                                    ],
                                                  )
                                                : null,
                                            color: rank > 3 ? Colors.grey.shade100 : null,
                                            shape: BoxShape.circle,
                                            boxShadow: rank <= 3
                                                ? [
                                                    BoxShadow(
                                                      color: _getMedalColor(rank).withOpacity(0.4),
                                                      blurRadius: 8,
                                                      offset: const Offset(0, 2),
                                                    ),
                                                  ]
                                                : null,
                                          ),
                                          child: Center(
                                            child: rank <= 3
                                                ? const Icon(Icons.emoji_events,
                                                    color: Colors.white, size: 22)
                                                : Text(
                                                    '#$rank',
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 13,
                                                      color: AppColors.textSecondary,
                                                    ),
                                                  ),
                                          ),
                                        ),
                                        const SizedBox(width: 14),

                                        // Name + W/L
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              ClickableUsername(
                                                userId: item['user_id'] ?? '',
                                                displayName: displayName,
                                                style: TextStyle(
                                                  fontWeight: isMe
                                                      ? FontWeight.bold
                                                      : FontWeight.w600,
                                                  fontSize: 15,
                                                  color: isMe
                                                      ? AppColors.brainPurple
                                                      : AppColors.textPrimary,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  Text(
                                                    '${l10n.wins}: $wins',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: AppColors.success,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    '${l10n.losses}: $losses',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: AppColors.error,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),

                                        // Rating
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 14, vertical: 8),
                                          decoration: BoxDecoration(
                                            gradient: isMe
                                                ? AppColors.primaryGradient
                                                : const LinearGradient(
                                                    colors: [
                                                      Color(0xFFFFD700),
                                                      Color(0xFFFFA500)
                                                    ],
                                                  ),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.emoji_events,
                                                  color: Colors.white, size: 16),
                                              const SizedBox(width: 4),
                                              Text(
                                                '$rating',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                  fontSize: 15,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
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
