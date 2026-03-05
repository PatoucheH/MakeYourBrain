import '../../../../shared/services/supabase_service.dart';

class ThemePreferencesRepository {
  final _supabase = SupabaseService().client;

  // Sauvegarder les thèmes préférés
  Future<void> savePreferences(String userId, List<String> themeIds) async {
    // Upsert new preferences FIRST — if this fails, the old ones are preserved
    if (themeIds.isNotEmpty) {
      await _supabase.from('user_theme_preferences').upsert(
        themeIds.map((themeId) => {
          'user_id': userId,
          'theme_id': themeId,
        }).toList(),
        onConflict: 'user_id,theme_id',
      );
    }

    // Delete only preferences that are no longer in the new list
    if (themeIds.isEmpty) {
      await _supabase
          .from('user_theme_preferences')
          .delete()
          .eq('user_id', userId);
    } else {
      await _supabase
          .from('user_theme_preferences')
          .delete()
          .eq('user_id', userId)
          .not('theme_id', 'in', '(${themeIds.join(',')})');
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

    return (response as List? ?? [])
        .map((item) => item['theme_id']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
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