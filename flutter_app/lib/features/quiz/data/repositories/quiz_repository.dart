import '../../../../shared/services/supabase_service.dart';
import '../models/theme_model.dart';
import '../models/question_model.dart';

class QuizRepository {
  final _supabase = SupabaseService().client;

  // Récupérer tous les thèmes dans une langue
  Future<List<ThemeModel>> getThemes(String languageCode) async {
    final response = await _supabase
        .from('themes_localized')
        .select()
        .eq('language_code', languageCode);

    return (response as List)
        .map((json) => ThemeModel.fromJson(json))
        .toList();
  }

  // Récupérer des questions aléatoires pour un thème
  Future<List<QuestionModel>> getQuestions({
    required String themeId,
    required String languageCode,
    int limit = 10,
  }) async {
    final response = await _supabase
        .rpc('get_random_questions', params: {
          'p_theme_id': themeId,
          'p_language_code': languageCode,
          'p_limit': limit,
        });

    return (response as List)
        .map((json) => QuestionModel.fromJson(json))
        .toList();
  }

  // Sauvegarder la réponse d'un user
  Future<void> saveUserAnswer({
    required String userId,
    required String questionId,
    required String selectedAnswerId,
    required bool isCorrect,
    required String languageUsed,
  }) async {
    await _supabase.from('user_answers').insert({
      'user_id': userId,
      'question_id': questionId,
      'selected_answer_id': selectedAnswerId,
      'is_correct': isCorrect,
      'language_used': languageUsed,
    });
  }
}