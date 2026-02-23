import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../../../../shared/services/supabase_service.dart';
import '../models/user_model.dart';

class AuthRepository {
  final _supabase = SupabaseService().client;

  // Inscription avec pseudo
  Future<void> signUp(String email, String password, {String? username}) async {
    // Vérifier que le pseudo est disponible avant l'inscription
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

    // Créer l'entrée user_stats avec le pseudo si l'inscription réussit
    if (response.user != null && username != null && username.isNotEmpty) {
      await _supabase.from('user_stats').insert({
        'user_id': response.user!.id,
        'username': username.toLowerCase().trim(),
        'preferred_language': 'en',
      });
    }
  }

  // Vérifier si un pseudo est disponible
  Future<bool> isUsernameAvailable(String username) async {
    if (username.isEmpty) return false;

    final normalizedUsername = username.toLowerCase().trim();

    // Vérifier la longueur (3-20 caractères)
    if (normalizedUsername.length < 3 || normalizedUsername.length > 20) {
      return false;
    }

    // Vérifier les caractères autorisés (lettres, chiffres, underscore)
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

  // Mettre à jour le pseudo
  Future<bool> updateUsername(String newUsername) async {
    final userId = getCurrentUserId();
    if (userId == null) return false;

    final normalizedUsername = newUsername.toLowerCase().trim();

    // Vérifier que le pseudo est disponible
    final response = await _supabase
        .from('user_stats')
        .select('user_id')
        .eq('username', normalizedUsername)
        .neq('user_id', userId)
        .maybeSingle();

    if (response != null) {
      // Le pseudo est déjà pris par quelqu'un d'autre
      return false;
    }

    await _supabase.from('user_stats').update({
      'username': normalizedUsername,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('user_id', userId);

    return true;
  }

  // Connexion
  Future<void> signIn(String email, String password) async {
    await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  // Connexion avec Facebook
Future<bool> signInWithFacebook() async {
  try {
    final response = await _supabase.auth.signInWithOAuth(
      OAuthProvider.facebook,
      redirectTo: kIsWeb ? null : 'makeyourbrain://auth-callback',
    );
    
    return response;
  } catch (e) {
    debugPrint('Facebook login error: $e');
    return false;
  }
}

  // Connexion avec Google
  Future<bool> signInWithGoogle() async {
    try {
      // Use Supabase Auth for Google Sign-In
      final response = await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'com.patou.makeyourbrain://login-callback',
      );

      if (!response) {
        debugPrint('Google sign in cancelled by user');
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
          await _supabase.from('user_stats').insert({
            'user_id': userId,
            'username': (getCurrentUserEmail() ?? 'user').split('@')[0].toLowerCase(),
            'preferred_language': 'en',
          });
        }
      }

      return true;
    } catch (e) {
      debugPrint('Google sign in error: $e');
      return false;
    }
  }

  // Connexion avec Apple
  Future<bool> signInWithApple() async {
    try {
      // Use Supabase Auth for Apple Sign-In
      final response = await _supabase.auth.signInWithOAuth(
        OAuthProvider.apple,
        redirectTo: kIsWeb ? null : 'com.patou.makeyourbrain://login-callback',
      );

      if (!response) {
        debugPrint('Apple sign in cancelled by user');
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
          await _supabase.from('user_stats').insert({
            'user_id': userId,
            'username': (getCurrentUserEmail() ?? 'user').split('@')[0].toLowerCase(),
            'preferred_language': 'en',
          });
        }
      }

      return true;
    } catch (e) {
      debugPrint('Apple sign in error: $e');
      return false;
    }
  }

  // Déconnexion
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  // User actuel
  String? getCurrentUserId() {
    return _supabase.auth.currentUser?.id;
  }

  String? getCurrentUserEmail() {
    return _supabase.auth.currentUser?.email;
  }

  bool isLoggedIn() {
    return _supabase.auth.currentUser != null;
  }

  // Récupérer les stats du user
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

    return UserModel.fromJson({
      ...response,
      'user_id': userId,
      'email': getCurrentUserEmail(),
    });
  }

  // Mettre à jour la langue préférée
  Future<void> updateLanguage(String languageCode) async {
    final userId = getCurrentUserId();
    if (userId == null) return;

    await _supabase.from('user_stats').upsert({
      'user_id': userId,
      'preferred_language': languageCode,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  // Écouter les changements d'auth
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;
}