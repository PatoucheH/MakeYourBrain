import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../features/auth/data/repositories/auth_repository.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/leaderboard/presentation/pages/leaderboard_page.dart';
import '../../features/lives/presentation/widgets/lives_indicator.dart';

enum AppPage { home, profile, leaderboard, other }

class BrainAppBar extends StatefulWidget {
  final AppPage currentPage;

  const BrainAppBar({super.key, this.currentPage = AppPage.other});

  @override
  State<BrainAppBar> createState() => _BrainAppBarState();
}

class _BrainAppBarState extends State<BrainAppBar> {
  final _authRepo = AuthRepository();
  int currentStreak = 0;

  @override
  void initState() {
    super.initState();
    _loadStreak();
  }

  Future<void> _loadStreak() async {
    try {
      final stats = await _authRepo.getUserStats();
      if (mounted) {
        setState(() {
          currentStreak = stats?.effectiveStreak ?? 0;
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isFirstRoute = !Navigator.of(context).canPop();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          // Logo + Title (clickable → home)
          Expanded(
            child: MouseRegion(
              cursor: isFirstRoute
                  ? SystemMouseCursors.basic
                  : SystemMouseCursors.click,
              child: GestureDetector(
                onTap: isFirstRoute
                    ? null
                    : () => Navigator.of(context)
                        .popUntil((route) => route.isFirst),
                child: Row(
                  children: [
                    Image.asset(
                      'assets/branding/logo/brainly_logo.png',
                      height: 28,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        l10n.appName,
                        style: const TextStyle(
                          color: AppColors.brainPurple,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Streak
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppColors.softShadow,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.local_fire_department,
                  color: Color(0xFFFF6B6B),
                  size: 18,
                ),
                const SizedBox(width: 2),
                Text(
                  '$currentStreak',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),

          // Lives Indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppColors.softShadow,
            ),
            child: const LivesIndicator(),
          ),
          const SizedBox(width: 6),

          // Menu Button
          Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: AppColors.softShadow,
            ),
            child: PopupMenuButton<String>(
              icon: const Icon(
                Icons.menu,
                color: AppColors.brainPurple,
                size: 20,
              ),
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onSelected: (value) async {
                if (value == 'home') {
                  Navigator.of(context)
                      .popUntil((route) => route.isFirst);
                } else if (value == 'profile') {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const ProfilePage()),
                  );
                  _loadStreak();
                } else if (value == 'leaderboard') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const LeaderboardPage()),
                  );
                } else if (value == 'logout') {
                  await _authRepo.signOut();
                  if (context.mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                          builder: (context) => const LoginPage()),
                      (route) => false,
                    );
                  }
                }
              },
              itemBuilder: (context) {
                final items = <PopupMenuEntry<String>>[];

                if (widget.currentPage != AppPage.home) {
                  items.add(PopupMenuItem(
                    value: 'home',
                    child: Row(
                      children: [
                        const Icon(Icons.home_outlined,
                            color: AppColors.brainPurple),
                        const SizedBox(width: 12),
                        Text(l10n.home),
                      ],
                    ),
                  ));
                }

                if (widget.currentPage != AppPage.profile) {
                  items.add(PopupMenuItem(
                    value: 'profile',
                    child: Row(
                      children: [
                        const Icon(Icons.person_outline,
                            color: AppColors.brainPurple),
                        const SizedBox(width: 12),
                        Text(l10n.profile),
                      ],
                    ),
                  ));
                }

                if (widget.currentPage != AppPage.leaderboard) {
                  items.add(PopupMenuItem(
                    value: 'leaderboard',
                    child: Row(
                      children: [
                        const Icon(Icons.leaderboard_outlined,
                            color: AppColors.brainPurple),
                        const SizedBox(width: 12),
                        Text(l10n.viewLeaderboard),
                      ],
                    ),
                  ));
                }

                items.add(const PopupMenuDivider());
                items.add(PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: [
                      const Icon(Icons.logout, color: AppColors.error),
                      const SizedBox(width: 12),
                      Text(l10n.logout,
                          style: const TextStyle(color: AppColors.error)),
                    ],
                  ),
                ));

                return items;
              },
            ),
          ),
        ],
      ),
    );
  }
}
