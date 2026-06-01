import 'dart:convert';

import 'package:prbd_2526_c06/core/services/api_client.dart';

class Security {

  static Future<String?> login(String email , String password) async {
    final response = await ApiClient.post(
      'login' ,
      body: json.encode({'email': email, 'password': password}),
      anonymous: true,
    );
    if (response.statusCode != 200) {
      throw Exception(ApiClient.errorMessage(response));
    }
    final token = json.decode(response.body)['token'];
    if (token == null || token.toString().isEmpty) {
      throw Exception('Réponse login invalide');
    }
    return token as String;
  }
  static Future<void> signup(String fullName, String email , String password) async {
    final response = await ApiClient.post(
      'signup' ,
      body: json.encode({'full_name': fullName, 'email' : email, 'password' : password}),
      anonymous: true
    );
    if (response.statusCode != 204) {
      throw Exception(ApiClient.errorMessage(response));
    }
  }

  static Future<bool> checkEmailAvailable(String email, {int? userId}) async {
    final response = await ApiClient.post(
      'check_email_available',
      body: json.encode({
        'email': email.trim(),
        if (userId != null) 'user_id': userId,
      }),
      anonymous: true,
    );
    if (response.statusCode != 200) {
      throw Exception(ApiClient.errorMessage(response));
    }
    return json.decode(response.body) as bool;
  }

  static Future<bool> checkFullNameAvailable(
      String fullName, {
        int? userId,
      }) async {
    final response = await ApiClient.post(
      'check_full_name_available',
      body: json.encode({
        'full_name': fullName.trim(),
        if (userId != null) 'user_id': userId,
      }),
      anonymous: true,
    );
    if (response.statusCode != 200) {
      throw Exception(ApiClient.errorMessage(response));
    }
    return json.decode(response.body) as bool;
  }
}