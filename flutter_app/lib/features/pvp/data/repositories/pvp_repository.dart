import 'package:flutter/foundation.dart';
import '../../../../shared/services/supabase_service.dart';
import '../../../quiz/data/models/question_model.dart';
import '../models/pvp_match_model.dart';
import '../models/pvp_round_model.dart';

class PvPRepository {
  final _supabase = SupabaseService().client;

  /// Joins the matchmaking queue
  /// Returns a Map with matchFound, matchId, and opponentId
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

  /// Leaves the matchmaking queue
  Future<void> leaveMatchmaking(String userId) async {
    try {
      await _supabase.rpc('pvp_leave_queue', params: {
        'p_user_id': userId,
      });
    } catch (e) {
      debugPrint('Error leaving matchmaking: $e');
    }
  }

  /// Gets a match by its ID
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

  /// Gets random questions for a PvP round
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

  /// Gets questions by their IDs for a PvP round
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

  /// Creates a new round for a match
  /// Returns the ID of the created round
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

  /// Gets a specific round of a match
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

  /// Gets all rounds of a match
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

  /// Submits a player's answers for a round
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

  /// Gets a player's match history
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

  /// Gets a player's active matches
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

  /// Listens for real-time changes on a match
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

  /// Listens for changes on a specific round
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

  /// Updates the status of a match via secure RPC (server-side validation)
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

  /// Updates the status and current round of a match via secure RPC
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

  /// Cancels a match (if the opponent does not respond)
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

  /// Checks if a player is in the queue
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

  /// Gets a player's username
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

  /// Gets a player's username and preferred language in a single call
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

  /// Batch-fetches usernames for a list of user IDs. Returns a map userId → username.
  Future<Map<String, String>> getUsernamesBatch(List<String> userIds) async {
    if (userIds.isEmpty) return {};
    try {
      final response = await _supabase
          .from('user_stats')
          .select('user_id, username')
          .inFilter('user_id', userIds);
      final result = <String, String>{};
      for (final row in response as List) {
        final id = row['user_id'] as String?;
        final name = row['username'] as String?;
        if (id != null && name != null) result[id] = name;
      }
      return result;
    } catch (e) {
      debugPrint('Error getting usernames batch: $e');
      return {};
    }
  }

  /// Sends a PvP invitation to a recipient. Returns the invitation ID, or null on error.
  Future<String?> sendPvpInvitation(String senderId, String recipientId) async {
    try {
      final response = await _supabase.rpc('pvp_send_invitation', params: {
        'p_sender_id': senderId,
        'p_recipient_id': recipientId,
      });
      return response?.toString();
    } catch (e) {
      debugPrint('Error sending PvP invitation: $e');
      return null;
    }
  }

  /// Accepts or declines a PvP invitation.
  /// Returns the created match ID if accepted, null if declined or on error.
  Future<String?> respondToPvpInvitation(String invitationId, String userId, bool accept) async {
    try {
      final response = await _supabase.rpc('pvp_respond_invitation', params: {
        'p_invitation_id': invitationId,
        'p_user_id': userId,
        'p_accept': accept,
      });
      final list = List<Map<String, dynamic>>.from(response ?? []);
      if (list.isEmpty) return null;
      final row = list.first;
      if (row['accepted'] == true) return row['match_id']?.toString();
      return null;
    } catch (e) {
      debugPrint('Error responding to PvP invitation: $e');
      return null;
    }
  }

  /// Gets pending PvP invitations for a user.
  Future<List<Map<String, dynamic>>> getPendingInvitations(String userId) async {
    try {
      final response = await _supabase.rpc('pvp_get_pending_invitations', params: {
        'p_user_id': userId,
      });
      return List<Map<String, dynamic>>.from(response ?? []);
    } catch (e) {
      debugPrint('Error getting pending invitations: $e');
      return [];
    }
  }

  /// Sends a push notification to a player via the edge function (fire-and-forget).
  /// [notificationType] must be one of: 'match_found', 'your_turn', 'match_over', 'pvp_invitation', 'pvp_invitation_accepted'
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

  /// Gets a player's PvP statistics
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
      // If the PvP columns don't exist yet, return default values
      debugPrint('Error getting PvP stats: $e');
      return {
        'rating': 1000,
        'wins': 0,
        'losses': 0,
        'draws': 0,
      };
    }
  }

  /// Gets the global PvP leaderboard
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

  /// Checks the queue status when returning to the app
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

  /// Gets random questions for a specific theme
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

  /// Gets a random theme excluding certain themes
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
