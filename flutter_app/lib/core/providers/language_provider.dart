import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../../features/auth/data/repositories/auth_repository.dart';

class LanguageProvider extends ChangeNotifier {
  String _currentLanguage = 'en';
  final _authRepo = AuthRepository();

  String get currentLanguage => _currentLanguage;

  // Initialize at app startup (from the device locale)
  Future<void> initialize() async {
    final locale = WidgetsBinding.instance.platformDispatcher.locale;
    _currentLanguage = locale.languageCode == 'fr' ? 'fr' : 'en';
    // Defer notifyListeners to avoid a setState-during-build (called from initState)
    SchedulerBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  // Load the preferred language from the server after login
  Future<void> loadFromServer() async {
    if (!_authRepo.isLoggedIn()) return;
    try {
      final userStats = await _authRepo.getUserStats();
      final lang = userStats?.preferredLanguage;
      if (lang != null) {
        _currentLanguage = lang;
        // Always notify: initialize() may have failed to notify MaterialApp
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[LanguageProvider] Failed to load language from server: $e');
    }
  }

  // Change the language
  Future<void> setLanguage(String languageCode) async {
    _currentLanguage = languageCode;

    // Save to DB if logged in
    if (_authRepo.isLoggedIn()) {
      try {
        await _authRepo.updateLanguage(languageCode);
      } catch (e) {
        debugPrint('[LanguageProvider] Failed to sync language to server: $e');
      }
    }

    notifyListeners();
  }

  String getLanguageName(String code) {
    return code == 'en' ? 'English' : 'Français';
  }

  String getLanguageFlag(String code) {
    return code == 'en' ? '🇬🇧' : '🇫🇷';
  }
}