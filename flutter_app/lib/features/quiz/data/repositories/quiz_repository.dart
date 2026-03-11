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
  }) async {
    final response = await _supabase
        .rpc('get_random_questions', params: {
          'p_theme_id': themeId,
          'p_language_code': languageCode,
          'p_limit': limit,
          'p_easy_percent': easyPercent,
          'p_medium_percent': mediumPercent,
          'p_hard_percent': hardPercent,
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