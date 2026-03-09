import 'package:supabase_flutter/supabase_flutter.dart';
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

  // Leaderboard hebdomadaire (top 100) — appel RPC pour bypasser RLS proprement
  Future<List<Map<String, dynamic>>> getWeeklyLeaderboard({int limit = 100}) async {
    final response = await _supabase.rpc('get_weekly_leaderboard');
    final list = List<Map<String, dynamic>>.from(response as List);
    return limit > 0 ? list.take(limit).toList() : list;
  }

  // Position d'un user dans le leaderboard global.
  // .count(CountOption.exact) → le serveur retourne le COUNT dans les headers,
  // aucune donnée volumineuse n'est traitée côté client.
  Future<int?> getUserGlobalRank(String userId) async {
    final userRow = await _supabase
        .from('leaderboard_global')
        .select('total_xp')
        .eq('user_id', userId)
        .maybeSingle();
    if (userRow == null) return null;
    final userXp = (userRow['total_xp'] as num?)?.toInt() ?? 0;
    final countResponse = await _supabase
        .from('leaderboard_global')
        .select('user_id')
        .gt('total_xp', userXp)
        .count(CountOption.exact);
    return countResponse.count + 1;
  }

  // Position d'un user dans un thème.
  Future<int?> getUserThemeRank(String userId, String themeId) async {
    final userRow = await _supabase
        .from('leaderboard_by_theme')
        .select('xp')
        .eq('user_id', userId)
        .eq('theme_id', themeId)
        .maybeSingle();
    if (userRow == null) return null;
    final userXp = (userRow['xp'] as num?)?.toInt() ?? 0;
    final countResponse = await _supabase
        .from('leaderboard_by_theme')
        .select('user_id')
        .eq('theme_id', themeId)
        .gt('xp', userXp)
        .count(CountOption.exact);
    return countResponse.count + 1;
  }
}
