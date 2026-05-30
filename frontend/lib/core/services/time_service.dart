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
}