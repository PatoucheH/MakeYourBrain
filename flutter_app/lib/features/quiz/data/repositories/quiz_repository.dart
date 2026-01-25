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

  // Récupérer des questions aléatoires pour un thème avec contrôle de difficulté
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

    return (response as List)
        .map((json) => QuestionModel.fromJson(json))
        .toList();
  }

  // Sauvegarder la réponse d'un user (sans XP - l'XP est ajouté à la fin du quiz)
  Future<void> saveUserAnswer({
    required String userId,
    required String questionId,
    required String selectedAnswerId,
    required bool isCorrect,
    required String languageUsed,
  }) async {
    // Sauvegarder la réponse
    await _supabase.from('user_answers').insert({
      'user_id': userId,
      'question_id': questionId,
      'selected_answer_id': selectedAnswerId,
      'is_correct': isCorrect,
      'language_used': languageUsed,
    });

    // Mettre à jour les stats
    await _supabase.rpc('increment_user_stats', params: {
      'p_user_id': userId,
      'p_is_correct': isCorrect,
    });
  }

  // Ajouter l'XP à la fin du quiz pour toutes les bonnes réponses
  Future<void> addQuizCompletionXp({
    required String userId,
    required String themeId,
    required int correctAnswers,
  }) async {
    // Appeler add_theme_xp pour chaque bonne réponse
    for (int i = 0; i < correctAnswers; i++) {
      await _supabase.rpc('add_theme_xp', params: {
        'p_user_id': userId,
        'p_theme_id': themeId,
        'p_is_correct': true,
      });
    }
  }
}