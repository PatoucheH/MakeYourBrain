import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/auth/data/repositories/auth_repository.dart';

class LanguageProvider extends ChangeNotifier {
  String _currentLanguage = 'en';
  final _authRepo = AuthRepository();

  String get currentLanguage => _currentLanguage;

  // Initialiser au démarrage de l'app
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Charger la langue sauvegardée localement
    final savedLanguage = prefs.getString('app_language');
    
    if (savedLanguage != null) {
      // Utiliser la langue sauvegardée
      _currentLanguage = savedLanguage;
    } else {
      // Première fois : détecter la langue du système
      final locale = WidgetsBinding.instance.platformDispatcher.locale;
      _currentLanguage = locale.languageCode == 'fr' ? 'fr' : 'en';
      
      // Sauvegarder
      await prefs.setString('app_language', _currentLanguage);
    }
    
    notifyListeners();
  }

  // Changer la langue
  Future<void> setLanguage(String languageCode) async {
    _currentLanguage = languageCode;
    
    // Sauvegarder LOCALEMENT
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_language', languageCode);
    
    // Sauvegarder en DB si connecté
    if (_authRepo.isLoggedIn()) {
      await _authRepo.updateLanguage(languageCode);
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