import 'dart:convert';

import '../core/services/api_client.dart';

class Service {

  final int id;
  final int restaurantId;
  final int dayOfWeek;
  final String startTime;
  final String endTime;

  Service({required this.id, required this.restaurantId, required this.dayOfWeek, required this.startTime, required this.endTime });

  factory Service.fromJson(Map<String, dynamic> json) {
    return Service(
      id: json['id'],
      restaurantId: json['restaurant'] ?? json['restaurantId'],
      dayOfWeek: json['day_of_week'] ?? json['dayOfWeek'],
      startTime: json['start_time'] ?? json['startTime'],
      endTime: json['end_time'] ?? json['endTime'],
    );
  }

  static Future<Service> save(int? id, int restaurantId, int dayOfWeek, String startTime, String endTime) async {
    final response = await ApiClient.post('save_service', body: json.encode({
      'service_id': ?id,
      'restaurant_id': restaurantId,
      'day_of_week': dayOfWeek,
      'start_time': startTime,
      'end_time': endTime,
    }));
    if (response.statusCode == 200) {
      return Service.fromJson(json.decode(response.body));
    }
    throw Exception('Failed to save service');
  }

  Future<void> delete() async {
    final response = await ApiClient.post('delete_service', body: json.encode({'service_id': id}));
    if (response.statusCode != 204 && response.statusCode != 200) {
      throw Exception('Failed to delete service');
    }
  }
}
