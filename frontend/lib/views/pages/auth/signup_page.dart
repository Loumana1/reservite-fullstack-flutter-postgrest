
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prbd_2526_c06/core/Widgets/simulated_time_bar.dart';
import 'package:prbd_2526_c06/model/security.dart';
import 'package:prbd_2526_c06/model/user.dart';
import 'package:prbd_2526_c06/providers/security_provider.dart';
import 'package:prbd_2526_c06/providers/simulated_time_provider.dart';


class SignupPage extends ConsumerStatefulWidget {
  const SignupPage({super.key});

  @override
  ConsumerState<SignupPage> createState() => _SignupPageState();
}


class _SignupPageState extends ConsumerState<SignupPage> {

  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  Timer? _emailDebounce;
  Timer? _nameDebounce;
  bool _emailChecking = false;
  bool _nameChecking = false;
  bool? _emailAvailable;
  bool? _nameAvailable;
  String? _emailError;
  String? _nameError;
  String? _passwordError;
  String? _confirmError;
  bool _submitting = false;

  static const _debounce = Duration(milliseconds: 500);

  @override
  void dispose() {
    _emailDebounce?.cancel();
    _nameDebounce?.cancel();
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }


  void _onEmailChanged(String value) {
    _emailDebounce?.cancel();
    setState(() {
      _emailError = User.validateEmail(value);
      _emailAvailable = null;
      _emailChecking = _emailError == null && value.trim().isNotEmpty;
    });
    if (_emailError != null) return;

    _emailDebounce = Timer(_debounce, () async {
      try {
        final ok = await Security.checkEmailAvailable(value.trim());
        if (!mounted) return;
        setState(() {
          _emailAvailable = ok;
          _emailChecking = false;
          if (!ok) _emailError = 'Cet email est déjà utilisé';
        });
      } catch (_) {
        if (!mounted) return;
        setState(() => _emailChecking = false);
      }
    });
  }


  void _onFullNameChanged(String value) {
    _nameDebounce?.cancel();
    setState(() {
      _nameError = value.trim().isEmpty ? 'Le nom complet est requis' : null;
      _nameAvailable = null;
      _nameChecking = _nameError == null;
    });
    if (_nameError != null) return;

    _nameDebounce = Timer(_debounce, () async {
      try {
        final ok = await Security.checkFullNameAvailable(value.trim());
        if (!mounted) return;
        setState(() {
          _nameAvailable = ok;
          _nameChecking = false;
          if (!ok) _nameError = 'Ce nom est déjà utilisé';
        });
      } catch (_) {
        if (!mounted) return;
        setState(() => _nameChecking = false);
      }
    });
  }


  Future<void> _submit() async {
    setState(() {
      _emailError = User.validateEmail(_emailController.text);
      _passwordError = User.validatePassword(_passwordController.text);
      _confirmError = _passwordController.text != _confirmController.text
          ? 'Les mots de passe ne correspondent pas'
          : null;
    });
    if (_emailChecking || _nameChecking) return;
    if (_emailAvailable == false || _nameAvailable == false) return;
    if (_emailError != null ||
        _passwordError != null ||
        _confirmError != null) {
      return;
    }
    if (_fullNameController.text.trim().isEmpty) {
      setState(() => _nameError = 'Le nom complet est requis');
      return;
    }

    setState(() => _submitting = true);
    try {
      await ref.read(securityProvider.notifier).signupAndLogin(
        fullName: _fullNameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (!mounted) return;
      final role = ref.read(securityProvider.notifier).role;
      Navigator.pushReplacementNamed(
        context,
        role == 'manager' ? '/home_manager' : '/home_client',
      );
    } catch (_) {
      if (!mounted) return;
      final msg = ref.read(securityProvider.notifier).errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg ?? 'Inscription impossible')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Inscription'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Rafraîchir le temps simulé',
            onPressed: () => ref.read(simulatedTimeProvider.notifier).refresh(),
          ),
        ],
        elevation: 2,
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        surfaceTintColor: Colors.transparent,
        flexibleSpace: const Align(
          alignment: Alignment.topCenter,
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.only(top: 2.0),
              child: SimulatedTimeBar(),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 32),
                const Icon(Icons.person_add, size: 80, color: Colors.blue),
                const SizedBox(height: 32),
                const Text(
                  'Créez votre compte',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _fullNameController,
                  onChanged: _onFullNameChanged,
                  decoration: InputDecoration(
                    labelText: 'Nom complet',
                    errorText: _nameError,
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  onChanged: _onEmailChanged,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    errorText: _emailError,
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  onChanged: (v) => setState(() {
                    _passwordError = User.validatePassword(v);
                    _confirmError = _confirmController.text.isEmpty
                        && v != _confirmController.text
                        ? 'Les mots de passe en correspondent pas' : null ;
                  }),
                  decoration: InputDecoration(
                    labelText: 'Mot de passe',
                    errorText: _passwordError,
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmController,
                  onChanged: (v) => setState(() {
                    _confirmError = v != _passwordController.text
                        ? 'Les mots de pass ne correspondent pas' : null ;
                  }),
                  decoration: InputDecoration(
                    labelText: 'Confirmer le mot de passe',
                    errorText: _confirmError,
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock_outline),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Téléphone (optionnel)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _submitting
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : const Text('S\'inscrire'),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/login'),
                  child: const Text('Déjà un compte ? Se connecter'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}