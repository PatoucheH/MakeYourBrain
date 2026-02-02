import '../../../../shared/services/supabase_service.dart';

class FollowRepository {
  final _supabase = SupabaseService().client;

  String? get _currentUserId => _supabase.auth.currentUser?.id;

  // Follow a user
  Future<bool> followUser(String followingId) async {
    try {
      await _supabase.rpc('follow_user', params: {
        'p_following_id': followingId,
      });
      return true;
    } catch (e) {
      print('Error following user: $e');
      return false;
    }
  }

  // Unfollow a user
  Future<bool> unfollowUser(String followingId) async {
    try {
      await _supabase.rpc('unfollow_user', params: {
        'p_following_id': followingId,
      });
      return true;
    } catch (e) {
      print('Error unfollowing user: $e');
      return false;
    }
  }

  // Get followers of a user
  Future<List<Map<String, dynamic>>> getFollowers(String userId) async {
    try {
      final response = await _supabase.rpc('get_followers', params: {
        'p_user_id': userId,
      });
      return List<Map<String, dynamic>>.from(response ?? []);
    } catch (e) {
      print('Error getting followers: $e');
      return [];
    }
  }

  // Get following of a user
  Future<List<Map<String, dynamic>>> getFollowing(String userId) async {
    try {
      final response = await _supabase.rpc('get_following', params: {
        'p_user_id': userId,
      });
      return List<Map<String, dynamic>>.from(response ?? []);
    } catch (e) {
      print('Error getting following: $e');
      return [];
    }
  }

  // Search users by username or email
  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    if (query.trim().length < 2) return [];
    try {
      final response = await _supabase.rpc('search_users', params: {
        'p_query': query.trim(),
      });
      return List<Map<String, dynamic>>.from(response ?? []);
    } catch (e) {
      print('Error searching users: $e');
      return [];
    }
  }

  // Get user profile summary
  Future<Map<String, dynamic>?> getUserProfileSummary(String targetUserId) async {
    try {
      final response = await _supabase.rpc('get_user_profile_summary', params: {
        'p_target_user_id': targetUserId,
      });
      final list = List<Map<String, dynamic>>.from(response ?? []);
      return list.isNotEmpty ? list.first : null;
    } catch (e) {
      print('Error getting user profile summary: $e');
      return null;
    }
  }

  // Get follow counts
  Future<Map<String, int>> getFollowCounts(String userId) async {
    try {
      final response = await _supabase.rpc('get_follow_counts', params: {
        'p_user_id': userId,
      });
      final list = List<Map<String, dynamic>>.from(response ?? []);
      if (list.isNotEmpty) {
        return {
          'followers': (list.first['followers_count'] as num?)?.toInt() ?? 0,
          'following': (list.first['following_count'] as num?)?.toInt() ?? 0,
        };
      }
      return {'followers': 0, 'following': 0};
    } catch (e) {
      print('Error getting follow counts: $e');
      return {'followers': 0, 'following': 0};
    }
  }

  // Get following leaderboard (global)
  Future<List<Map<String, dynamic>>> getFollowingLeaderboard() async {
    final userId = _currentUserId;
    if (userId == null) return [];
    try {
      final response = await _supabase.rpc('get_following_leaderboard', params: {
        'p_user_id': userId,
      });
      return List<Map<String, dynamic>>.from(response ?? []);
    } catch (e) {
      print('Error getting following leaderboard: $e');
      return [];
    }
  }

  // Get PvP following leaderboard
  Future<List<Map<String, dynamic>>> getPvPFollowingLeaderboard() async {
    final userId = _currentUserId;
    if (userId == null) return [];
    try {
      final response = await _supabase.rpc('get_pvp_following_leaderboard', params: {
        'p_user_id': userId,
      });
      return List<Map<String, dynamic>>.from(response ?? []);
    } catch (e) {
      print('Error getting PvP following leaderboard: $e');
      return [];
    }
  }

  // Check if current user is following a target user
  Future<bool> isFollowing(String targetUserId) async {
    final userId = _currentUserId;
    if (userId == null) return false;
    try {
      final response = await _supabase
          .from('user_follows')
          .select('id')
          .eq('follower_id', userId)
          .eq('following_id', targetUserId)
          .maybeSingle();
      return response != null;
    } catch (e) {
      print('Error checking follow status: $e');
      return false;
    }
  }
}
