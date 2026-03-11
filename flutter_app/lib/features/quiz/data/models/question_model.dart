import 'dart:math';

class QuestionModel {
  final String id;
  final String themeId;
  final String difficulty;
  final String questionText;
  final String? explanation;
  final String languageCode;
  final List<AnswerModel> answers;

  QuestionModel({
    required this.id,
    required this.themeId,
    required this.difficulty,
    required this.questionText,
    this.explanation,
    required this.languageCode,
    required this.answers,
  });

  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    final answers = ((json['answers'] as List?) ?? [])
        .map((a) => AnswerModel.fromJson(a))
        .toList()
      ..shuffle();
    return QuestionModel(
      id: json['question_id']?.toString() ?? '',
      themeId: json['theme_id']?.toString() ?? '',
      difficulty: json['difficulty']?.toString() ?? 'easy',
      questionText: json['question_text']?.toString() ?? '',
      explanation: json['explanation']?.toString(),
      languageCode: json['language_code']?.toString() ?? 'en',
      answers: answers,
    );
  }

  QuestionModel _withAnswers(List<AnswerModel> newAnswers) {
    return QuestionModel(
      id: id,
      themeId: themeId,
      difficulty: difficulty,
      questionText: questionText,
      explanation: explanation,
      languageCode: languageCode,
      answers: newAnswers,
    );
  }

  /// Ensures the correct answer is not at the same index
  /// for two consecutive questions in the list.
  static List<QuestionModel> ensureAnswerVariety(List<QuestionModel> questions) {
    if (questions.length <= 1) return questions;
    final rng = Random();
    final result = List<QuestionModel>.from(questions);
    for (int i = 1; i < result.length; i++) {
      final prevCorrectIdx =
          result[i - 1].answers.indexWhere((a) => a.isCorrect);
      final currAnswers = List<AnswerModel>.from(result[i].answers);
      final currCorrectIdx = currAnswers.indexWhere((a) => a.isCorrect);
      if (prevCorrectIdx == currCorrectIdx &&
          currAnswers.length > 1 &&
          currCorrectIdx != -1) {
        int newIdx;
        do {
          newIdx = rng.nextInt(currAnswers.length);
        } while (newIdx == currCorrectIdx);
        final tmp = currAnswers[currCorrectIdx];
        currAnswers[currCorrectIdx] = currAnswers[newIdx];
        currAnswers[newIdx] = tmp;
        result[i] = result[i]._withAnswers(currAnswers);
      }
    }
    return result;
  }
}

class AnswerModel {
  final String id;
  final String text;
  final bool isCorrect;
  final int displayOrder;

  AnswerModel({
    required this.id,
    required this.text,
    required this.isCorrect,
    required this.displayOrder,
  });

  factory AnswerModel.fromJson(Map<String, dynamic> json) {
    return AnswerModel(
      id: json['answer_id']?.toString() ?? '',
      text: json['answer_text']?.toString() ?? '',
      isCorrect: json['is_correct'] == true,
      displayOrder: (json['display_order'] as int?) ?? 0,
    );
  }
}
