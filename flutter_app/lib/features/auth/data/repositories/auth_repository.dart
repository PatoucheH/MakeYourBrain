import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../../../../shared/services/supabase_service.dart';
import '../../../../shared/services/notification_service.dart';
import '../models/user_model.dart';

class AuthRepository {
  final _supabase = SupabaseService().client;

  String _getPreferredLanguage() {
    final deviceLang = PlatformDispatcher.instance.locale.languageCode;
    return deviceLang == 'fr' ? 'fr' : 'en';
  }

  Future<void> _savefcmToken() async {
    try {
      final userId = getCurrentUserId();
      if (userId == null) return;
      final token = await NotificationService().getToken();
      if (token == null) return;
      final platform = Platform.isIOS ? 'ios' : 'android';
      await _supabase.from('user_fcm_tokens').upsert({
        'user_id': userId,
        'token': token,
        'platform': platform,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id, token').timeout(const Duration(seconds: 15));
      // Update the timezone for streak notifications
      await _supabase.from('user_stats').update({
        'timezone_offset_hours': DateTime.now().timeZoneOffset.inHours,
      }).eq('user_id', userId);
    } catch (e) {
      debugPrint('❌ Failed to save FCM token: $e');
    }
  }

  Future<void> refreshFcmToken() => _savefcmToken();

  // Sign up with username
  Future<void> signUp(String email, String password, {String? username}) async {
    // Check that the username is available before signing up
    if (username != null && username.isNotEmpty) {
      final isAvailable = await isUsernameAvailable(username);
      if (!isAvailable) {
        throw Exception('Ce pseudo est déjà utilisé');
      }
    }

    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
    );

    // Create the user_stats entry with the username if sign-up succeeds
    if (response.user != null && username != null && username.isNotEmpty) {
      final lang = _getPreferredLanguage();
      await _supabase.from('user_stats').insert({
        'user_id': response.user!.id,
        'username': username.toLowerCase().trim(),
        'preferred_language': lang,
      });
      await _savefcmToken();
    }
  }

  // Check if a username is available
  Future<bool> isUsernameAvailable(String username) async {
    if (username.isEmpty) return false;

    final normalizedUsername = username.toLowerCase().trim();

    // Check length (3-20 characters)
    if (normalizedUsername.length < 3 || normalizedUsername.length > 20) {
      return false;
    }

    // Check allowed characters (letters, numbers, underscore)
    final validPattern = RegExp(r'^[a-z0-9_]+$');
    if (!validPattern.hasMatch(normalizedUsername)) {
      return false;
    }

    final response = await _supabase
        .from('user_stats')
        .select('user_id')
        .eq('username', normalizedUsername)
        .maybeSingle();

    return response == null;
  }

  // Update the username
  Future<bool> updateUsername(String newUsername) async {
    final userId = getCurrentUserId();
    if (userId == null) return false;

    final normalizedUsername = newUsername.toLowerCase().trim();

    // Validate format (same rules as sign-up)
    if (normalizedUsername.length < 3 || normalizedUsername.length > 20) return false;
    final validPattern = RegExp(r'^[a-z0-9_]+$');
    if (!validPattern.hasMatch(normalizedUsername)) return false;

    // Check that the username is available
    final response = await _supabase
        .from('user_stats')
        .select('user_id')
        .eq('username', normalizedUsername)
        .neq('user_id', userId)
        .maybeSingle();

    if (response != null) {
      // The username is already taken by someone else
      return false;
    }

    await _supabase.from('user_stats').update({
      'username': normalizedUsername,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('user_id', userId);

    return true;
  }

  // Sign in
  Future<void> signIn(String email, String password) async {
    await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
    await _savefcmToken();
  }

  Future<bool> hasUsername() async {
    final userId = getCurrentUserId();
    if (userId == null) return false;
    final data = await _supabase
        .from('user_stats')
        .select('username')
        .eq('user_id', userId)
        .maybeSingle();
    final username = data?['username'] as String?;
    return username != null && username.isNotEmpty;
  }

  // Sign in with Facebook
Future<bool> signInWithFacebook() async {
  try {
    final response = await _supabase.auth.signInWithOAuth(
      OAuthProvider.facebook,
      redirectTo: kIsWeb ? null : 'makeyourbrain://auth-callback',
      authScreenLaunchMode: LaunchMode.inAppWebView,
    );
    
    return response;
  } catch (e) {
    debugPrint('Facebook login error: $e');
    return false;
  }
}

  // Sign in with Google
  Future<bool> signInWithGoogle() async {
    try {
      // Use Supabase Auth for Google Sign-In
      final response = await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'com.patou.makeyourbrain://login-callback',
        authScreenLaunchMode: LaunchMode.inAppWebView,
      );

      if (!response) {
        return false;
      }

      // User will be automatically created in Supabase
      // Check if user exists in user_stats, create if not
      final userId = getCurrentUserId();
      if (userId != null) {
        final existingUser = await _supabase
            .from('user_stats')
            .select()
            .eq('user_id', userId)
            .maybeSingle();

        if (existingUser == null) {
          final lang = _getPreferredLanguage();
          await _supabase.from('user_stats').insert({
            'user_id': userId,
            'preferred_language': lang,
            'timezone_offset_hours': DateTime.now().timeZoneOffset.inHours,
          });
        }
      }

      await _savefcmToken();
      return true;
    } catch (e) {
      debugPrint('Google sign in error: $e');
      return false;
    }
  }

  // Sign in with Apple
  Future<bool> signInWithApple() async {
    try {
      // Use Supabase Auth for Apple Sign-In
      final response = await _supabase.auth.signInWithOAuth(
        OAuthProvider.apple,
        redirectTo: kIsWeb ? null : 'com.patou.makeyourbrain://login-callback',
        authScreenLaunchMode: LaunchMode.inAppWebView,
      );

      if (!response) {
        return false;
      }

      // Check if user exists in user_stats, create if not
      final userId = getCurrentUserId();
      if (userId != null) {
        final existingUser = await _supabase
            .from('user_stats')
            .select()
            .eq('user_id', userId)
            .maybeSingle();

        if (existingUser == null) {
          final lang = _getPreferredLanguage();
          await _supabase.from('user_stats').insert({
            'user_id': userId,
            'preferred_language': lang,
            'timezone_offset_hours': DateTime.now().timeZoneOffset.inHours,
          });
        }
      }

      await _savefcmToken();
      return true;
    } catch (e) {
      debugPrint('Apple sign in error: $e');
      return false;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  // Suppression du compte
  Future<bool> deleteAccount() async {
    try {
      await _supabase.rpc('delete_own_account');
      await _supabase.auth.signOut();
      return true;
    } catch (e) {
      debugPrint('Delete account error: $e');
      return false;
    }
  }

  // Current user
  String? getCurrentUserId() {
    return _supabase.auth.currentUser?.id;
  }

  String? getCurrentUserEmail() {
    return _supabase.auth.currentUser?.email;
  }

  bool isLoggedIn() {
    return _supabase.auth.currentUser != null;
  }

  // Get user stats
  Future<UserModel?> getUserStats() async {
    final userId = getCurrentUserId();
    if (userId == null) return null;

    final response = await _supabase
        .from('user_stats')
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    if (response == null) {
      await _supabase.from('user_stats').insert({
        'user_id': userId,
        'preferred_language': 'en',
      });
      return UserModel(
        id: userId,
        email: getCurrentUserEmail() ?? '',
        preferredLanguage: 'en',
      );
    }

    await _savefcmToken();
    return UserModel.fromJson({
      ...response,
      'user_id': userId,
      'email': getCurrentUserEmail(),
    });
  }

  // Update the preferred language
  Future<void> updateLanguage(String languageCode) async {
    final userId = getCurrentUserId();
    if (userId == null) return;

    await _supabase.from('user_stats').upsert({
      'user_id': userId,
      'preferred_language': languageCode,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  // Listen to auth state changes
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;
}