import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
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
        // Weekly rank calculation
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

  Widget _buildLeaderboardList(
    List<Map<String, dynamic>> leaderboard,
    int? myRank,
    String scoreKey,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final userId = _authRepo.getCurrentUserId();

    return RefreshIndicator(
      onRefresh: loadLeaderboards,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: leaderboard.length,
        itemBuilder: (context, index) {
          final item = leaderboard[index];
          final rank = index + 1;
          final isCurrentUser = item['user_id'] == userId;
          final score = item[scoreKey] ?? 0;
          final accuracy = item['accuracy']?.toStringAsFixed(1) ?? '0.0';
          
          // Email masking
          String email = item['email'] ?? 'Unknown';
          if (!isCurrentUser && email.contains('@')) {
            final parts = email.split('@');
            email = '${parts[0][0]}***@${parts[1]}';
          }

          Color rankColor = Colors.grey;
          IconData? medalIcon;
          
          if (rank == 1) {
            rankColor = Colors.amber;
            medalIcon = Icons.emoji_events;
          } else if (rank == 2) {
            rankColor = Colors.grey.shade400;
            medalIcon = Icons.emoji_events;
          } else if (rank == 3) {
            rankColor = Colors.brown.shade300;
            medalIcon = Icons.emoji_events;
          }

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: isCurrentUser ? 4 : 1,
            color: isCurrentUser ? Colors.blue.shade50 : null,
            child: ListTile(
              leading: SizedBox(
                width: 40,
                child: Center(
                  child: rank <= 3
                      ? Icon(medalIcon, color: rankColor, size: 32)
                      : Text(
                          '#$rank',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: rankColor,
                          ),
                        ),
                ),
              ),
              title: Text(
                email,
                style: TextStyle(
                  fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              subtitle: Text('$accuracy% ${l10n.accuracy}'),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    scoreKey == 'total_xp' ? '$score XP' : '$score pts',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isCurrentUser ? Colors.blue.shade900 : null,
                    ),
                  ),
                  if (scoreKey == 'total_xp' || scoreKey == 'xp')
                    Text(
                      'Lv ${item['total_levels'] ?? 0}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
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
      appBar: AppBar(
        title: Text(
          widget.themeName != null
              ? '${widget.themeName} Leaderboard'
              : '🏆 Leaderboard',
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: widget.themeId != null? [
                Tab(
                icon: const Icon(Icons.style),
                text: l10n.level,
                ),
                Tab(
                icon: const Icon(Icons.public),
                text: l10n.global,
                ),
                Tab(
                icon: const Icon(Icons.calendar_today),
                text: l10n.thisWeek,
                ),
            ] : [
                Tab(
                icon: const Icon(Icons.public),
                text: l10n.global,
                ),
                Tab(
                icon: const Icon(Icons.calendar_today),
                text: l10n.thisWeek,
                ),
            ],
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // My Rank Card
                if (myGlobalRank != null || myWeeklyRank != null || myThemeRank != null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      border: Border(
                        bottom: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        if (myGlobalRank != null)
                          Column(
                            children: [
                              const Icon(Icons.public, color: Colors.blue),
                              const SizedBox(height: 4),
                              Text(
                                'Your Global Rank',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              Text(
                                '#$myGlobalRank',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                        if (myWeeklyRank != null)
                          Column(
                            children: [
                              const Icon(Icons.calendar_today, color: Colors.orange),
                              const SizedBox(height: 4),
                              Text(
                                'Your Weekly Rank',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              Text(
                                '#$myWeeklyRank',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange,
                                ),
                              ),
                            ],
                          ),
                        if (myThemeRank != null)
                          Column(
                            children: [
                            const Icon(Icons.style, color: Colors.green),
                            const SizedBox(height: 4),
                            Text(
                                l10n.yourThemeRank,
                                style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade700,
                                ),
                            ),
                            Text(
                                '#$myThemeRank',
                                style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                                ),
                            ),
                            ],
                          ),
                      ],
                    ),
                  ),

                // TabBarView
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: widget.themeId != null
                        ? [
                            _buildLeaderboardList(
                            themeLeaderboard,
                            myThemeRank,
                            'xp', // ✅ XP du thème
                            ),
                            _buildLeaderboardList(
                            globalLeaderboard,
                            myGlobalRank,
                            'total_xp',
                            ),
                            _buildLeaderboardList(
                            weeklyLeaderboard,
                            myWeeklyRank,
                            'xp_earned',
                            ),
                        ]
                        : [
                            _buildLeaderboardList(
                            globalLeaderboard,
                            myGlobalRank,
                            'total_xp',
                            ),
                            _buildLeaderboardList(
                            weeklyLeaderboard,
                            myWeeklyRank,
                            'xp_earned',
                            ),
                        ],
                  ),
                ),
              ],
            ),
    );
  }
}