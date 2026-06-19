import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:prbd_2526_c06/core/services/api_client.dart';

class Security {

  static Future<String?> login(String email , String password) async {
    final response = await ApiClient.post(
      'login' ,
      body: json.encode({'email': email, 'password': password}),
      anonymous: true,
    );
    if (response.statusCode != 200) {
      throw Exception(_errorMessage(response));
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
      throw Exception(_errorMessage(response));
    }
  }

  static Future<bool> checkEmailAvailable(String email, {int? userId}) async {
    final response = await ApiClient.post(
      'check_email_available',
      body: json.encode({
        'email': email.trim(),
        'user_id': ?userId,
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
        'user_id': ?userId,
      }),
      anonymous: true,
    );
    if (response.statusCode != 200) {
      throw Exception(ApiClient.errorMessage(response));
    }
    return json.decode(response.body) as bool;
  }

  static String _errorMessage(http.Response response) {
    final raw = ApiClient.errorMessage(response).toLowerCase();
    
    if (raw.contains('invalid password') || raw.contains('mot de passe')) {
      return 'Mot de passe incorrect.';
    }
    if (raw.contains('not found') || raw.contains('utilisateur')) {
      return 'Utilisateur introuvable.';
    }
    if (raw.contains('email_format') || raw.contains('email format')) {
      return 'Le format de l\'adresse email est invalide.';
    }
    if (raw.contains('unique_email') || raw.contains('already exists') || raw.contains('déjà utilisé')) {
      return 'Cette adresse email est déjà associée à un compte.';
    }
    if (raw.contains('phone_format')) {
      return 'Le format du numéro de téléphone est invalide.';
    }
    
    return 'Une erreur est survenue lors de l\'authentification.';
  }
}