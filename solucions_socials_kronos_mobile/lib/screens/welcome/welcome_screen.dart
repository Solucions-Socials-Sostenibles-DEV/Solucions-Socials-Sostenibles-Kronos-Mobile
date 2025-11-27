import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key, this.onComplete});

  final VoidCallback? onComplete;

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  String? _userName;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    try {
      final SupabaseClient client = Supabase.instance.client;
      final String? userId = client.auth.currentUser?.id;

      if (userId != null) {
        final List<dynamic> profileData = await client
            .from('user_profiles')
            .select('name')
            .eq('id', userId)
            .limit(1);

        if (mounted) {
          setState(() {
            _userName = profileData.isNotEmpty
                ? profileData.first['name'] as String?
                : null;
            _loading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _loading = false;
          });
        }
      }

      // Esperar unos segundos antes de navegar
      await Future<void>.delayed(const Duration(seconds: 3));

      if (mounted) {
        widget.onComplete?.call();
        // El AuthGate se encargará de navegar a MainShell
      }
    } catch (e) {
      // Si hay error, navegar de todas formas después del delay
      await Future<void>.delayed(const Duration(seconds: 3));
      if (mounted) {
        widget.onComplete?.call();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primary = Color(0xFF4CAF51);
    const Color primaryDark = Color(0xFF3C8E41);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: <Color>[primary, primaryDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  // Logo
                  Image.asset(
                    'assets/images/Logo Minimalist SSS High Opacity.PNG',
                    width: 180,
                    height: 180,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 40),
                  // Mensaje de bienvenida
                  Text(
                    _loading
                        ? 'Bienvenido/a'
                        : 'Bienvenido/a${_userName != null ? ' $_userName' : ''}',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  // Barra de carga
                  const SizedBox(
                    width: 200,
                    child: LinearProgressIndicator(
                      backgroundColor: Colors.white30,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      minHeight: 4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
