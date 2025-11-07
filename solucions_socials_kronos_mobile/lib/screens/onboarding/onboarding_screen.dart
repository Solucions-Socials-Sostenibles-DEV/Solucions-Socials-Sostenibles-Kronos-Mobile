import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  bool _saving = false;
  String? _error;

  Future<void> _complete() async {
    if (_saving) return;
    setState(() { _saving = true; _error = null; });
    try {
      final SupabaseClient client = Supabase.instance.client;
      final String? userId = client.auth.currentUser?.id;
      if (userId == null) return;
      await client
          .from('user_profiles')
          .update(<String, dynamic>{'onboarding_completed': true})
          .eq('id', userId);
      // AuthGate volverá a cargar el perfil y nos llevará a Ruta
    } catch (e) {
      setState(() => _error = 'No se pudo completar el onboarding');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Onboarding')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Text('Completa el onboarding para continuar.'),
                const SizedBox(height: 16),
                if (_error != null) ...<Widget>[
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 8),
                ],
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _complete,
                    child: _saving
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Completar'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


