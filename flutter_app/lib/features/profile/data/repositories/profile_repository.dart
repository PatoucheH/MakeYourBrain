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
    await _supabase.rpc('update_user_streak', 
      params: {'p_user_id': userId}
    );
  }
}