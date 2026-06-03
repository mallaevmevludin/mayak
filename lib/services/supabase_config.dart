import 'supabase_local.dart';

class SupabaseConfig {
  static const String supabaseUrl = SupabaseLocal.url;
  static const String supabaseAnonKey = SupabaseLocal.anonKey;

  static bool get isConfigured {
    return supabaseUrl.trim().isNotEmpty &&
        supabaseAnonKey.trim().isNotEmpty &&
        supabaseUrl.startsWith('https://') &&
        !supabaseUrl.contains('your-project');
  }
}
