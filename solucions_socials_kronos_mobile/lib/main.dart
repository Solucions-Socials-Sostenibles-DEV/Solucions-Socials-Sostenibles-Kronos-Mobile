import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
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
  await dotenv.load(fileName: ".env");
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
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    final SupabaseClient client = Supabase.instance.client;
    
    // 1. Obtener sesión actual
    final Session? currentSession = client.auth.currentSession;
    _session = currentSession;

    // 2. Escuchar cambios de estado
    client.auth.onAuthStateChange.listen((AuthState state) async {
      final bool wasLoggedOut = _session == null && state.session != null;
      
      if (mounted) {
        setState(() {
          _session = state.session;
          if (wasLoggedOut && state.session != null) {
            _showWelcome = true;
          }
        });
      }

      // Si tenemos sesión y se ha refrescado o iniciado, cargamos perfil
      if (state.session != null) {
        await _loadProfile();
      }
    });

    // 3. Gestionar estado inicial
    if (currentSession != null) {
      if (currentSession.isExpired) {
        // Si está expirada, esperamos a que el listener reciba el refresco
        // No llamamos a _loadProfile todavía
      } else {
        // Si es válida, cargamos perfil inmediatamente
        await _loadProfile();
      }
    } else {
      // No hay sesión, terminamos carga
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadProfile() async {
    if (!mounted) return;
    
    // Si ya estamos cargando o no hay sesión, salir
    if (_session == null) {
      setState(() {
        _profile = null;
        _isLoading = false;
      });
      return;
    }

    final SupabaseClient client = Supabase.instance.client;
    final String? userId = client.auth.currentUser?.id;
    
    if (userId == null) {
      setState(() {
        _profile = null;
        _isLoading = false;
      });
      return;
    }

    try {
      final List<Map<String, dynamic>> rows = await client
          .from('user_profiles')
          .select('name, role, onboarding_completed')
          .eq('id', userId)
          .limit(1);
          
      if (mounted) {
        setState(() {
          _profile = rows.isNotEmpty
              ? rows.first
              : <String, dynamic>{'onboarding_completed': true};
          _isLoading = false;
        });
      }
    } catch (e) {
      // Si el error es de autenticación (401), forzamos logout
      // en versiones recientes PostgrestException tiene 'code'
      if (e.toString().contains('401') || e.toString().contains('JWT')) {
        await client.auth.signOut();
      } else {
        // En otros errores, asumimos onboarding completado para no bloquear,
        // pero idealmente deberíamos mostrar un error.
        if (mounted) {
          setState(() {
            _profile = <String, dynamic>{'onboarding_completed': true};
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Si estamos esperando validación inicial o refresh
    if (_isLoading) {
       return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_session == null) {
      return const LoginScreen();
    }
    
    // Si session existe pero no profile cargado aún (y no estamos loading),
    // mostramos loading también.
    if (_profile == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    
    final bool onboardingDone = _profile?['onboarding_completed'] == true;
    if (!onboardingDone) {
      // _showWelcome gestionado en el estado
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
