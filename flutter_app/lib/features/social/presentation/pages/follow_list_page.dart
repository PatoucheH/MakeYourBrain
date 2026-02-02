import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/data/repositories/auth_repository.dart';
import '../../data/repositories/follow_repository.dart';
import '../widgets/user_profile_bottom_sheet.dart';

class FollowListPage extends StatefulWidget {
  final int initialTabIndex;

  const FollowListPage({
    super.key,
    this.initialTabIndex = 0,
  });

  @override
  State<FollowListPage> createState() => _FollowListPageState();
}

class _FollowListPageState extends State<FollowListPage>
    with SingleTickerProviderStateMixin {
  final _followRepo = FollowRepository();
  final _authRepo = AuthRepository();
  final _searchController = TextEditingController();
  Timer? _debounce;

  late TabController _tabController;

  List<Map<String, dynamic>> followers = [];
  List<Map<String, dynamic>> following = [];
  List<Map<String, dynamic>> searchResults = [];
  bool isLoadingFollowers = true;
  bool isLoadingFollowing = true;
  bool isSearching = false;
  bool showSearchResults = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    final userId = _authRepo.getCurrentUserId();
    if (userId == null) return;

    final followersFuture = _followRepo.getFollowers(userId);
    final followingFuture = _followRepo.getFollowing(userId);

    final results = await Future.wait([followersFuture, followingFuture]);

    if (mounted) {
      setState(() {
        followers = results[0];
        following = results[1];
        isLoadingFollowers = false;
        isLoadingFollowing = false;
      });
    }
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    if (query.trim().length < 2) {
      setState(() {
        showSearchResults = false;
        searchResults = [];
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      setState(() => isSearching = true);
      final results = await _followRepo.searchUsers(query);
      if (mounted) {
        setState(() {
          searchResults = results;
          showSearchResults = true;
          isSearching = false;
        });
      }
    });
  }

  Future<void> _toggleFollow(String targetUserId, bool currentlyFollowing) async {
    bool success;
    if (currentlyFollowing) {
      success = await _followRepo.unfollowUser(targetUserId);
    } else {
      success = await _followRepo.followUser(targetUserId);
    }
    if (success && mounted) {
      _loadData();
      // Update search results if visible
      if (showSearchResults) {
        setState(() {
          searchResults = searchResults.map((item) {
            if (item['user_id'] == targetUserId) {
              return {...item, 'is_following': !currentlyFollowing};
            }
            return item;
          }).toList();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currentUserId = _authRepo.getCurrentUserId();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              // AppBar
              _buildAppBar(l10n),

              // Search bar
              _buildSearchBar(l10n),

              // Search results or tabs
              if (showSearchResults)
                Expanded(child: _buildSearchResults(l10n, currentUserId))
              else ...[
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
                    tabs: [
                      Tab(
                        icon: const Icon(Icons.people, size: 20),
                        text: '${l10n.following} (${following.length})',
                      ),
                      Tab(
                        icon: const Icon(Icons.person, size: 20),
                        text: '${l10n.followers} (${followers.length})',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Tab content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildFollowList(
                        following,
                        isLoadingFollowing,
                        l10n.noFollowingYet,
                        currentUserId,
                        isFollowingList: true,
                      ),
                      _buildFollowList(
                        followers,
                        isLoadingFollowers,
                        l10n.noFollowersYet,
                        currentUserId,
                        isFollowingList: false,
                      ),
                    ],
                  ),
                ),
              ],
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
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.people, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              l10n.social,
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

  Widget _buildSearchBar(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppColors.softShadow,
        ),
        child: TextField(
          controller: _searchController,
          onChanged: _onSearchChanged,
          decoration: InputDecoration(
            hintText: l10n.searchByUsernameOrEmail,
            hintStyle: TextStyle(color: AppColors.textLight, fontSize: 14),
            prefixIcon: const Icon(Icons.search, color: AppColors.brainPurple),
            suffixIcon: showSearchResults
                ? IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textSecondary),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        showSearchResults = false;
                        searchResults = [];
                      });
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults(AppLocalizations l10n, String? currentUserId) {
    if (isSearching) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.brainPurple),
      );
    }

    if (searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/branding/mascot/brainly_thinking.png',
              height: 80,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.search_off,
                size: 64,
                color: AppColors.textLight,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.userNotFound,
              style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: searchResults.length,
      itemBuilder: (context, index) {
        final item = searchResults[index];
        final userId = item['user_id'] as String;
        final username = item['username'];
        final email = item['email'] ?? '';
        final displayName = (username != null && username.toString().isNotEmpty)
            ? username.toString()
            : email.toString().split('@').first;
        final isFollowingUser = item['is_following'] == true;
        final isMe = userId == currentUserId;

        return _buildUserItem(
          userId: userId,
          displayName: displayName,
          isFollowingUser: isFollowingUser,
          isMe: isMe,
          currentUserId: currentUserId,
        );
      },
    );
  }

  Widget _buildFollowList(
    List<Map<String, dynamic>> list,
    bool isLoading,
    String emptyMessage,
    String? currentUserId, {
    required bool isFollowingList,
  }) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.brainPurple),
      );
    }

    if (list.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/branding/mascot/brainly_thinking.png',
                height: 80,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.people_outline,
                  size: 64,
                  color: AppColors.textLight,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                emptyMessage,
                style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppColors.brainPurple,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: list.length,
        itemBuilder: (context, index) {
          final item = list[index];
          final userId = item['user_id'] as String;
          final username = item['username'];
          final email = item['email'] ?? '';
          final displayName = (username != null && username.toString().isNotEmpty)
              ? username.toString()
              : email.toString().split('@').first;
          final isMe = userId == currentUserId;

          // For followers tab, check is_followed_back
          // For following tab, user is always followed
          final bool isFollowingUser;
          if (isFollowingList) {
            isFollowingUser = true;
          } else {
            isFollowingUser = item['is_followed_back'] == true;
          }

          return _buildUserItem(
            userId: userId,
            displayName: displayName,
            isFollowingUser: isFollowingUser,
            isMe: isMe,
            currentUserId: currentUserId,
          );
        },
      ),
    );
  }

  Widget _buildUserItem({
    required String userId,
    required String displayName,
    required bool isFollowingUser,
    required bool isMe,
    String? currentUserId,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isMe ? AppColors.brainPurpleLight.withOpacity(0.3) : AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: isMe ? Border.all(color: AppColors.brainPurple, width: 2) : null,
        boxShadow: AppColors.cardShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(Icons.person, color: Colors.white, size: 24),
              ),
            ),
            const SizedBox(width: 14),

            // Name
            Expanded(
              child: GestureDetector(
                onTap: () {
                  UserProfileBottomSheet.show(context, userId, currentUserId);
                },
                child: Text(
                  displayName,
                  style: TextStyle(
                    fontWeight: isMe ? FontWeight.bold : FontWeight.w600,
                    fontSize: 15,
                    color: isMe ? AppColors.brainPurple : AppColors.textPrimary,
                    decoration: TextDecoration.underline,
                    decorationStyle: TextDecorationStyle.dotted,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),

            // Follow/Unfollow button (not for self)
            if (!isMe)
              TextButton(
                onPressed: () => _toggleFollow(userId, isFollowingUser),
                style: TextButton.styleFrom(
                  backgroundColor: isFollowingUser
                      ? AppColors.backgroundGray
                      : AppColors.brainPurple,
                  foregroundColor: isFollowingUser
                      ? AppColors.textSecondary
                      : Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  isFollowingUser
                      ? AppLocalizations.of(context)!.unfollow
                      : AppLocalizations.of(context)!.follow,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
