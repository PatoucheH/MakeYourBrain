import 'package:flutter/foundation.dart';
import '../../../../shared/services/supabase_service.dart';

class LivesRepository {
  final _supabase = SupabaseService().client;

  // Récupérer les vies actuelles
  Future<Map<String, dynamic>> getLives(String userId) async {
    final response = await _supabase.rpc('get_user_lives', params: {
      'p_user_id': userId,
    });

    final data = response as List?;
    if (data == null || data.isEmpty) {
      return {
        'current_lives': 10,
        'max_lives': 10,
        'next_life_in_seconds': 0,
      };
    }

    return data.first as Map<String, dynamic>;
  }

  // Utiliser une vie (retourne false si plus de vies)
  Future<bool> useLife(String userId) async {
    final response = await _supabase.rpc('use_life', params: {
      'p_user_id': userId,
    });

    return response == true;
  }

  // Ajouter 2 vies après une pub (debug uniquement — en prod, les vies sont accordées via SSV AdMob)
  Future<void> addLivesFromAd(String userId) async {
    assert(kDebugMode, 'addLivesFromAd must only be called in debug mode');
    if (!kDebugMode) return;
    await _supabase.rpc('add_lives_from_ad', params: {
      'p_user_id': userId,
    });
  }

  // Stream pour les mises à jour en temps réel
  Stream<Map<String, dynamic>> livesStream(String userId) {
    return Stream.periodic(const Duration(seconds: 10), (_) async {
      return await getLives(userId);
    }).asyncMap((event) => event);
  }
}