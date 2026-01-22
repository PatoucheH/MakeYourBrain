class UserModel {
  final String id;
  final String email;
  final String? preferredLanguage;
  final int totalQuestions;
  final int correctAnswers;
  final int currentStreak;
  final int bestStreak;
  final DateTime? lastPlayedAt;

  UserModel({
    required this.id,
    required this.email,
    this.preferredLanguage,
    this.totalQuestions = 0,
    this.correctAnswers = 0,
    this.currentStreak = 0,
    this.bestStreak = 0,
    this.lastPlayedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['user_id'],
      email: json['email'] ?? '',
      preferredLanguage: json['preferred_language'],
      totalQuestions: json['total_questions'] ?? 0,
      correctAnswers: json['correct_answers'] ?? 0,
      currentStreak: json['current_streak'] ?? 0,
      bestStreak: json['best_streak'] ?? 0,
      lastPlayedAt: json['last_played_at'] != null 
          ? DateTime.parse(json['last_played_at'])
          : null,
    );
  }

  double get accuracy {
    if (totalQuestions == 0) return 0;
    return (correctAnswers / totalQuestions) * 100;
  }
}