import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/auth/data/repositories/auth_repository.dart';

class LanguageProvider extends ChangeNotifier {
  String _currentLanguage = 'en';
  final _authRepo = AuthRepository();

  String get currentLanguage => _currentLanguage;

  // Initialiser au démarrage de l'app
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLanguage = prefs.getString('app_language');

      if (savedLanguage != null) {
        _currentLanguage = savedLanguage;
        notifyListeners();
        return;
      }

      // Première fois : détecter la langue du système
      final locale = WidgetsBinding.instance.platformDispatcher.locale;
      _currentLanguage = locale.languageCode == 'fr' ? 'fr' : 'en';

      await prefs.setString('app_language', _currentLanguage);
    } catch (e) {
      debugPrint('[LanguageProvider] SharedPreferences failed, using device locale: $e');
      // Fallback : détecter la langue du système sans sauvegarder
      final locale = WidgetsBinding.instance.platformDispatcher.locale;
      _currentLanguage = locale.languageCode == 'fr' ? 'fr' : 'en';
    }

    notifyListeners();
  }

  // Changer la langue
  Future<void> setLanguage(String languageCode) async {
    _currentLanguage = languageCode;
    
    // Sauvegarder LOCALEMENT
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('app_language', languageCode);
    } catch (e) {
      debugPrint('[LanguageProvider] SharedPreferences failed to save language: $e');
    }
    
    // Sauvegarder en DB si connecté
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