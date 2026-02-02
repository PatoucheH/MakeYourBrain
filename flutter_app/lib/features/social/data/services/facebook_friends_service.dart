import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../shared/services/supabase_service.dart';
import '../repositories/follow_repository.dart';

/// Service to sync Facebook friends who are registered on the app.
///
/// IMPORTANT: This service requires:
/// 1. Facebook app to be in production mode (not development)
/// 2. The `user_friends` permission to be approved by Facebook
/// 3. User to have logged in via Facebook OAuth
///
/// The `user_friends` permission only returns friends who also use the app.
class FacebookFriendsService {
  final _supabase = SupabaseService().client;
  final _followRepo = FollowRepository();

  /// Attempts to sync Facebook friends.
  /// Returns the number of new friends auto-followed, or -1 if not available.
  Future<int> syncFacebookFriends() async {
    try {
      // Get the current session and check if user logged in via Facebook
      final session = _supabase.auth.currentSession;
      if (session == null) return -1;

      final providerToken = session.providerToken;
      if (providerToken == null) {
        // User didn't log in via Facebook or token expired
        return -1;
      }

      // Check if the auth provider is Facebook
      final user = _supabase.auth.currentUser;
      if (user == null) return -1;

      final isFacebookUser = user.appMetadata['provider'] == 'facebook' ||
          (user.appMetadata['providers'] as List?)?.contains('facebook') == true;

      if (!isFacebookUser) return -1;

      // Call Facebook Graph API to get friends who also use the app
      final response = await http.get(
        Uri.parse('https://graph.facebook.com/v19.0/me/friends?fields=id,name&limit=500&access_token=$providerToken'),
      );

      if (response.statusCode != 200) {
        print('Facebook friends API error: ${response.statusCode} - ${response.body}');
        return -1;
      }

      final data = json.decode(response.body);
      final friends = List<Map<String, dynamic>>.from(data['data'] ?? []);

      if (friends.isEmpty) return 0;

      // For each Facebook friend, find if they're registered in our app
      int newFollows = 0;
      for (final friend in friends) {
        final fbId = friend['id'] as String?;
        if (fbId == null) continue;

        // Search for users who signed up via Facebook with this Facebook ID
        // Facebook ID is stored in auth.users.raw_app_meta_data.provider_id
        // We need an RPC function or a lookup table for this
        // For now, we search by checking user identities
        final matchingUsers = await _findUserByFacebookId(fbId);

        for (final userId in matchingUsers) {
          final followed = await _followRepo.followUser(userId);
          if (followed) newFollows++;
        }
      }

      return newFollows;
    } catch (e) {
      print('Error syncing Facebook friends: $e');
      return -1;
    }
  }

  /// Find app users by their Facebook ID.
  /// This searches the auth.users table via a server-side function.
  ///
  /// NOTE: This requires a Supabase RPC function to be created:
  /// ```sql
  /// CREATE OR REPLACE FUNCTION find_users_by_facebook_id(p_facebook_id TEXT)
  /// RETURNS TABLE (user_id UUID)
  /// LANGUAGE plpgsql
  /// SECURITY DEFINER
  /// AS $$
  /// BEGIN
  ///   RETURN QUERY
  ///   SELECT au.id
  ///   FROM auth.users au
  ///   WHERE au.raw_app_meta_data->>'provider_id' = p_facebook_id
  ///     OR au.raw_user_meta_data->>'provider_id' = p_facebook_id;
  /// END;
  /// $$;
  /// ```
  Future<List<String>> _findUserByFacebookId(String facebookId) async {
    try {
      final response = await _supabase.rpc('find_users_by_facebook_id', params: {
        'p_facebook_id': facebookId,
      });
      final list = List<Map<String, dynamic>>.from(response ?? []);
      return list.map((item) => item['user_id'] as String).toList();
    } catch (e) {
      // RPC function may not exist yet - this is expected in development
      print('Facebook ID lookup not available: $e');
      return [];
    }
  }

  /// Check if the current user is a Facebook user.
  bool isFacebookUser() {
    final user = _supabase.auth.currentUser;
    if (user == null) return false;
    return user.appMetadata['provider'] == 'facebook' ||
        (user.appMetadata['providers'] as List?)?.contains('facebook') == true;
  }
}
