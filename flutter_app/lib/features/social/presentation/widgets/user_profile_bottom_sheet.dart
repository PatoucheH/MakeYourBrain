import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/repositories/follow_repository.dart';

class UserProfileBottomSheet extends StatefulWidget {
  final String userId;
  final String? currentUserId;

  const UserProfileBottomSheet({
    super.key,
    required this.userId,
    this.currentUserId,
  });

  static Future<void> show(BuildContext context, String userId, String? currentUserId) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => UserProfileBottomSheet(
        userId: userId,
        currentUserId: currentUserId,
      ),
    );
  }

  @override
  State<UserProfileBottomSheet> createState() => _UserProfileBottomSheetState();
}

class _UserProfileBottomSheetState extends State<UserProfileBottomSheet> {
  final _followRepo = FollowRepository();
  Map<String, dynamic>? profileData;
  bool isLoading = true;
  bool isFollowing = false;
  bool isToggling = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final data = await _followRepo.getUserProfileSummary(widget.userId);
    if (mounted) {
      setState(() {
        profileData = data;
        isFollowing = data?['is_following'] == true;
        isLoading = false;
      });
    }
  }

  Future<void> _toggleFollow() async {
    if (isToggling) return;
    setState(() => isToggling = true);

    bool success;
    if (isFollowing) {
      success = await _followRepo.unfollowUser(widget.userId);
    } else {
      success = await _followRepo.followUser(widget.userId);
    }

    if (success && mounted) {
      setState(() {
        isFollowing = !isFollowing;
        if (profileData != null) {
          final currentCount = (profileData!['followers_count'] as num?)?.toInt() ?? 0;
          profileData!['followers_count'] = isFollowing ? currentCount + 1 : currentCount - 1;
        }
      });
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isFollowing ? l10n.followSuccess : l10n.unfollowSuccess),
          duration: const Duration(seconds: 2),
        ),
      );
    }
    if (mounted) setState(() => isToggling = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isOwnProfile = widget.userId == widget.currentUserId;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: isLoading
          ? const SizedBox(
              height: 200,
              child: Center(
                child: CircularProgressIndicator(color: AppColors.brainPurple),
              ),
            )
          : profileData == null
              ? SizedBox(
                  height: 200,
                  child: Center(
                    child: Text(
                      l10n.userNotFound,
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
                    ),
                  ),
                )
              : _buildContent(l10n, isOwnProfile),
    );
  }

  Widget _buildContent(AppLocalizations l10n, bool isOwnProfile) {
    final data = profileData!;
    final username = data['username'];
    final email = data['email'] ?? '';
    final displayName = (username != null && username.toString().isNotEmpty)
        ? username.toString()
        : email.toString().split('@').first;

    final totalQuestions = (data['total_questions'] as num?)?.toInt() ?? 0;
    final correctAnswers = (data['correct_answers'] as num?)?.toInt() ?? 0;
    final accuracy = totalQuestions > 0 ? (correctAnswers / totalQuestions * 100) : 0.0;
    final rawStreak = (data['current_streak'] as num?)?.toInt() ?? 0;
    final bestStreak = (data['best_streak'] as num?)?.toInt() ?? 0;
    // Calculer le streak effectif : 0 si pas joué depuis plus d'1 jour
    final lastPlayedAt = data['last_played_at'] != null
        ? DateTime.tryParse(data['last_played_at'].toString())
        : null;
    int currentStreak = rawStreak;
    if (lastPlayedAt != null) {
      final now = DateTime.now();
      final local = lastPlayedAt.toLocal();
      final today = DateTime(now.year, now.month, now.day);
      final lastPlayed = DateTime(local.year, local.month, local.day);
      if (today.difference(lastPlayed).inDays > 1) {
        currentStreak = 0;
      }
    } else {
      currentStreak = 0;
    }
    final pvpRating = (data['pvp_rating'] as num?)?.toInt() ?? 1000;
    final pvpWins = (data['pvp_wins'] as num?)?.toInt() ?? 0;
    final pvpLosses = (data['pvp_losses'] as num?)?.toInt() ?? 0;
    final pvpDraws = (data['pvp_draws'] as num?)?.toInt() ?? 0;
    final followersCount = (data['followers_count'] as num?)?.toInt() ?? 0;
    final followingCount = (data['following_count'] as num?)?.toInt() ?? 0;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            // Avatar + Name
            Image.asset(
              'assets/branding/mascot/brainly_happy.png',
              height: 64,
              errorBuilder: (_, _, _) => Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person, color: Colors.white, size: 32),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              displayName,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),

            // Followers / Following counts
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildCountChip('$followersCount', l10n.followers),
                const SizedBox(width: 24),
                _buildCountChip('$followingCount', l10n.following),
              ],
            ),
            const SizedBox(height: 16),

            // Follow button (not on own profile)
            if (!isOwnProfile)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: isToggling ? null : _toggleFollow,
                  icon: isToggling
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(
                          isFollowing ? Icons.person_remove : Icons.person_add,
                          size: 20,
                        ),
                  label: Text(isFollowing ? l10n.unfollow : l10n.follow),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isFollowing ? AppColors.textSecondary : AppColors.brainPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 20),

            // Stats grid
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatItem(
                          Icons.local_fire_department,
                          AppColors.warning,
                          '$currentStreak',
                          l10n.currentStreak,
                        ),
                      ),
                      Expanded(
                        child: _buildStatItem(
                          Icons.emoji_events,
                          const Color(0xFFFFD700),
                          '$bestStreak',
                          l10n.bestStreak,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatItem(
                          Icons.quiz,
                          AppColors.accentBlue,
                          '$totalQuestions',
                          l10n.questions,
                        ),
                      ),
                      Expanded(
                        child: _buildStatItem(
                          Icons.check_circle,
                          AppColors.success,
                          '${accuracy.toStringAsFixed(1)}%',
                          l10n.accuracy,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // PvP stats
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.sports_esports, color: AppColors.brainPurple, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        l10n.pvpArena,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$pvpRating',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildPvpStat('$pvpWins', l10n.wins, AppColors.success),
                      _buildPvpStat('$pvpLosses', l10n.losses, AppColors.error),
                      _buildPvpStat('$pvpDraws', l10n.draws, AppColors.textSecondary),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCountChip(String count, String label) {
    return Column(
      children: [
        Text(
          count,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.brainPurple,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(IconData icon, Color color, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildPvpStat(String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
