import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// File-based [LocalStorage] for supabase_flutter.
/// Replaces SharedPreferencesLocalStorage to avoid the shared_preferences_foundation
/// crash on iOS 26 (EXC_BAD_ACCESS in swift_getObjectType during plugin registration).
class FileLocalStorage extends LocalStorage {
  static const _fileName = 'supabase_session.json';

  Future<File> _getFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_fileName');
  }

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> hasAccessToken() async {
    final file = await _getFile();
    return file.exists();
  }

  @override
  Future<String?> accessToken() async {
    final file = await _getFile();
    if (!await file.exists()) return null;
    return file.readAsString();
  }

  @override
  Future<void> persistSession(String persistSessionString) async {
    final file = await _getFile();
    await file.writeAsString(persistSessionString);
  }

  @override
  Future<void> removePersistedSession() async {
    final file = await _getFile();
    if (await file.exists()) await file.delete();
  }
}
