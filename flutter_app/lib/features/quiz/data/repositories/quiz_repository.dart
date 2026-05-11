import '../../../../shared/services/supabase_service.dart';
import '../models/theme_model.dart';
import '../models/question_model.dart';

class QuizRepository {
  final _supabase = SupabaseService().client;

  // Get all themes in a language
  Future<List<ThemeModel>> getThemes(String languageCode) async {
    final response = await _supabase
        .from('themes_localized')
        .select()
        .eq('language_code', languageCode);

    return (response as List? ?? [])
        .map((json) => ThemeModel.fromJson(json))
        .toList();
  }

  // Get random questions for a theme with difficulty control
  Future<List<QuestionModel>> getQuestions({
    required String themeId,
    required String languageCode,
    int limit = 10,
    int easyPercent = 100,
    int mediumPercent = 0,
    int hardPercent = 0,
    String? userId,
  }) async {
    final response = await _supabase
        .rpc('get_random_questions', params: {
          'p_theme_id': themeId,
          'p_language_code': languageCode,
          'p_limit': limit,
          'p_easy_percent': easyPercent,
          'p_medium_percent': mediumPercent,
          'p_hard_percent': hardPercent,
          if (userId != null) 'p_user_id': userId,
        });

    return QuestionModel.ensureAnswerVariety(
      (response as List? ?? [])
          .map((json) => QuestionModel.fromJson(json))
          .toList(),
    );
  }

  // Save a user answer (without XP - XP is added at the end of the quiz)
  Future<void> saveUserAnswer({
    required String userId,
    required String questionId,
    required String selectedAnswerId,
    required bool isCorrect,
    required String languageUsed,
  }) async {
    // Save the answer
    await _supabase.from('user_answers').insert({
      'user_id': userId,
      'question_id': questionId,
      'selected_answer_id': selectedAnswerId,
      'is_correct': isCorrect,
      'language_used': languageUsed,
    });

    // Update stats
    await _supabase.rpc('increment_user_stats', params: {
      'p_user_id': userId,
      'p_is_correct': isCorrect,
    });
  }

  // Save a survival score (one row per run)
  Future<void> saveSurvivalScore({
    required String userId,
    required String themeId,
    required int score,
  }) async {
    await _supabase.from('survival_scores').insert({
      'user_id': userId,
      'theme_id': themeId,
      'score': score,
    });
  }

  // Returns the user's personal best for a given theme, or null if none
  Future<int?> getUserBestSurvivalScore({
    required String userId,
    required String themeId,
  }) async {
    final response = await _supabase
        .from('survival_scores')
        .select('score')
        .eq('user_id', userId)
        .eq('theme_id', themeId)
        .order('score', ascending: false)
        .limit(1);
    final list = response as List?;
    if (list == null || list.isEmpty) return null;
    return (list.first['score'] as num?)?.toInt();
  }

  // Top scores for a theme (best score per user)
  Future<List<Map<String, dynamic>>> getSurvivalLeaderboard({
    required String themeId,
    int limit = 20,
  }) async {
    final response = await _supabase.rpc('get_survival_leaderboard', params: {
      'p_theme_id': themeId,
      'p_limit': limit,
    });
    return (response as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  // Add XP directly (used by survival mode: 5 XP per correct answer)
  Future<void> addSurvivalXp({
    required String userId,
    required String themeId,
    required int xp,
  }) async {
    if (xp <= 0) return;
    await _supabase.rpc('add_bonus_xp', params: {
      'p_user_id': userId,
      'p_theme_id': themeId,
      'p_bonus_xp': xp,
    });
  }

  // Add XP at the end of the quiz — (questionId, answerId) pairs are
  // verified server-side to prevent cheating on the number of correct answers.
  Future<void> addQuizCompletionXp({
    required String userId,
    required String themeId,
    required List<String> questionIds,
    required List<String> answerIds,
    int bonusXp = 0,
  }) async {
    // The RPC verifies each (question_id, answer_id) pair against the answers table
    await _supabase.rpc('add_quiz_completion_xp', params: {
      'p_user_id': userId,
      'p_theme_id': themeId,
      'p_question_ids': questionIds,
      'p_answer_ids': answerIds,
    });

    // Add bonus XP (for timed quizzes)
    if (bonusXp > 0) {
      await _supabase.rpc('add_bonus_xp', params: {
        'p_user_id': userId,
        'p_theme_id': themeId,
        'p_bonus_xp': bonusXp,
      });
    }
  }
}