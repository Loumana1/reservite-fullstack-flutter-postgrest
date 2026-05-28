import 'dart:convert';

import 'package:prbd_2526_c06/core/services/api_client.dart';

class Security {

  static Future<String?> login(String email , String password) async {
    final response = await ApiClient.post(
      'login' ,
      body: json.encode({'email': email, 'password': password}),
      anonymous: true,
    );
    if (response.statusCode != 200) throw Exception('Echec de connexion');
    return json.decode(response.body)['token'];
  }

  static Future<void> signup(String fullName, String email , String password) async {
    final response = await ApiClient.post(
      'signup' ,
      body: json.encode({'full_name': fullName, 'email' : email, 'password' : password}),
      anonymous: true
    );
    if (response.statusCode != 204) throw Exception('Echec de l\'inscription');
  }
}