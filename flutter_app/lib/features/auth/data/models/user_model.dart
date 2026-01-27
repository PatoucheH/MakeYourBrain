class UserModel {
  final String id;
  final String email;
  final String? username;
  final String? preferredLanguage;
  final int totalQuestions;
  final int correctAnswers;
  final int currentStreak;
  final int bestStreak;
  final DateTime? lastPlayedAt;
  final int pvpRating;
  final int pvpWins;
  final int pvpLosses;
  final int pvpDraws;

  UserModel({
    required this.id,
    required this.email,
    this.username,
    this.preferredLanguage,
    this.totalQuestions = 0,
    this.correctAnswers = 0,
    this.currentStreak = 0,
    this.bestStreak = 0,
    this.lastPlayedAt,
    this.pvpRating = 1000,
    this.pvpWins = 0,
    this.pvpLosses = 0,
    this.pvpDraws = 0,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['user_id'],
      email: json['email'] ?? '',
      username: json['username'],
      preferredLanguage: json['preferred_language'],
      totalQuestions: json['total_questions'] ?? 0,
      correctAnswers: json['correct_answers'] ?? 0,
      currentStreak: json['current_streak'] ?? 0,
      bestStreak: json['best_streak'] ?? 0,
      lastPlayedAt: json['last_played_at'] != null
          ? DateTime.parse(json['last_played_at'])
          : null,
      pvpRating: json['pvp_rating'] ?? 1000,
      pvpWins: json['pvp_wins'] ?? 0,
      pvpLosses: json['pvp_losses'] ?? 0,
      pvpDraws: json['pvp_draws'] ?? 0,
    );
  }

  double get accuracy {
    if (totalQuestions == 0) return 0;
    return (correctAnswers / totalQuestions) * 100;
  }

  int get pvpTotalGames => pvpWins + pvpLosses + pvpDraws;

  double get pvpWinRate {
    if (pvpTotalGames == 0) return 0;
    return (pvpWins / pvpTotalGames) * 100;
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? username,
    String? preferredLanguage,
    int? totalQuestions,
    int? correctAnswers,
    int? currentStreak,
    int? bestStreak,
    DateTime? lastPlayedAt,
    int? pvpRating,
    int? pvpWins,
    int? pvpLosses,
    int? pvpDraws,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      username: username ?? this.username,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      correctAnswers: correctAnswers ?? this.correctAnswers,
      currentStreak: currentStreak ?? this.currentStreak,
      bestStreak: bestStreak ?? this.bestStreak,
      lastPlayedAt: lastPlayedAt ?? this.lastPlayedAt,
      pvpRating: pvpRating ?? this.pvpRating,
      pvpWins: pvpWins ?? this.pvpWins,
      pvpLosses: pvpLosses ?? this.pvpLosses,
      pvpDraws: pvpDraws ?? this.pvpDraws,
    );
  }

  /// Retourne le nom d'affichage (pseudo ou email tronqué)
  String get displayName {
    if (username != null && username!.isNotEmpty) {
      return username!;
    }
    // Retourne la partie avant @ de l'email
    return email.split('@').first;
  }
}