import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:prbd_2526_c06/core/services/api_client.dart';
import 'package:prbd_2526_c06/model/user.dart';
import 'package:prbd_2526_c06/providers/security_provider.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin(Future<void> Function() loginAction) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    await loginAction();

    if (!mounted) return;

    final notifier = ref.read(securityProvider.notifier);
    if (notifier.isLoggedIn) {
      navigator.pushReplacementNamed(
        notifier.role == 'manager' ? '/home_manager' : '/home_client',
      );
      return;
    }


    final message = ref
        .read(securityProvider.notifier)
        .errorMessage;
    messenger.showSnackBar(
      SnackBar(content: Text(message ?? 'Identifiants incorrects')),
    );
  }

    Future<void> _submitLogin() async {
      final emailError = User.validateEmail(_emailController.text);
      if (emailError != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(emailError)),
        );
        return;
      }

      await _handleLogin(
            () =>
            ref.read(securityProvider.notifier).login(
              _emailController.text.trim(),
              _passwordController.text,
            ),
      );
    }

    Future<void> _loginAs(String email) async {
      await _handleLogin(
            () =>
            ref.read(securityProvider.notifier).login(email, 'Password1,'),
      );
    }

    Future<void> _resetDatabase() async {
      final messenger = ScaffoldMessenger.of(context);
      await ApiClient.post('reset_database', anonymous: true);
      messenger.showSnackBar(
        const SnackBar(content: Text('Base reinitialisee !')),
      );
    }

    @override
    Widget build(BuildContext context) {
      final theme = Theme.of(context);
      final simulatedTime = DateTime(2024, 12, 4, 16, 0);

      return Scaffold(
        appBar: AppBar(
          title: const Text('Connexion'),
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Rafraîchir les données',
              onPressed: () {},
            ),
          ],
          elevation: 2,
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          surfaceTintColor: Colors.transparent,
          flexibleSpace: Align(
            alignment: Alignment.topCenter,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(top: 2.0),
                child: Tooltip(
                  message:
                  'Date/heure simulée utilisée pour les tests.\nCliquez pour modifier.',
                  child: Text(
                    DateFormat('EEEE dd/MM/yyyy HH:mm', 'fr_FR')
                        .format(simulatedTime),
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[400],
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Form(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 32),
                        const Icon(
                          Icons.restaurant,
                          size: 80,
                          color: Colors.blue,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Connectez-vous',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.email),
                          ),
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _passwordController,
                          decoration: const InputDecoration(
                            labelText: 'Mot de passe',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.lock),
                          ),
                          obscureText: true,
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _submitLogin,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text('Se connecter'),
                        ),
                        const SizedBox(height: 6),
                        TextButton(
                          onPressed: () =>
                              Navigator.pushNamed(context, '/signup'),
                          child: const Text(
                            'Pas encore de compte ? S\'inscrire',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Divider(),
                    const SizedBox(height: 8),
                    const Text(
                      'Raccourcis de débogage',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Se connecter directement en tant que :',
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _loginAs('brlacroix@epfc.eu'),
                            icon: const Icon(Icons.person),
                            label: const Text('Client (Bruno)'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _loginAs('mamichel@epfc.eu'),
                            icon: const Icon(Icons.person),
                            label: const Text('Client (Marc)'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _loginAs('bepenelle@epfc.eu'),
                            icon: const Icon(Icons.manage_accounts),
                            label: const Text('Manager (Benoît)'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _loginAs('gedielman@epfc.eu'),
                            icon: const Icon(Icons.manage_accounts),
                            label: const Text('Manager (Geoffrey)'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _resetDatabase,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Réinitialiser la base de données'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

