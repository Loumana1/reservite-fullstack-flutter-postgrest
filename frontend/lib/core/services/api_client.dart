import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../tools/params.dart';

String get baseUrl => kIsWeb || !Platform.isAndroid
    ? 'http://localhost:3000/rpc'
    : 'http://10.0.2.2:3000/rpc';

class ApiClient {
  static final http.Client _client = http.Client();

  static Future<http.Response> get(String endpoint, {Map<String, String>?
  headers, bool anonymous = false}) async {
    final Uri url = Uri.parse('$baseUrl/$endpoint');
    return await _client.get(
      url,
      headers: {
        ...?headers,
        'Content-type' : 'application/json; charset=UTF-8',
        if (!anonymous) 'Authorization': 'Bearer ${Params.getValue('token')}'
      },
    );
  }

  static Future<http.Response> post(String endpoint, {Map<String, String>?
  headers, dynamic body, bool anonymous = false}) async {
    final Uri url = Uri.parse('$baseUrl/$endpoint');
    return await _client.post(
      url,
      headers: {
        ...?headers,
        'Content-Type': 'application/json; charset=UTF-8',
        if (!anonymous) 'Authorization': 'Bearer ${Params.getValue('token')}',
      },
      body : body,
    );
  }
  static String errorMessage(http.Response response) {
    try {
      final body = json.decode(response.body);
      if (body is Map && body['message'] != null) {
        return body['message'].toString();
      }
    } catch (_) {}
    return 'Erreur serveur (${response.statusCode})';
  }
}
