import 'package:flutter/material.dart';
import '../../features/auth/data/repositories/auth_repository.dart';

class LanguageProvider extends ChangeNotifier {
  String _currentLanguage = 'en';
  final _authRepo = AuthRepository();

  String get currentLanguage => _currentLanguage;

  // Initialiser au démarrage de l'app
  Future<void> initialize() async {
    // Détecter la langue du système
    final locale = WidgetsBinding.instance.platformDispatcher.locale;
    _currentLanguage = locale.languageCode == 'fr' ? 'fr' : 'en';
    notifyListeners();
  }

  // Changer la langue
  Future<void> setLanguage(String languageCode) async {
    _currentLanguage = languageCode;

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