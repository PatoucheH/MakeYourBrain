import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/supabase_config.dart';
import 'file_local_storage.dart';

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
        // FileLocalStorage replaces SharedPreferencesLocalStorage to avoid
        // the shared_preferences_foundation crash on iOS 26.
        authOptions: FlutterAuthClientOptions(
          localStorage: FileLocalStorage(),
        ),
      );
    } catch (e) {
      throw Exception('Failed to initialize Supabase: $e');
    }
  }
}