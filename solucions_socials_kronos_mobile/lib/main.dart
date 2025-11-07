import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/supabase_config.dart';
import 'screens/auth/login_screen.dart';
import 'screens/ruta/ruta_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // App root
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SSS Kronos Mobile',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  Session? _session;
  Map<String, dynamic>? _profile;

  @override
  void initState() {
    super.initState();
    final SupabaseClient client = Supabase.instance.client;
    _session = client.auth.currentSession;
    _loadProfile();
    client.auth.onAuthStateChange.listen((AuthState state) async {
      setState(() => _session = state.session);
      await _loadProfile();
    });
  }

  Future<void> _loadProfile() async {
    final SupabaseClient client = Supabase.instance.client;
    final String? userId = client.auth.currentUser?.id;
    if (userId == null) {
      setState(() => _profile = null);
      return;
    }
    try {
      final List<Map<String, dynamic>> rows = await client
          .from('user_profiles')
          .select('name, role, onboarding_completed')
          .eq('id', userId)
          .limit(1);
      setState(() => _profile = rows.isNotEmpty ? rows.first : <String, dynamic>{'onboarding_completed': true});
    } catch (_) {
      setState(() => _profile = <String, dynamic>{'onboarding_completed': true});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_session == null) return const LoginScreen();
    if (_profile == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final bool onboardingDone = _profile?['onboarding_completed'] == true;
    if (!onboardingDone) return const OnboardingScreen();
    return const RutaScreen();
  }
}
