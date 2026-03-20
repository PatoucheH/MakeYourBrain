import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/data/repositories/auth_repository.dart';
import '../../../social/data/repositories/follow_repository.dart';
import '../../data/repositories/pvp_repository.dart';

class InviteToPvpSheet extends StatefulWidget {
  const InviteToPvpSheet({super.key});

  @override
  State<InviteToPvpSheet> createState() => _InviteToPvpSheetState();
}

class _InviteToPvpSheetState extends State<InviteToPvpSheet> {
  final _pvpRepo = PvPRepository();
  final _followRepo = FollowRepository();
  final _authRepo = AuthRepository();
  final _searchController = TextEditingController();

  List<Map<String, dynamic>> _suggestions = [];
  List<Map<String, dynamic>> _searchResults = [];
  bool _isLoadingSuggestions = true;
  bool _isSearching = false;
  bool _hasSearched = false;
  String? _sendingToId;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadSuggestions();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSuggestions() async {
    final userId = _authRepo.getCurrentUserId();
    if (userId == null) {
      if (mounted) { setState(() => _isLoadingSuggestions = false); }
      return;
    }
    try {
      final results = await Future.wait([
        _followRepo.getFollowers(userId),
        _followRepo.getFollowing(userId),
      ]);
      final seen = <String>{};
      final merged = <Map<String, dynamic>>[];
      for (final u in [...results[1], ...results[0]]) {
        final uid = u['user_id'] as String? ?? '';
        if (uid.isNotEmpty && uid != userId && seen.add(uid)) {
          merged.add(u);
        }
      }
      if (mounted) {
        setState(() {
          _suggestions = merged;
          _isLoadingSuggestions = false;
        });
      }
    } catch (e) {
      if (mounted) { setState(() => _isLoadingSuggestions = false); }
    }
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    final q = _searchController.text.trim();
    if (q.isEmpty) {
      if (mounted) {
        setState(() {
          _searchResults = [];
          _hasSearched = false;
          _isSearching = false;
        });
      }
      return;
    }
    if (mounted) { setState(() => _isSearching = true); }
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      final results = await _followRepo.searchUsers(q);
      final myId = _authRepo.getCurrentUserId();
      if (mounted) {
        setState(() {
          _searchResults = results.where((u) => u['user_id'] != myId).toList();
          _isSearching = false;
          _hasSearched = true;
        });
      }
    });
  }

  Future<void> _invite(String recipientId) async {
    final userId = _authRepo.getCurrentUserId();
    if (userId == null) return;
    if (mounted) { setState(() => _sendingToId = recipientId); }
    try {
      final invitationId = await _pvpRepo.sendPvpInvitation(userId, recipientId);
      if (invitationId != null) {
        await _pvpRepo.sendPvPNotification(recipientId, 'pvp_invitation');
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(AppLocalizations.of(context)!.invitationSent),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ));
        }
      }
    } catch (e) {
      debugPrint('Error inviting: $e');
    } finally {
      if (mounted) { setState(() => _sendingToId = null); }
    }
  }

  String _displayName(Map<String, dynamic> user) {
    return user['username'] as String? ??
        user['display_name'] as String? ??
        user['name'] as String? ??
        '?';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isSearchActive = _searchController.text.isNotEmpty;
    final displayList = isSearchActive ? _searchResults : _suggestions;

    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: keyboardHeight),
      child: Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
              child: Row(
                children: [
                  const Icon(Icons.sports_esports, color: AppColors.brainPurple, size: 22),
                  const SizedBox(width: 10),
                  Text(
                    l10n.inviteFriend,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            // Search field
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: l10n.searchPlayer,
                  prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                  suffixIcon: _isSearching
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.brainPurple),
                          ),
                        )
                      : _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () => _searchController.clear(),
                            )
                          : null,
                  filled: true,
                  fillColor: AppColors.backgroundGray,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            // Section label
            if (!isSearchActive && _suggestions.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    l10n.suggested,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            // User list
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: (MediaQuery.of(context).size.height * 0.45 - keyboardHeight).clamp(80.0, double.infinity),
              ),
              child: _isLoadingSuggestions && !isSearchActive
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(color: AppColors.brainPurple),
                      ),
                    )
                  : displayList.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Text(
                              _hasSearched || isSearchActive
                                  ? l10n.usernameNotFound
                                  : l10n.noFriendsToInvite,
                              style: const TextStyle(color: AppColors.textSecondary),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          itemCount: displayList.length,
                          itemBuilder: (context, index) {
                            final user = displayList[index];
                            final uid = user['user_id'] as String? ?? '';
                            final name = _displayName(user);
                            final isSending = _sendingToId == uid;

                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              leading: Container(
                                width: 44,
                                height: 44,
                                decoration: const BoxDecoration(
                                  gradient: AppColors.primaryGradient,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                              ),
                              title: Text(
                                name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              trailing: isSending
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.brainPurple,
                                      ),
                                    )
                                  : ElevatedButton(
                                      onPressed: _sendingToId != null ? null : () => _invite(uid),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.brainPurple,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                      ),
                                      child: Text(
                                        l10n.sendInvitation,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                    ),
                            );
                          },
                        ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    ),
    );
  }
}
