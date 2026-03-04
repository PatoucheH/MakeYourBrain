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
    final userRow = await _supabase
        .from('leaderboard_global')
        .select('total_xp')
        .eq('user_id', userId)
        .maybeSingle();
    if (userRow == null) return null;
    final userXp = (userRow['total_xp'] as num?)?.toInt() ?? 0;
    final higherRanked = await _supabase
        .from('leaderboard_global')
        .select('user_id')
        .gt('total_xp', userXp);
    return (higherRanked as List).length + 1;
  }

  // Position d'un user dans un thème
  Future<int?> getUserThemeRank(String userId, String themeId) async {
    final userRow = await _supabase
        .from('leaderboard_by_theme')
        .select('xp')
        .eq('user_id', userId)
        .eq('theme_id', themeId)
        .maybeSingle();
    if (userRow == null) return null;
    final userXp = (userRow['xp'] as num?)?.toInt() ?? 0;
    final higherRanked = await _supabase
        .from('leaderboard_by_theme')
        .select('user_id')
        .eq('theme_id', themeId)
        .gt('xp', userXp);
    return (higherRanked as List).length + 1;
  }
}