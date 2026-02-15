enum PvPMatchStatus {
  waiting,
  player1ChoosingTheme,
  player1Turn,
  player2ChoosingTheme,
  player2Turn,
  completed,
  cancelled;

  static PvPMatchStatus fromString(String value) {
    switch (value) {
      case 'waiting':
        return PvPMatchStatus.waiting;
      case 'player1_choosing_theme':
        return PvPMatchStatus.player1ChoosingTheme;
      case 'player1_turn':
        return PvPMatchStatus.player1Turn;
      case 'player2_choosing_theme':
        return PvPMatchStatus.player2ChoosingTheme;
      case 'player2_turn':
        return PvPMatchStatus.player2Turn;
      case 'completed':
        return PvPMatchStatus.completed;
      case 'cancelled':
        return PvPMatchStatus.cancelled;
      default:
        return PvPMatchStatus.waiting;
    }
  }

  String toJson() {
    switch (this) {
      case PvPMatchStatus.waiting:
        return 'waiting';
      case PvPMatchStatus.player1ChoosingTheme:
        return 'player1_choosing_theme';
      case PvPMatchStatus.player1Turn:
        return 'player1_turn';
      case PvPMatchStatus.player2ChoosingTheme:
        return 'player2_choosing_theme';
      case PvPMatchStatus.player2Turn:
        return 'player2_turn';
      case PvPMatchStatus.completed:
        return 'completed';
      case PvPMatchStatus.cancelled:
        return 'cancelled';
    }
  }
}

class PvPMatchModel {
  final String id;
  final String player1Id;
  final String? player2Id;
  final PvPMatchStatus status;
  final int currentRound;
  final int player1TotalScore;
  final int player2TotalScore;
  final String? winnerId;
  final int player1RatingBefore;
  final int? player2RatingBefore;
  final int? player1RatingChange;
  final int? player2RatingChange;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? completedAt;

  PvPMatchModel({
    required this.id,
    required this.player1Id,
    this.player2Id,
    required this.status,
    this.currentRound = 1,
    this.player1TotalScore = 0,
    this.player2TotalScore = 0,
    this.winnerId,
    required this.player1RatingBefore,
    this.player2RatingBefore,
    this.player1RatingChange,
    this.player2RatingChange,
    required this.createdAt,
    this.startedAt,
    this.completedAt,
  });

  factory PvPMatchModel.fromJson(Map<String, dynamic> json) {
    return PvPMatchModel(
      id: json['id'],
      player1Id: json['player1_id'],
      player2Id: json['player2_id'],
      status: PvPMatchStatus.fromString(json['status'] ?? 'waiting'),
      currentRound: json['current_round'] ?? 1,
      player1TotalScore: json['player1_total_score'] ?? 0,
      player2TotalScore: json['player2_total_score'] ?? 0,
      winnerId: json['winner_id'],
      player1RatingBefore: json['player1_rating_before'] ?? 1000,
      player2RatingBefore: json['player2_rating_before'],
      player1RatingChange: json['player1_rating_change'],
      player2RatingChange: json['player2_rating_change'],
      createdAt: DateTime.parse(json['created_at']),
      startedAt: json['started_at'] != null
          ? DateTime.parse(json['started_at'])
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'player1_id': player1Id,
      'player2_id': player2Id,
      'status': status.toJson(),
      'current_round': currentRound,
      'player1_total_score': player1TotalScore,
      'player2_total_score': player2TotalScore,
      'winner_id': winnerId,
      'player1_rating_before': player1RatingBefore,
      'player2_rating_before': player2RatingBefore,
      'player1_rating_change': player1RatingChange,
      'player2_rating_change': player2RatingChange,
      'created_at': createdAt.toIso8601String(),
      'started_at': startedAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
    };
  }

  bool get isWaitingForPlayer2 => status == PvPMatchStatus.waiting;
  bool get isInProgress =>
      status == PvPMatchStatus.player1Turn ||
      status == PvPMatchStatus.player2Turn ||
      status == PvPMatchStatus.player1ChoosingTheme ||
      status == PvPMatchStatus.player2ChoosingTheme;
  bool get isCompleted => status == PvPMatchStatus.completed;
  bool get isCancelled => status == PvPMatchStatus.cancelled;

  bool get isChoosingTheme =>
      status == PvPMatchStatus.player1ChoosingTheme ||
      status == PvPMatchStatus.player2ChoosingTheme;

  bool isPlayerChoosingTheme(String playerId) {
    if (status == PvPMatchStatus.player1ChoosingTheme && playerId == player1Id) return true;
    if (status == PvPMatchStatus.player2ChoosingTheme && playerId == player2Id) return true;
    return false;
  }

  bool isPlayerTurn(String playerId) {
    if (status == PvPMatchStatus.player1Turn && playerId == player1Id) return true;
    if (status == PvPMatchStatus.player2Turn && playerId == player2Id) return true;
    return false;
  }

  String? getOpponentId(String playerId) {
    if (playerId == player1Id) return player2Id;
    if (playerId == player2Id) return player1Id;
    return null;
  }

  int getPlayerScore(String playerId) {
    if (playerId == player1Id) return player1TotalScore;
    if (playerId == player2Id) return player2TotalScore;
    return 0;
  }

  int? getPlayerRatingChange(String playerId) {
    if (playerId == player1Id) return player1RatingChange;
    if (playerId == player2Id) return player2RatingChange;
    return null;
  }

  PvPMatchModel copyWith({
    String? id,
    String? player1Id,
    String? player2Id,
    PvPMatchStatus? status,
    int? currentRound,
    int? player1TotalScore,
    int? player2TotalScore,
    String? winnerId,
    int? player1RatingBefore,
    int? player2RatingBefore,
    int? player1RatingChange,
    int? player2RatingChange,
    DateTime? createdAt,
    DateTime? startedAt,
    DateTime? completedAt,
  }) {
    return PvPMatchModel(
      id: id ?? this.id,
      player1Id: player1Id ?? this.player1Id,
      player2Id: player2Id ?? this.player2Id,
      status: status ?? this.status,
      currentRound: currentRound ?? this.currentRound,
      player1TotalScore: player1TotalScore ?? this.player1TotalScore,
      player2TotalScore: player2TotalScore ?? this.player2TotalScore,
      winnerId: winnerId ?? this.winnerId,
      player1RatingBefore: player1RatingBefore ?? this.player1RatingBefore,
      player2RatingBefore: player2RatingBefore ?? this.player2RatingBefore,
      player1RatingChange: player1RatingChange ?? this.player1RatingChange,
      player2RatingChange: player2RatingChange ?? this.player2RatingChange,
      createdAt: createdAt ?? this.createdAt,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}
