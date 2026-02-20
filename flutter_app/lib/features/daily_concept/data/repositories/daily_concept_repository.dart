import '../../../../shared/services/supabase_service.dart';
import '../../../quiz/data/models/question_model.dart';
import '../models/daily_concept_model.dart';

class DailyConceptRepository {
  final _supabase = SupabaseService().client;

  Future<DailyConceptModel?> getDailyConcept(String userId, String languageCode) async {
    final response = await _supabase.rpc('get_daily_concept', params: {
      'p_user_id': userId,
      'p_language_code': languageCode,
    });

    if (response == null || (response is List && response.isEmpty)) {
      return null;
    }

    final data = response is List ? response.first : response;
    return DailyConceptModel.fromJson(data);
  }

  Future<List<QuestionModel>> getDailyQuestions({
    required String languageCode,
    int limit = 10,
    int easyPercent = 100,
    int mediumPercent = 0,
    int hardPercent = 0,
  }) async {
    final response = await _supabase.rpc('get_daily_questions', params: {
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

  Future<void> completeDailyConcept(String userId) async {
    await _supabase.rpc('complete_daily_concept', params: {
      'p_user_id': userId,
    });
  }
}
