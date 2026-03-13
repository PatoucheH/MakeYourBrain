import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../../shared/services/supabase_service.dart';
import '../../features/auth/data/repositories/auth_repository.dart';

class LanguageProvider extends ChangeNotifier {
  String _currentLanguage = 'en';
  final _authRepo = AuthRepository();
  final _supabase = SupabaseService().client;

  static const _cacheFileName = 'preferred_language.txt';

  String get currentLanguage => _currentLanguage;

  // ─── Cache helpers ────────────────────────────────────────────────────────

  Future<File> _getCacheFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_cacheFileName');
  }

  Future<String?> _readCache() async {
    try {
      final file = await _getCacheFile();
      if (!await file.exists()) return null;
      final value = (await file.readAsString()).trim();
      return (value == 'fr' || value == 'en') ? value : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeCache(String lang) async {
    try {
      final file = await _getCacheFile();
      await file.writeAsString(lang);
    } catch (_) {}
  }

  // ─── Public API ───────────────────────────────────────────────────────────

  /// Called at app startup. Loads from local cache (instant) or device locale.
  Future<void> initialize() async {
    final cached = await _readCache();
    if (cached != null) {
      _currentLanguage = cached;
    } else {
      final locale = WidgetsBinding.instance.platformDispatcher.locale;
      _currentLanguage = locale.languageCode == 'fr' ? 'fr' : 'en';
    }
    notifyListeners();
  }

  /// Called after login. Direct minimal query — does NOT go through getUserStats.
  Future<void> loadFromServer() async {
    if (!_authRepo.isLoggedIn()) return;
    try {
      final userId = _authRepo.getCurrentUserId();
      if (userId == null) return;
      final data = await _supabase
          .from('user_stats')
          .select('preferred_language')
          .eq('user_id', userId)
          .maybeSingle();
      final lang = data?['preferred_language'] as String?;
      if (lang == 'fr' || lang == 'en') {
        _currentLanguage = lang!;
        await _writeCache(lang);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[LanguageProvider] Failed to load language from server: $e');
    }
  }

  /// Changes the language, persists locally and to DB.
  Future<void> setLanguage(String languageCode) async {
    _currentLanguage = languageCode;
    await _writeCache(languageCode);
    notifyListeners();

    if (_authRepo.isLoggedIn()) {
      try {
        await _authRepo.updateLanguage(languageCode);
      } catch (e) {
        debugPrint('[LanguageProvider] Failed to sync language to server: $e');
      }
    }
  }

  String getLanguageName(String code) => code == 'en' ? 'English' : 'Français';
  String getLanguageFlag(String code) => code == 'en' ? '🇬🇧' : '🇫🇷';
}
