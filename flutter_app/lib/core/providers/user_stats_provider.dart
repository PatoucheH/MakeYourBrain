import 'package:flutter/material.dart';
import '../../features/auth/data/repositories/auth_repository.dart';
import '../../features/auth/data/models/user_model.dart';
import '../../features/profile/data/repositories/profile_repository.dart';

class UserStatsProvider extends ChangeNotifier {
  final _authRepo = AuthRepository();
  final _profileRepo = ProfileRepository();

  UserModel? _userStats;
  Map<String, Map<String, dynamic>> _themeProgress = {};
  bool _isLoading = false;

  UserModel? get userStats => _userStats;
  Map<String, Map<String, dynamic>> get themeProgress => _themeProgress;
  bool get isLoading => _isLoading;

  int get currentStreak => _userStats?.currentStreak ?? 0;
  int get bestStreak => _userStats?.bestStreak ?? 0;
  int get pvpRating => _userStats?.pvpRating ?? 1000;
  int get totalQuestions => _userStats?.totalQuestions ?? 0;
  int get correctAnswers => _userStats?.correctAnswers ?? 0;

  Future<void> initialize() async {
    final userId = _authRepo.getCurrentUserId();
    if (userId == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final stats = await _authRepo.getUserStats();
      final progress = await _profileRepo.getProgressByTheme(userId);
      final progressMap = <String, Map<String, dynamic>>{};
      for (var p in progress) {
        progressMap[p['theme_id']] = p;
      }

      _userStats = stats;
      _themeProgress = progressMap;
    } catch (e) {
      debugPrint('Error initializing user stats: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> refresh() async {
    final userId = _authRepo.getCurrentUserId();
    if (userId == null) return;

    try {
      final stats = await _authRepo.getUserStats();
      final progress = await _profileRepo.getProgressByTheme(userId);
      final progressMap = <String, Map<String, dynamic>>{};
      for (var p in progress) {
        progressMap[p['theme_id']] = p;
      }

      _userStats = stats;
      _themeProgress = progressMap;
      notifyListeners();
    } catch (e) {
      debugPrint('Error refreshing user stats: $e');
    }
  }

  void clear() {
    _userStats = null;
    _themeProgress = {};
    _isLoading = false;
    notifyListeners();
  }
}
