import 'dart:convert';

import 'package:prbd_2526_c06/core/services/api_client.dart';

class TimeService {
  static Future<DateTime> getSimulatedTime() async {
    final response = await ApiClient.post(
      'get_simulated_time',
      body: json.encode({}),
      anonymous: true,
    );
    if (response.statusCode != 200) {
      throw Exception('Impossible de lire le temps simulé');
    }
    return DateTime.parse(json.decode(response.body).toString());
  }
  static Future<DateTime> setSimulatedTime(DateTime newTime) async {
    final response = await ApiClient.post(
      'set_simulated_time',
      body: json.encode({
        'new_time': newTime.toIso8601String(),
      }),
      anonymous: true,
    );
    if (response.statusCode != 200) {
      throw Exception(ApiClient.errorMessage(response));
    }
    return DateTime.parse(json.decode(response.body).toString());
  }
}