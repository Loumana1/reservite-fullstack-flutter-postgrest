import 'dart:io';
import 'package:http/http.dart' as http;

String get baseUrl => kisWeb || !Platform.isAndroid
    ? 'http://localhost:3000/rpc'
    : 'http://10.0.2.2:3000/rpc';

class ApiClient {
  static final http.Client _client = http.Client();

  static Future<http.Response> get() async {}

  static Future<http.Response> post() async {}


}