import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:prbd_2526_c06/core/tools/params.dart';
import 'package:prbd_2526_c06/model/security.dart';

final securityProvider = AsyncNotifierProvider<SecurityNotifier , String?>(() => SecurityNotifier());

class SecurityNotifier extends AsyncNotifier<String?> {

  @override
  Future<String?> build() async {
    state = AsyncData(Params.getValue('token'));
    return state.value;
  }

  Future<void> login(String email, String password) async {
    state = const AsyncLoading();
    try {
      var token = await Security.login(email, password);
      Params.setValue('token', token);
      state = AsyncData(token);
    } catch (e) {
      state = AsyncError("Erreur de Connexion", StackTrace.current);
    }
  }

  void logOut() {
    Params.clearValue('token');
    state = const AsyncData(null);
  }

  bool get isLoggedIn => state.value != null;

  String? get role {
    if (state.value == null) return null;
    try {
      return JwtDecoder.decode(state.value!)['role'] as String?;
    } catch (_) {
      return null;
    }
  }


  Future<void> signupAndLogin({
    required String fullName,
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    try {
      await Security.signup(fullName, email, password);
      await login(email, password);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

    String? get errorMessage {
      final err = state.error;
      if (err == null) return null;
      if (err is Exception) return err.toString().replaceFirst('Exception: ', '');
      return err.toString();

    }

  }