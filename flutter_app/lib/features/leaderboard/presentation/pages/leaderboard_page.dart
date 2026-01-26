import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/data/repositories/auth_repository.dart';
import '../../data/repositories/leaderboard_repository.dart';

class LeaderboardPage extends StatefulWidget {
  final String? themeId;
  final String? themeName;

  const LeaderboardPage({
    super.key,
    this.themeId,
    this.themeName,
  });

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage>
    with SingleTickerProviderStateMixin {
  final _leaderboardRepo = LeaderboardRepository();
  final _authRepo = AuthRepository();

  late TabController _tabController;
  List<Map<String, dynamic>> globalLeaderboard = [];
  List<Map<String, dynamic>> weeklyLeaderboard = [];
  List<Map<String, dynamic>> themeLeaderboard = [];
  bool isLoading = true;
  int? myGlobalRank;
  int? myWeeklyRank;
  int? myThemeRank;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: widget.themeId != null ? 3 : 2,
      vsync: this,
    );
    loadLeaderboards();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> loadLeaderboards() async {
    try {
      final userId = _authRepo.getCurrentUserId();

      final global = await _leaderboardRepo.getGlobalLeaderboard();
      final weekly = await _leaderboardRepo.getWeeklyLeaderboard();

      int? globalRank;
      int? weeklyRank;
      int? themeRank;
      List<Map<String, dynamic>> theme = [];

      if (userId != null) {
        globalRank = await _leaderboardRepo.getUserGlobalRank(userId);
        final weeklyIndex = weekly.indexWhere((item) => item['user_id'] == userId);
        weeklyRank = weeklyIndex >= 0 ? weeklyIndex + 1 : null;

        if (widget.themeId != null) {
          theme = await _leaderboardRepo.getThemeLeaderboard(widget.themeId!);
          themeRank = await _leaderboardRepo.getUserThemeRank(userId, widget.themeId!);
        }
      }

      setState(() {
        globalLeaderboard = global;
        weeklyLeaderboard = weekly;
        themeLeaderboard = theme;
        myGlobalRank = globalRank;
        myWeeklyRank = weeklyRank;
        myThemeRank = themeRank;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading leaderboard: $e')),
        );
      }
    }
  }

  Color _getMedalColor(int rank) {
    switch (rank) {
      case 1:
        return const Color(0xFFFFD700); // Gold
      case 2:
        return const Color(0xFFC0C0C0); // Silver
      case 3:
        return const Color(0xFFCD7F32); // Bronze
      default:
        return AppColors.textSecondary;
    }
  }

  Widget _buildLeaderboardList(
    List<Map<String, dynamic>> leaderboard,
    int? myRank,
    String scoreKey,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final userId = _authRepo.getCurrentUserId();

    if (leaderboard.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/branding/mascot/brainly_thinking.png',
                  height: 80,
                ),
                const SizedBox(height: 12),
                Text(
                  'No players yet',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: loadLeaderboards,
      color: AppColors.brainPurple,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: leaderboard.length,
        itemBuilder: (context, index) {
          final item = leaderboard[index];
          final rank = index + 1;
          final isCurrentUser = item['user_id'] == userId;
          final score = item[scoreKey] ?? 0;
          final accuracy = item['accuracy']?.toStringAsFixed(1) ?? '0.0';

          String email = item['email'] ?? 'Unknown';
          if (!isCurrentUser && email.contains('@')) {
            final parts = email.split('@');
            email = '${parts[0][0]}***@${parts[1]}';
          }

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: isCurrentUser ? AppColors.brainPurpleLight.withOpacity(0.3) : AppColors.white,
              borderRadius: BorderRadius.circular(16),
              border: isCurrentUser
                  ? Border.all(color: AppColors.brainPurple, width: 2)
                  : null,
              boxShadow: AppColors.cardShadow,
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Rank Badge
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: rank <= 3
                          ? LinearGradient(
                              colors: [
                                _getMedalColor(rank),
                                _getMedalColor(rank).withOpacity(0.7),
                              ],
                            )
                          : null,
                      color: rank > 3 ? AppColors.backgroundGray : null,
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
                          ? const Icon(Icons.emoji_events, color: Colors.white, size: 24)
                          : Text(
                              '#$rank',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textSecondary,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // User Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          email,
                          style: TextStyle(
                            fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.w600,
                            fontSize: 15,
                            color: isCurrentUser ? AppColors.brainPurple : AppColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.check_circle_outline, size: 14, color: AppColors.success),
                            const SizedBox(width: 4),
                            Text(
                              '$accuracy% ${l10n.accuracy}',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Score
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: isCurrentUser
                              ? AppColors.primaryGradient
                              : const LinearGradient(
                                  colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                                ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          scoreKey == 'total_xp' ? '$score XP' : '$score pts',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      if (scoreKey == 'xp')
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'Lv ${item['level'] ?? 0}',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              // Custom AppBar
              _buildAppBar(l10n),

              // My Rank Card
              if (!isLoading && (myGlobalRank != null || myWeeklyRank != null || myThemeRank != null))
                _buildMyRankCard(l10n),

              // Tabs
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: AppColors.softShadow,
                ),
                child: TabBar(
                  controller: _tabController,
                  labelColor: AppColors.brainPurple,
                  unselectedLabelColor: AppColors.textSecondary,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    color: AppColors.brainPurpleLight.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  dividerColor: Colors.transparent,
                  tabs: widget.themeId != null
                      ? [
                          Tab(icon: const Icon(Icons.style, size: 20), text: l10n.level),
                          Tab(icon: const Icon(Icons.public, size: 20), text: l10n.global),
                          Tab(icon: const Icon(Icons.calendar_today, size: 20), text: l10n.thisWeek),
                        ]
                      : [
                          Tab(icon: const Icon(Icons.public, size: 20), text: l10n.global),
                          Tab(icon: const Icon(Icons.calendar_today, size: 20), text: l10n.thisWeek),
                        ],
                ),
              ),
              const SizedBox(height: 8),

              // Content
              Expanded(
                child: isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: AppColors.brainPurple),
                      )
                    : TabBarView(
                        controller: _tabController,
                        children: widget.themeId != null
                            ? [
                                _buildLeaderboardList(themeLeaderboard, myThemeRank, 'xp'),
                                _buildLeaderboardList(globalLeaderboard, myGlobalRank, 'total_xp'),
                                _buildLeaderboardList(weeklyLeaderboard, myWeeklyRank, 'xp_earned'),
                              ]
                            : [
                                _buildLeaderboardList(globalLeaderboard, myGlobalRank, 'total_xp'),
                                _buildLeaderboardList(weeklyLeaderboard, myWeeklyRank, 'xp_earned'),
                              ],
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
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.emoji_events, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.themeName != null
                  ? '${widget.themeName} Leaderboard'
                  : 'Leaderboard',
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

  Widget _buildMyRankCard(AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.buttonShadow,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          if (myGlobalRank != null)
            _buildRankItem('Global', myGlobalRank!, Icons.public, Colors.white),
          if (myWeeklyRank != null)
            _buildRankItem('Weekly', myWeeklyRank!, Icons.calendar_today, const Color(0xFFFFD700)),
          if (myThemeRank != null)
            _buildRankItem(l10n.yourThemeRank, myThemeRank!, Icons.style, AppColors.accentGreen),
        ],
      ),
    );
  }

  Widget _buildRankItem(String label, int rank, IconData icon, Color iconColor) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          '#$rank',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.9),
          ),
        ),
      ],
    );
  }
}
