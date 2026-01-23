import '../../../../shared/services/supabase_service.dart';

class LeaderboardRepository {
  final _supabase = SupabaseService().client;

  // Leaderboard global (top 100)
  Future<List<Map<String, dynamic>>> getGlobalLeaderboard({int limit = 100}) async {
    final response = await _supabase
        .from('leaderboard_global')
        .select()
        .limit(limit);
    
    return List<Map<String, dynamic>>.from(response);
  }

  // Leaderboard par thème (top 100)
  Future<List<Map<String, dynamic>>> getThemeLeaderboard(
    String themeId, {
    int limit = 100,
  }) async {
    final response = await _supabase
        .from('leaderboard_by_theme')
        .select()
        .eq('theme_id', themeId)
        .limit(limit);
    
    return List<Map<String, dynamic>>.from(response);
  }

  // Leaderboard hebdomadaire (top 100)
  Future<List<Map<String, dynamic>>> getWeeklyLeaderboard({int limit = 100}) async {
    final response = await _supabase
        .from('leaderboard_weekly')
        .select()
        .limit(limit);
    
    return List<Map<String, dynamic>>.from(response);
  }

  // Position d'un user dans le leaderboard global
  Future<int?> getUserGlobalRank(String userId) async {
    final leaderboard = await getGlobalLeaderboard(limit: 1000);
    final index = leaderboard.indexWhere((item) => item['user_id'] == userId);
    return index >= 0 ? index + 1 : null;
  }

  // Position d'un user dans un thème
  Future<int?> getUserThemeRank(String userId, String themeId) async {
    final leaderboard = await getThemeLeaderboard(themeId, limit: 1000);
    final index = leaderboard.indexWhere((item) => item['user_id'] == userId);
    return index >= 0 ? index + 1 : null;
  }
}