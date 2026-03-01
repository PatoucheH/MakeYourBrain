import '../../../../shared/services/supabase_service.dart';

class ProfileRepository {
  final _supabase = SupabaseService().client;

  // Récupérer la progression par thème
  Future<List<Map<String, dynamic>>> getProgressByTheme(String userId) async {
    final response = await _supabase.rpc('get_user_progress_by_theme', 
      params: {'p_user_id': userId}
    );
    
    return List<Map<String, dynamic>>.from(response ?? []);
  }

  // Mettre à jour le streak
  Future<void> updateStreak(String userId) async {
    final offsetHours = DateTime.now().timeZoneOffset.inHours;
    // Convert offset to POSIX timezone format (e.g., +02, -05)
    final sign = offsetHours >= 0 ? '+' : '';
    final utcOffset = 'UTC$sign$offsetHours';
    await _supabase.rpc('update_user_streak',
      params: {
        'p_user_id': userId,
        'p_timezone': utcOffset,
      }
    ).timeout(const Duration(seconds: 15));
  }
}