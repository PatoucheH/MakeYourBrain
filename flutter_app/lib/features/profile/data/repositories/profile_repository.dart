import '../../../../shared/services/supabase_service.dart';

class ProfileRepository {
  final _supabase = SupabaseService().client;

  // Récupérer la progression par thème
  Future<List<Map<String, dynamic>>> getProgressByTheme(String userId) async {
    final response = await _supabase.rpc('get_user_progress_by_theme', 
      params: {'p_user_id': userId}
    );
    
    if (response is! List) return [];
    return List<Map<String, dynamic>>.from(response);
  }

  // Mettre à jour le streak
  Future<void> updateStreak(String userId) async {
    final offsetMinutes = DateTime.now().timeZoneOffset.inMinutes;
    final offsetHours = offsetMinutes ~/ 60;
    final remainingMins = offsetMinutes.abs() % 60;
    final sign = offsetMinutes >= 0 ? '+' : '-';
    final utcOffset = remainingMins == 0
        ? 'UTC$sign${offsetHours.abs()}'
        : 'UTC$sign${offsetHours.abs()}:${remainingMins.toString().padLeft(2, '0')}';
    await _supabase.rpc('update_user_streak',
      params: {
        'p_user_id': userId,
        'p_timezone': utcOffset,
      }
    ).timeout(const Duration(seconds: 15));
  }
}