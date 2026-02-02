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
    final answers = (json['answers'] as List)
        .map((a) => AnswerModel.fromJson(a))
        .toList()
      ..shuffle();
    return QuestionModel(
      id: json['question_id'],
      themeId: json['theme_id'],
      difficulty: json['difficulty'],
      questionText: json['question_text'],
      explanation: json['explanation'],
      languageCode: json['language_code'],
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
      id: json['answer_id'],
      text: json['answer_text'],
      isCorrect: json['is_correct'],
      displayOrder: json['display_order'],
    );
  }
}