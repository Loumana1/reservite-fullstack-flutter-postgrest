import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prbd_2526_c06/providers/security_provider.dart';
import 'package:prbd_2526_c06/views/pages/auth/login_page.dart';
import 'package:prbd_2526_c06/views/pages/auth/signup_page.dart';
import 'package:prbd_2526_c06/views/pages/client/home_client_page.dart';
import 'package:prbd_2526_c06/views/pages/manager/home_manager_page.dart';

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final securityNotifier = ref.read(securityProvider.notifier);

    return MaterialApp(
      title: 'ReserVite',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      initialRoute: securityNotifier.isLoggedIn ? '/login'
      : (securityNotifier.role == 'manager' ? '/home_manager' : '/home_client'),
      routes: {
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignupPage(),
        '/home_client': (context) => const HomeClientPage(),
        '/home_manager': (context) => const HomeManagerPage(),
      });
  }
}