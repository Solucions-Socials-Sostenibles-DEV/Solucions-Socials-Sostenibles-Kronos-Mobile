import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/supabase_config.dart';
import 'screens/auth/login_screen.dart';
import 'screens/ruta/ruta_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/user/user_screen.dart';
import 'screens/welcome/welcome_screen.dart';
import 'package:provider/provider.dart';
import 'theme/theme_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );
  runApp(
    ChangeNotifierProvider<ThemeController>(
      create: (_) => ThemeController(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // App root
  @override
  Widget build(BuildContext context) {
    const Color primary = Color(0xFF4CAF51);
    final ThemeController themeController = context.watch<ThemeController>();
    return MaterialApp(
      title: 'SSS Kronos Mobile',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: primary),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primary,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: themeController.themeMode,
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
  bool _showWelcome = false;

  @override
  void initState() {
    super.initState();
    final SupabaseClient client = Supabase.instance.client;
    _session = client.auth.currentSession;
    _loadProfile();
    client.auth.onAuthStateChange.listen((AuthState state) async {
      final bool wasLoggedOut = _session == null && state.session != null;
      setState(() {
        _session = state.session;
        // Si el usuario acaba de terminar de logguearse
        if (wasLoggedOut && state.session != null) {
          _showWelcome = true;
        }
      });
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
      setState(
        () => _profile = rows.isNotEmpty
            ? rows.first
            : <String, dynamic>{'onboarding_completed': true},
      );
    } catch (_) {
      setState(
        () => _profile = <String, dynamic>{'onboarding_completed': true},
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_session == null) {
      setState(() => _showWelcome = false);
      return const LoginScreen();
    }
    if (_profile == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final bool onboardingDone = _profile?['onboarding_completed'] == true;
    if (!onboardingDone) {
      setState(() => _showWelcome = false);
      return const OnboardingScreen();
    }
    // Mostrar pantalla de bienvenida si es un login reciente
    if (_showWelcome) {
      return WelcomeScreen(
        onComplete: () {
          setState(() {
            _showWelcome = false;
          });
        },
      );
    }
    return const MainShell();
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  static const Color primary = Color(0xFF4CAF51);

  final List<Widget> _pages = const <Widget>[
    RutaScreen(),
    UserScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (int i) => setState(() => _index = i),
        indicatorColor: primary.withOpacity(0.15),
        destinations: const <NavigationDestination>[
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment),
            label: 'Hoja de Ruta',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Usuario',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Ajustes',
          ),
        ],
      ),
    );
  }
}
