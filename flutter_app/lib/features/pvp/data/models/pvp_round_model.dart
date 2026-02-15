class PvPAnswerModel {
  final String questionId;
  final String answerId;
  final bool isCorrect;
  final String difficulty;
  final int points;
  final int timeSpent;

  PvPAnswerModel({
    required this.questionId,
    required this.answerId,
    required this.isCorrect,
    required this.difficulty,
    required this.points,
    required this.timeSpent,
  });

  factory PvPAnswerModel.fromJson(Map<String, dynamic> json) {
    return PvPAnswerModel(
      questionId: json['question_id'],
      answerId: json['answer_id'],
      isCorrect: json['is_correct'] ?? false,
      difficulty: json['difficulty'] ?? 'easy',
      points: json['points'] ?? 0,
      timeSpent: json['time_spent'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'question_id': questionId,
      'answer_id': answerId,
      'is_correct': isCorrect,
      'difficulty': difficulty,
      'points': points,
      'time_spent': timeSpent,
    };
  }

  PvPAnswerModel copyWith({
    String? questionId,
    String? answerId,
    bool? isCorrect,
    String? difficulty,
    int? points,
    int? timeSpent,
  }) {
    return PvPAnswerModel(
      questionId: questionId ?? this.questionId,
      answerId: answerId ?? this.answerId,
      isCorrect: isCorrect ?? this.isCorrect,
      difficulty: difficulty ?? this.difficulty,
      points: points ?? this.points,
      timeSpent: timeSpent ?? this.timeSpent,
    );
  }
}

class PvPRoundModel {
  final String id;
  final String matchId;
  final int roundNumber;
  final String? themeId;
  final List<String> questionIds;
  final int player1Score;
  final int player2Score;
  final List<PvPAnswerModel> player1Answers;
  final List<PvPAnswerModel> player2Answers;
  final DateTime? player1CompletedAt;
  final DateTime? player2CompletedAt;

  PvPRoundModel({
    required this.id,
    required this.matchId,
    required this.roundNumber,
    this.themeId,
    required this.questionIds,
    this.player1Score = 0,
    this.player2Score = 0,
    this.player1Answers = const [],
    this.player2Answers = const [],
    this.player1CompletedAt,
    this.player2CompletedAt,
  });

  factory PvPRoundModel.fromJson(Map<String, dynamic> json) {
    return PvPRoundModel(
      id: json['id'],
      matchId: json['match_id'],
      roundNumber: json['round_number'] ?? 1,
      themeId: json['theme_id'],
      questionIds: List<String>.from(json['question_ids'] ?? []),
      player1Score: json['player1_score'] ?? 0,
      player2Score: json['player2_score'] ?? 0,
      player1Answers: (json['player1_answers'] as List<dynamic>?)
              ?.map((answer) => PvPAnswerModel.fromJson(answer))
              .toList() ??
          [],
      player2Answers: (json['player2_answers'] as List<dynamic>?)
              ?.map((answer) => PvPAnswerModel.fromJson(answer))
              .toList() ??
          [],
      player1CompletedAt: json['player1_completed_at'] != null
          ? DateTime.parse(json['player1_completed_at'])
          : null,
      player2CompletedAt: json['player2_completed_at'] != null
          ? DateTime.parse(json['player2_completed_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'match_id': matchId,
      'round_number': roundNumber,
      'theme_id': themeId,
      'question_ids': questionIds,
      'player1_score': player1Score,
      'player2_score': player2Score,
      'player1_answers': player1Answers.map((a) => a.toJson()).toList(),
      'player2_answers': player2Answers.map((a) => a.toJson()).toList(),
      'player1_completed_at': player1CompletedAt?.toIso8601String(),
      'player2_completed_at': player2CompletedAt?.toIso8601String(),
    };
  }

  bool get isPlayer1Completed => player1CompletedAt != null;
  bool get isPlayer2Completed => player2CompletedAt != null;
  bool get isRoundCompleted => isPlayer1Completed && isPlayer2Completed;

  int getPlayerScore(String playerId, String player1Id) {
    return playerId == player1Id ? player1Score : player2Score;
  }

  List<PvPAnswerModel> getPlayerAnswers(String playerId, String player1Id) {
    return playerId == player1Id ? player1Answers : player2Answers;
  }

  bool hasPlayerCompleted(String playerId, String player1Id) {
    return playerId == player1Id ? isPlayer1Completed : isPlayer2Completed;
  }

  PvPRoundModel copyWith({
    String? id,
    String? matchId,
    int? roundNumber,
    String? themeId,
    List<String>? questionIds,
    int? player1Score,
    int? player2Score,
    List<PvPAnswerModel>? player1Answers,
    List<PvPAnswerModel>? player2Answers,
    DateTime? player1CompletedAt,
    DateTime? player2CompletedAt,
  }) {
    return PvPRoundModel(
      id: id ?? this.id,
      matchId: matchId ?? this.matchId,
      roundNumber: roundNumber ?? this.roundNumber,
      themeId: themeId ?? this.themeId,
      questionIds: questionIds ?? this.questionIds,
      player1Score: player1Score ?? this.player1Score,
      player2Score: player2Score ?? this.player2Score,
      player1Answers: player1Answers ?? this.player1Answers,
      player2Answers: player2Answers ?? this.player2Answers,
      player1CompletedAt: player1CompletedAt ?? this.player1CompletedAt,
      player2CompletedAt: player2CompletedAt ?? this.player2CompletedAt,
    );
  }
}
