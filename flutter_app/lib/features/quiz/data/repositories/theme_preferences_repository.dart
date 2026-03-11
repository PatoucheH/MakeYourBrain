import '../../../../shared/services/supabase_service.dart';

class ThemePreferencesRepository {
  final _supabase = SupabaseService().client;

  // Save preferred themes
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

    // Mark onboarding as completed
    await _supabase
        .from('user_stats')
        .upsert({
          'user_id': userId,
          'has_completed_onboarding': true,
          'updated_at': DateTime.now().toIso8601String(),
        });
  }

  // Get preferred themes
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

  // Check if onboarding is completed
  // Returns true by default on network error — an existing authenticated user
  // must not be sent back to onboarding because of a
  // connection problem at startup.
  Future<bool> hasCompletedOnboarding(String userId) async {
    try {
      final response = await _supabase
          .from('user_stats')
          .select('has_completed_onboarding')
          .eq('user_id', userId)
          .maybeSingle();

      return response?['has_completed_onboarding'] == true;
    } catch (_) {
      return true;
    }
  }
}