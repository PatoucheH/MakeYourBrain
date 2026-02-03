import 'dart:async';
import 'package:flutter/material.dart';
import '../repositories/lives_repository.dart';
import '../../../auth/data/repositories/auth_repository.dart';

class LivesProvider extends ChangeNotifier {
  final _repository = LivesRepository();
  final _authRepo = AuthRepository();

  int currentLives = 10;
  int maxLives = 10;
  int nextLifeInSeconds = 0;
  Timer? _timer;

  LivesProvider() {
    initialize();
  }

  Future<void> initialize() async {
    final userId = _authRepo.getCurrentUserId();
    if (userId != null) {
      await refresh();
      _startTimer();
    }
  }

  Future<void> refresh() async {
    final userId = _authRepo.getCurrentUserId();
    if (userId == null) return;

    try {
      final data = await _repository.getLives(userId);
      currentLives = data['current_lives'] ?? 10;
      maxLives = data['max_lives'] ?? 10;
      nextLifeInSeconds = data['next_life_in_seconds'] ?? 0;
      notifyListeners();
    } catch (e) {
      debugPrint('Error refreshing lives: $e');
    }
  }

  Future<bool> useLife() async {
    final userId = _authRepo.getCurrentUserId();
    if (userId == null) return false;

    try {
      final success = await _repository.useLife(userId);
      if (success) {
        await refresh();
      }
      return success;
    } catch (e) {
      debugPrint('Error using life: $e');
      return false;
    }
  }

  Future<void> addLivesFromAd() async {
    final userId = _authRepo.getCurrentUserId();
    if (userId == null) return;

    try {
      await _repository.addLivesFromAd(userId);
      await refresh();
    } catch (e) {
      debugPrint('Error adding lives: $e');
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (nextLifeInSeconds > 0) {
        nextLifeInSeconds--;
        notifyListeners();
      } else if (currentLives < maxLives) {
        refresh();
      }
    });
  }

  String getTimeUntilNextLife() {
    if (currentLives >= maxLives) return '';
    
    final minutes = nextLifeInSeconds ~/ 60;
    final seconds = nextLifeInSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}