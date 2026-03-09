import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// File-based [GotrueAsyncStorage] for PKCE code verifier persistence.
/// Replaces [SharedPreferencesGotrueAsyncStorage] to avoid the
/// shared_preferences_foundation hang on iOS 26.
class FileGotrueAsyncStorage extends GotrueAsyncStorage {
  static const _fileName = 'gotrue_async_storage.json';

  Future<File> _getFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_fileName');
  }

  Future<Map<String, String>> _readAll() async {
    try {
      final file = await _getFile();
      if (!await file.exists()) return {};
      final raw = await file.readAsString();
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map((k, v) => MapEntry(k, v as String));
    } catch (_) {
      return {};
    }
  }

  Future<void> _writeAll(Map<String, String> data) async {
    final file = await _getFile();
    await file.writeAsString(jsonEncode(data));
  }

  @override
  Future<String?> getItem({required String key}) async {
    final all = await _readAll();
    return all[key];
  }

  @override
  Future<void> setItem({required String key, required String value}) async {
    final all = await _readAll();
    all[key] = value;
    await _writeAll(all);
  }

  @override
  Future<void> removeItem({required String key}) async {
    final all = await _readAll();
    all.remove(key);
    await _writeAll(all);
  }
}
