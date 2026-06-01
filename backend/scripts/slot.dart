import 'dart:convert';
import 'package:prbd_2526_c06/core/services/api_client.dart';

class Slot {
  const Slot({
    required this.datetime,
    required this.serviceId,
    required this.available,
    required this.capacityLeft,
  });

  final DateTime datetime;
  final int serviceId;
  final bool available;
  final int capacityLeft;

  factory Slot.fromJson(Map<String, dynamic> json) => Slot(
    datetime: DateTime.parse(json['datetime'].toString()),
    serviceId: json['service_id'] as int,
    available: json['available'] as bool,
    capacityLeft: json['capacity_left'] as int,
  );
}

class SlotsResponse {
  const SlotsResponse({
    required this.slots,
    required this.restaurantClosed,
    required this.userFullyBooked,
  });

  final List<Slot> slots;
  final bool restaurantClosed;
  final bool userFullyBooked;

  factory SlotsResponse.fromJson(Map<String, dynamic> json) {
    final raw = json['slots'] as List? ?? [];
    return SlotsResponse(
      slots: raw.map((e) => Slot.fromJson(e as Map<String, dynamic>)).toList(),
      restaurantClosed: json['restaurant_closed'] as bool? ?? false,
      userFullyBooked: json['user_fully_booked'] as bool? ?? false,
    );
  }

  static Future<SlotsResponse> fetch({
    required int restaurantId,
    required DateTime date,
    int? excludeReservationId,
  }) async {
    final iso = '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
    final r = await ApiClient.post('get_available_slots', body: json.encode({
      'restaurant_id': restaurantId,
      'target_date': iso,
      if (excludeReservationId != null) 'exclude_reservation_id': excludeReservationId,
    }));
    if (r.statusCode != 200) throw Exception('Failed to load slots');
    return SlotsResponse.fromJson(json.decode(r.body));
  }

  static Future<bool> checkCapacity({
    required int restaurantId,
    required DateTime datetime,
    required int guests,
    int? excludeReservationId,
  }) async {
    final r = await ApiClient.post('check_capacity', body: json.encode({
      'restaurant_id': restaurantId,
      'target_datetime': datetime.toIso8601String(),
      'guests': guests,
      if (excludeReservationId != null) 'exclude_reservation_id': excludeReservationId,
    }));
    if (r.statusCode != 200) throw Exception('Failed to check capacity');
    return json.decode(r.body) == true;
  }
}