import '../../../../shared/services/supabase_service.dart';
import '../../../quiz/data/models/question_model.dart';
import '../models/pvp_match_model.dart';
import '../models/pvp_round_model.dart';

class PvPRepository {
  final _supabase = SupabaseService().client;

  /// Rejoint la file d'attente de matchmaking
  /// Retourne un Map avec matchFound, matchId, et opponentId
  Future<Map<String, dynamic>> joinMatchmaking(
    String userId,
    int rating,
    String language,
  ) async {
    final response = await _supabase.rpc('pvp_join_queue', params: {
      'p_user_id': userId,
      'p_rating': rating,
      'p_language': language,
    });

    if (response == null) {
      return {
        'matchFound': false,
        'matchId': null,
        'opponentId': null,
      };
    }

    return {
      'matchFound': response['match_found'] ?? false,
      'matchId': response['match_id'],
      'opponentId': response['opponent_id'],
    };
  }

  /// Quitte la file d'attente de matchmaking
  Future<void> leaveMatchmaking(String userId) async {
    await _supabase.rpc('pvp_leave_queue', params: {
      'p_user_id': userId,
    });
  }

  /// Récupère un match par son ID
  Future<PvPMatchModel?> getMatch(String matchId) async {
    final response = await _supabase
        .from('pvp_matches')
        .select()
        .eq('id', matchId)
        .maybeSingle();

    if (response == null) return null;
    return PvPMatchModel.fromJson(response);
  }

  /// Récupère des questions aléatoires pour un round PvP
  Future<List<QuestionModel>> getQuestionsForRound(
    String language,
    int limit,
  ) async {
    final response = await _supabase.rpc('pvp_get_random_questions', params: {
      'p_language_code': language,
      'p_limit': limit,
    });

    return (response as List)
        .map((json) => QuestionModel.fromJson(json))
        .toList();
  }

  /// Crée un nouveau round pour un match
  /// Retourne l'ID du round créé
  Future<String> createRound(
    String matchId,
    int roundNumber,
    List<String> questionIds,
  ) async {
    final response = await _supabase.rpc('pvp_create_round', params: {
      'p_match_id': matchId,
      'p_round_number': roundNumber,
      'p_question_ids': questionIds,
    });

    return response as String;
  }

  /// Récupère un round spécifique d'un match
  Future<PvPRoundModel?> getRound(String matchId, int roundNumber) async {
    final response = await _supabase
        .from('pvp_rounds')
        .select()
        .eq('match_id', matchId)
        .eq('round_number', roundNumber)
        .maybeSingle();

    if (response == null) return null;
    return PvPRoundModel.fromJson(response);
  }

  /// Récupère tous les rounds d'un match
  Future<List<PvPRoundModel>> getRounds(String matchId) async {
    final response = await _supabase
        .from('pvp_rounds')
        .select()
        .eq('match_id', matchId)
        .order('round_number', ascending: true);

    return (response as List)
        .map((json) => PvPRoundModel.fromJson(json))
        .toList();
  }

  /// Soumet les réponses d'un joueur pour un round
  Future<void> submitRoundAnswers(
    String matchId,
    int roundNumber,
    String userId,
    List<PvPAnswerModel> answers,
    int score,
  ) async {
    final answersJson = answers.map((a) => a.toJson()).toList();

    await _supabase.rpc('pvp_submit_round_answers', params: {
      'p_match_id': matchId,
      'p_round_number': roundNumber,
      'p_user_id': userId,
      'p_answers': answersJson,
      'p_score': score,
    });
  }

  /// Termine un match et calcule le gagnant
  Future<void> completeMatch(String matchId) async {
    await _supabase.rpc('pvp_complete_match', params: {
      'p_match_id': matchId,
    });
  }

  /// Récupère l'historique des matchs d'un joueur
  Future<List<PvPMatchModel>> getMyMatches(
    String userId, {
    int limit = 20,
  }) async {
    try {
      final response = await _supabase
          .from('pvp_matches')
          .select()
          .or('player1_id.eq.$userId,player2_id.eq.$userId')
          .order('created_at', ascending: false)
          .limit(limit);

      return (response as List)
          .map((json) => PvPMatchModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error getting matches: $e');
      return [];
    }
  }

  /// Récupère les matchs en cours d'un joueur
  Future<List<PvPMatchModel>> getActiveMatches(String userId) async {
    try {
      final response = await _supabase
          .from('pvp_matches')
          .select()
          .or('player1_id.eq.$userId,player2_id.eq.$userId')
          .inFilter('status', ['waiting', 'player1_turn', 'player2_turn'])
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => PvPMatchModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error getting active matches: $e');
      return [];
    }
  }

  /// Écoute les changements en temps réel sur un match
  Stream<PvPMatchModel?> watchMatch(String matchId) {
    return _supabase
        .from('pvp_matches')
        .stream(primaryKey: ['id'])
        .eq('id', matchId)
        .map((list) {
          if (list.isEmpty) return null;
          return PvPMatchModel.fromJson(list.first);
        });
  }

  /// Écoute les changements sur un round spécifique
  Stream<PvPRoundModel?> watchRound(String matchId, int roundNumber) {
    return _supabase
        .from('pvp_rounds')
        .stream(primaryKey: ['id'])
        .eq('match_id', matchId)
        .map((list) {
          final round = list.where((r) => r['round_number'] == roundNumber).firstOrNull;
          if (round == null) return null;
          return PvPRoundModel.fromJson(round);
        });
  }

  /// Annule un match (si l'adversaire ne répond pas)
  Future<void> cancelMatch(String matchId) async {
    await _supabase
        .from('pvp_matches')
        .update({'status': 'cancelled'})
        .eq('id', matchId);
  }

  /// Vérifie si un joueur est dans la file d'attente
  Future<bool> isInQueue(String userId) async {
    final response = await _supabase
        .from('pvp_matchmaking_queue')
        .select('id')
        .eq('user_id', userId)
        .maybeSingle();

    return response != null;
  }

  /// Récupère les statistiques PvP d'un joueur
  Future<Map<String, dynamic>> getPlayerPvPStats(String userId) async {
    try {
      final response = await _supabase
          .from('user_stats')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) {
        return {
          'rating': 1000,
          'wins': 0,
          'losses': 0,
          'draws': 0,
        };
      }

      return {
        'rating': response['pvp_rating'] ?? 1000,
        'wins': response['pvp_wins'] ?? 0,
        'losses': response['pvp_losses'] ?? 0,
        'draws': response['pvp_draws'] ?? 0,
      };
    } catch (e) {
      // Si les colonnes PvP n'existent pas encore, retourner les valeurs par défaut
      print('Error getting PvP stats: $e');
      return {
        'rating': 1000,
        'wins': 0,
        'losses': 0,
        'draws': 0,
      };
    }
  }

  /// Récupère le classement PvP global
  Future<List<Map<String, dynamic>>> getPvPLeaderboard({int limit = 50}) async {
    try {
      final response = await _supabase
          .from('user_stats')
          .select()
          .gt('pvp_wins', 0)
          .order('pvp_rating', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting PvP leaderboard: $e');
      return [];
    }
  }
}
