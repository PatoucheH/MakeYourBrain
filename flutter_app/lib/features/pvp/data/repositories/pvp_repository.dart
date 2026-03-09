import 'package:flutter/foundation.dart';
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
    try {
      final response = await _supabase.rpc('pvp_join_queue', params: {
        'p_user_id': userId,
        'p_rating': rating,
        'p_language': language,
      }).timeout(const Duration(seconds: 15));

      if (response == null || (response is List && response.isEmpty)) {
        return {'matchFound': false, 'matchId': null, 'opponentId': null};
      }

      final data = response is List ? response.first : response;
      return {
        'matchFound': data['match_found'] ?? false,
        'matchId': data['match_id'],
        'opponentId': data['opponent_id'],
      };
    } catch (e) {
      debugPrint('Error joining matchmaking: $e');
      return {'matchFound': false, 'matchId': null, 'opponentId': null};
    }
  }

  /// Quitte la file d'attente de matchmaking
  Future<void> leaveMatchmaking(String userId) async {
    try {
      await _supabase.rpc('pvp_leave_queue', params: {
        'p_user_id': userId,
      });
    } catch (e) {
      debugPrint('Error leaving matchmaking: $e');
    }
  }

  /// Récupère un match par son ID
  Future<PvPMatchModel?> getMatch(String matchId) async {
    try {
      final response = await _supabase
          .from('pvp_matches')
          .select()
          .eq('id', matchId)
          .maybeSingle()
          .timeout(const Duration(seconds: 15));

      if (response == null) return null;
      return PvPMatchModel.fromJson(response);
    } catch (e) {
      debugPrint('Error getting match: $e');
      return null;
    }
  }

  /// Récupère des questions aléatoires pour un round PvP
  Future<List<QuestionModel>> getQuestionsForRound(
    String language,
    int limit,
  ) async {
    try {
      final response = await _supabase.rpc('pvp_get_random_questions', params: {
        'p_language_code': language,
        'p_limit': limit,
      });

      if (response is! List) return [];
      return QuestionModel.ensureAnswerVariety(
        response.map((json) => QuestionModel.fromJson(json)).toList(),
      );
    } catch (e) {
      debugPrint('Error getting questions for round: $e');
      return [];
    }
  }

  /// Récupère des questions par leurs IDs pour un round PvP
  Future<List<QuestionModel>> getQuestionsByIds(
    List<String> questionIds,
    String language,
  ) async {
    try {
      final response = await _supabase.rpc('pvp_get_questions_by_ids', params: {
        'p_question_ids': questionIds,
        'p_language_code': language,
      });

      if (response is! List) return [];
      return QuestionModel.ensureAnswerVariety(
        response.map((json) => QuestionModel.fromJson(json)).toList(),
      );
    } catch (e) {
      debugPrint('Error getting questions by ids: $e');
      return [];
    }
  }

  /// Crée un nouveau round pour un match
  /// Retourne l'ID du round créé
  Future<String> createRound(
    String matchId,
    int roundNumber,
    List<String> questionIds, {
    String? themeId,
  }) async {
    try {
      final response = await _supabase.rpc('pvp_create_round', params: {
        'p_match_id': matchId,
        'p_round_number': roundNumber,
        'p_question_ids': questionIds,
        'p_theme_id': themeId,
      });
      return response?.toString() ?? '';
    } catch (e) {
      debugPrint('Error creating round: $e');
      return '';
    }
  }

  /// Récupère un round spécifique d'un match
  Future<PvPRoundModel?> getRound(String matchId, int roundNumber) async {
    try {
      final response = await _supabase
          .from('pvp_rounds')
          .select()
          .eq('match_id', matchId)
          .eq('round_number', roundNumber)
          .maybeSingle();

      if (response == null) return null;
      return PvPRoundModel.fromJson(response);
    } catch (e) {
      debugPrint('Error getting round: $e');
      return null;
    }
  }

  /// Récupère tous les rounds d'un match
  Future<List<PvPRoundModel>> getRounds(String matchId) async {
    try {
      final response = await _supabase
          .from('pvp_rounds')
          .select()
          .eq('match_id', matchId)
          .order('round_number', ascending: true);

      return response.map((json) => PvPRoundModel.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error getting rounds: $e');
      return [];
    }
  }

  /// Soumet les réponses d'un joueur pour un round
  Future<void> submitRoundAnswers(
    String matchId,
    int roundNumber,
    String userId,
    List<PvPAnswerModel> answers,
    int score,
  ) async {
    try {
      final answersJson = answers.map((a) => a.toJson()).toList();
      await _supabase.rpc('pvp_submit_round_answers', params: {
        'p_match_id': matchId,
        'p_round_number': roundNumber,
        'p_user_id': userId,
        'p_answers': answersJson,
        'p_score': score,
      });
    } catch (e) {
      debugPrint('Error submitting round answers: $e');
    }
  }

  /// Termine un match et calcule le gagnant
  Future<void> completeMatch(String matchId) async {
    try {
      await _supabase.rpc('pvp_complete_match', params: {
        'p_match_id': matchId,
      });
    } catch (e) {
      debugPrint('Error completing match: $e');
    }
  }

  /// Récupère l'historique des matchs d'un joueur
  Future<List<PvPMatchModel>> getMyMatches(
    String userId, {
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await _supabase
          .from('pvp_matches')
          .select()
          .or('player1_id.eq.$userId,player2_id.eq.$userId')
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List? ?? [])
          .map((json) => PvPMatchModel.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error getting matches: $e');
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
          .inFilter('status', ['waiting', 'player1_turn', 'player2_turn', 'player1_choosing_theme', 'player2_choosing_theme'])
          .order('created_at', ascending: false)
          .timeout(const Duration(seconds: 15));

      return (response as List? ?? [])
          .map((json) => PvPMatchModel.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error getting active matches: $e');
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

  /// Met à jour le statut d'un match via RPC sécurisé (validation côté serveur)
  Future<void> updateMatchStatus(String matchId, String status) async {
    try {
      await _supabase.rpc('pvp_update_match_status', params: {
        'p_match_id': matchId,
        'p_status': status,
      });
    } catch (e) {
      debugPrint('Error updating match status: $e');
    }
  }

  /// Met à jour le statut et le round courant d'un match via RPC sécurisé
  Future<void> updateMatchStatusAndRound(String matchId, String status, int currentRound) async {
    try {
      await _supabase.rpc('pvp_update_match_status', params: {
        'p_match_id': matchId,
        'p_status': status,
        'p_current_round': currentRound,
      });
    } catch (e) {
      debugPrint('Error updating match status and round: $e');
    }
  }

  /// Annule un match (si l'adversaire ne répond pas)
  Future<void> cancelMatch(String matchId) async {
    try {
      await _supabase.rpc('pvp_update_match_status', params: {
        'p_match_id': matchId,
        'p_status': 'cancelled',
      });
    } catch (e) {
      debugPrint('Error cancelling match: $e');
    }
  }

  /// Vérifie si un joueur est dans la file d'attente
  Future<bool> isInQueue(String userId) async {
    try {
      final response = await _supabase
          .from('pvp_matchmaking_queue')
          .select('id')
          .eq('user_id', userId)
          .maybeSingle();
      return response != null;
    } catch (e) {
      debugPrint('Error checking queue status: $e');
      return false;
    }
  }

  /// Récupère le username d'un joueur
  Future<String?> getUsername(String userId) async {
    try {
      final response = await _supabase
          .from('user_stats')
          .select('username')
          .eq('user_id', userId)
          .maybeSingle();
      return response?['username'] as String?;
    } catch (e) {
      debugPrint('Error getting username: $e');
      return null;
    }
  }

  /// Récupère le username et la langue préférée d'un joueur en un seul appel
  Future<Map<String, String?>> getOpponentInfo(String userId) async {
    try {
      final response = await _supabase
          .from('user_stats')
          .select('username, preferred_language')
          .eq('user_id', userId)
          .maybeSingle();
      return {
        'username': response?['username'] as String?,
        'language': response?['preferred_language'] as String?,
      };
    } catch (e) {
      return {'username': null, 'language': null};
    }
  }

  /// Envoie une push notification à un joueur via l'edge function (fire-and-forget).
  /// [notificationType] doit être l'un de : 'match_found', 'your_turn', 'match_over'
  Future<void> sendPvPNotification(String userId, String notificationType) async {
    try {
      await _supabase.functions.invoke('send-notification', body: {
        'userId': userId,
        'notificationType': notificationType,
      });
    } catch (e) {
      debugPrint('Error sending PvP notification: $e');
    }
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
        'rating': _toInt(response['pvp_rating'], 1000),
        'wins': _toInt(response['pvp_wins'], 0),
        'losses': _toInt(response['pvp_losses'], 0),
        'draws': _toInt(response['pvp_draws'], 0),
      };
    } catch (e) {
      // Si les colonnes PvP n'existent pas encore, retourner les valeurs par défaut
      debugPrint('Error getting PvP stats: $e');
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
      debugPrint('Error getting PvP leaderboard: $e');
      return [];
    }
  }

  /// Vérifie le statut de la queue au retour dans l'app
  Future<Map<String, dynamic>> checkQueueStatus(String userId) async {
    try {
      final response = await _supabase.rpc('pvp_check_queue_status', params: {
        'p_user_id': userId,
      });
      final data = response is Map<String, dynamic> ? response : <String, dynamic>{};
      return {
        'inQueue': data['in_queue'] ?? false,
        'matchFound': data['match_found'] ?? false,
        'matchId': data['match_id'],
        'timeInQueue': data['time_in_queue'],
      };
    } catch (e) {
      debugPrint('Error checking queue status: $e');
      return {'inQueue': false, 'matchFound': false, 'matchId': null, 'timeInQueue': null};
    }
  }

  /// Récupère des questions aléatoires pour un thème spécifique
  Future<List<QuestionModel>> getQuestionsByTheme(
    String themeId,
    String language,
    int limit, {
    int avgRating = 1000,
  }) async {
    try {
      final response = await _supabase.rpc('pvp_get_random_questions_by_theme', params: {
        'p_theme_id': themeId,
        'p_language_code': language,
        'p_limit': limit,
        'p_avg_rating': avgRating,
      });

      if (response is! List) return [];
      return QuestionModel.ensureAnswerVariety(
        response.map((json) => QuestionModel.fromJson(json)).toList(),
      );
    } catch (e) {
      debugPrint('Error getting questions by theme: $e');
      return [];
    }
  }

  /// Récupère un thème aléatoire excluant certains thèmes
  Future<String?> getRandomTheme(
    String language,
    List<String> excludeThemeIds,
  ) async {
    try {
      final response = await _supabase.rpc('pvp_get_random_theme', params: {
        'p_language_code': language,
        'p_exclude_theme_ids': excludeThemeIds,
      });
      return response?.toString();
    } catch (e) {
      debugPrint('Error getting random theme: $e');
      return null;
    }
  }

  static int _toInt(dynamic value, int fallback) {
    if (value == null) return fallback;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? fallback;
  }
}
