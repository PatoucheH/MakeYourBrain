import '../../../../shared/services/supabase_service.dart';
import '../models/user_model.dart';

class AuthRepository {
  final _supabase = SupabaseService().client;

  // Inscription
  Future<void> signUp(String email, String password) async {
    await _supabase.auth.signUp(
      email: email,
      password: password,
    );
  }

  // Connexion
  Future<void> signIn(String email, String password) async {
    await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
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
      // Créer les stats si n'existent pas
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
}