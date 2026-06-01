import 'dart:convert';

import 'package:prbd_2526_c06/core/services/api_client.dart';
import 'package:prbd_2526_c06/model/reservation.dart';
import 'package:prbd_2526_c06/model/restaurant.dart';

class ReservationService {
  static Future<Reservation?> getById(int reservationId) async {
    final response = await ApiClient.post(
      'get_reservation',
      body: json.encode({'reservation_id': reservationId}),
    );
    if (response.statusCode != 200) {
      throw Exception(ApiClient.errorMessage(response));
    }
    final data = json.decode(response.body);
    if (data == null) return null;
    return Reservation.fromJson(data as Map<String, dynamic>);
  }

  static Future<Restaurant?> getRestaurant(int restaurantId) async {
    final response = await ApiClient.post(
      'get_restaurant',
      body: json.encode({'restaurant_id': restaurantId}),
    );
    if (response.statusCode != 200) return null;
    final data = json.decode(response.body);
    if (data == null) return null;
    return Restaurant.fromJson(data as Map<String, dynamic>);
  }

  static Future<Reservation> cancel(int reservationId) async {
    final response = await ApiClient.post(
      'cancel_reservation',
      body: json.encode({'reservation_id': reservationId}),
    );
    if (response.statusCode != 200) {
      throw Exception(ApiClient.errorMessage(response));
    }
    return Reservation.fromJson(
      json.decode(response.body) as Map<String, dynamic>,
    );
  }
}
