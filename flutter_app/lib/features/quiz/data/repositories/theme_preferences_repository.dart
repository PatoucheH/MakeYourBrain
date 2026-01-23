import '../../../../shared/services/supabase_service.dart';

class ThemePreferencesRepository {
  final _supabase = SupabaseService().client;

  // Sauvegarder les thèmes préférés
  Future<void> savePreferences(String userId, List<String> themeIds) async {
    // Supprimer les anciennes préférences
    await _supabase
        .from('user_theme_preferences')
        .delete()
        .eq('user_id', userId);

    // Insérer les nouvelles
    if (themeIds.isNotEmpty) {
      await _supabase.from('user_theme_preferences').insert(
        themeIds.map((themeId) => {
          'user_id': userId,
          'theme_id': themeId,
        }).toList(),
      );
    }

    // Marquer l'onboarding comme complété
    await _supabase
        .from('user_stats')
        .upsert({
          'user_id': userId,
          'has_completed_onboarding': true,
          'updated_at': DateTime.now().toIso8601String(),
        });
  }

  // Récupérer les thèmes préférés
  Future<List<String>> getPreferences(String userId) async {
    final response = await _supabase
        .from('user_theme_preferences')
        .select('theme_id')
        .eq('user_id', userId);

    return (response as List)
        .map((item) => item['theme_id'] as String)
        .toList();
  }

  // Vérifier si onboarding complété
  Future<bool> hasCompletedOnboarding(String userId) async {
    final response = await _supabase
        .from('user_stats')
        .select('has_completed_onboarding')
        .eq('user_id', userId)
        .maybeSingle();

    return response?['has_completed_onboarding'] ?? false;
  }
}