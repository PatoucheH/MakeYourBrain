import '../../../../shared/services/supabase_service.dart';
import '../models/achievement_model.dart';

class AchievementRepository {
  final _supabase = SupabaseService().client;

  Future<List<AchievementModel>> getAllWithUserStatus(String userId) async {
    final allRes = await _supabase
        .from('achievements')
        .select()
        .order('category')
        .order('condition_value');

    final unlockedRes = await _supabase
        .from('user_achievements')
        .select('achievement_id, unlocked_at')
        .eq('user_id', userId);

    final unlockedMap = <String, DateTime>{};
    for (final u in unlockedRes as List) {
      final aid = u['achievement_id'] as String?;
      final rawDate = u['unlocked_at'];
      if (aid != null && rawDate != null) {
        final date = DateTime.tryParse(rawDate.toString());
        if (date != null) unlockedMap[aid] = date;
      }
    }

    return (allRes as List)
        .whereType<Map<String, dynamic>>()
        .map((a) => AchievementModel.fromJson(
              a,
              unlockedAt: unlockedMap[a['id'] as String?],
            ))
        .toList();
  }

  Future<List<AchievementModel>> checkAchievements(String userId) async {
    final response = await _supabase
        .rpc('check_achievements', params: {'p_user_id': userId});
    if (response == null) return [];
    return (response as List)
        .whereType<Map<String, dynamic>>()
        .map((e) => AchievementModel.fromJson(e, unlockedAt: DateTime.now()))
        .toList();
  }
}
