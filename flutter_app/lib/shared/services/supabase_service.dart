import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/supabase_config.dart';

/// In-memory LocalStorage for Supabase auth.
/// Prevents supabase_flutter from calling shared_preferences on iOS,
/// which crashes on iOS 26 due to a bug in shared_preferences_foundation.
class _InMemoryLocalStorage extends LocalStorage {
  String? _persistedSession;

  @override
  Future<void> initialize() async {}

  @override
  Future<String?> accessToken() async => _persistedSession;

  @override
  Future<bool> hasAccessToken() async => _persistedSession != null;

  @override
  Future<void> persistSession(String persistedSession) async {
    _persistedSession = persistedSession;
  }

  @override
  Future<void> removePersistedSession() async {
    _persistedSession = null;
  }
}

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  SupabaseClient get client => Supabase.instance.client;

  static Future<void> initialize() async {
    try {
      await Supabase.initialize(
        url: SupabaseConfig.url,
        anonKey: SupabaseConfig.anonKey,
        authOptions: FlutterAuthClientOptions(
          localStorage: _InMemoryLocalStorage(),
        ),
      );
    } catch (e) {
      throw Exception('Failed to initialize Supabase: $e');
    }
  }
}