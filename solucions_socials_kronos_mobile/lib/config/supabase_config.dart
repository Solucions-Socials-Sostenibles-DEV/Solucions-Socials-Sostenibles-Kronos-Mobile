class SupabaseConfig {
  // Puedes sobreescribir estos valores con --dart-define al ejecutar:
  // flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://zalnsacawwekmibhoiba.supabase.co',
  );

  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InphbG5zYWNhd3dla21pYmhvaWJhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTIwNTgxNDMsImV4cCI6MjA2NzYzNDE0M30.vJKSFJGTg19lYgk8O1fr3YJ5wyW_6uEEjQwF3_y6R4I',
  );
}
