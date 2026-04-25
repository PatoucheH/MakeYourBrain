import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;
  bool get isDark => _themeMode == ThemeMode.dark;

  Future<void> initialize() async {
    _themeMode = await _loadFromFile();
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
    await _saveToFile(mode);
  }

  Future<ThemeMode> _loadFromFile() async {
    try {
      final file = await _prefsFile();
      if (!file.existsSync()) return ThemeMode.system;
      final content = await file.readAsString();
      final data = json.decode(content) as Map<String, dynamic>;
      switch (data['themeMode']) {
        case 'dark':
          return ThemeMode.dark;
        case 'light':
          return ThemeMode.light;
        default:
          return ThemeMode.system;
      }
    } catch (_) {
      return ThemeMode.system;
    }
  }

  Future<void> _saveToFile(ThemeMode mode) async {
    try {
      final file = await _prefsFile();
      final label = mode == ThemeMode.dark
          ? 'dark'
          : mode == ThemeMode.light
              ? 'light'
              : 'system';
      await file.writeAsString(json.encode({'themeMode': label}));
    } catch (_) {}
  }

  Future<File> _prefsFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/theme_preference.json');
  }
}
