import 'dart:async';
import 'dart:ffi';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prbd_2526_c06/core/tools/params.dart';
import 'package:prbd_2526_c06/model/security.dart';

final securityProvideer = AsyncNotifierProvider<SecurityNotifier , String?>(() => SecurityNotifier());

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
    } catch (e) {
      state = AsyncError("Erreur de Connexion", StackTrace.current);
    }
  }

}