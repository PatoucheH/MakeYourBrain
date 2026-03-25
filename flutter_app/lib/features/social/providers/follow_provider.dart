import 'package:flutter/foundation.dart';
import '../data/repositories/follow_repository.dart';

class FollowProvider extends ChangeNotifier {
  final _repo = FollowRepository();

  Set<String> _followingIds = {};
  int followersCount = 0;
  int followingCount = 0;

  Set<String> get followingIds => _followingIds;

  bool isFollowing(String userId) => _followingIds.contains(userId);

  Future<void> loadFromServer(String currentUserId) async {
    try {
      final results = await Future.wait([
        _repo.getFollowing(currentUserId),
        _repo.getFollowCounts(currentUserId),
      ]);
      final following = results[0] as List<Map<String, dynamic>>;
      final counts = results[1] as Map<String, int>;
      _followingIds = following
          .map((u) => u['user_id'] as String? ?? '')
          .where((id) => id.isNotEmpty)
          .toSet();
      followersCount = counts['followers'] ?? 0;
      followingCount = counts['following'] ?? 0;
      notifyListeners();
    } catch (e) {
      debugPrint('[FollowProvider] loadFromServer error: $e');
    }
  }

  Future<bool> followUser(String targetId) async {
    final success = await _repo.followUser(targetId);
    if (success) {
      _followingIds.add(targetId);
      followingCount++;
      notifyListeners();
    }
    return success;
  }

  Future<bool> unfollowUser(String targetId) async {
    final success = await _repo.unfollowUser(targetId);
    if (success) {
      _followingIds.remove(targetId);
      if (followingCount > 0) followingCount--;
      notifyListeners();
    }
    return success;
  }

  void reset() {
    _followingIds = {};
    followersCount = 0;
    followingCount = 0;
    notifyListeners();
  }
}
