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
