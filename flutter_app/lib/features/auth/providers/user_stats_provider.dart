import 'package:flutter/foundation.dart';
import '../data/repositories/auth_repository.dart';

class UserStatsProvider extends ChangeNotifier {
  final _authRepo = AuthRepository();

  int _effectiveStreak = 0;
  int _bestStreak = 0;

  int get effectiveStreak => _effectiveStreak;
  int get bestStreak => _bestStreak;

  Future<void> loadFromServer() async {
    try {
      final stats = await _authRepo.getUserStats();
      _effectiveStreak = stats?.effectiveStreak ?? 0;
      _bestStreak = stats?.bestStreak ?? 0;
      notifyListeners();
    } catch (e) {
      debugPrint('[UserStatsProvider] loadFromServer error: $e');
    }
  }

  void reset() {
    _effectiveStreak = 0;
    _bestStreak = 0;
    notifyListeners();
  }
}
