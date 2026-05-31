import 'dart:convert';

import '../core/services/api_client.dart';

class Reservation {
  const Reservation({
    required this.id,
    required this.clientId,
    required this.restaurantId,
    required this.datetime,
    required this.numberOfGuests,
    required this.status,
    this.specialRequests,
    this.restaurantName,
    this.restaurantCity,
    this.clientFullName,
    this.clientEmail,
  });

  final int id;
  final int clientId;
  final int restaurantId;
  final DateTime datetime;
  final int numberOfGuests;
  final String status;
  final String? specialRequests;
  final String? restaurantName;
  final String? restaurantCity;
  final String? clientFullName;
  final String? clientEmail;


  factory Reservation.fromJson(Map<String, dynamic> json) {
    return Reservation(
      id: json['id'] as int,
      clientId: json['client'] as int,
      restaurantId: json['restaurant'] as int,
      datetime: DateTime.parse(json['datetime'].toString()),
      numberOfGuests: json['number_of_guests'] as int,
      status: json['status'] as String,
      specialRequests: json['special_requests'] as String?,
      restaurantName: json['restaurant_name'] as String?,
      restaurantCity: json['restaurant_city'] as String?,
      clientFullName: json['client_full_name'] as String?,
      clientEmail: json['client_email'] as String?,

    );
  }

  bool get canEdit => status == 'pending' || status == 'confirmed';
  bool get canCancel => status == 'pending' || status == 'confirmed';
  bool get canConfirm => status == 'pending';
  bool get canComplete => status == 'confirmed';

  static Future<Reservation> getById(int id) async {
    final r = await ApiClient.post('get_reservation',
        body: json.encode({'reservation_id': id}));
    if (r.statusCode != 200) throw Exception('Failed to load reservation');
    return Reservation.fromJson(json.decode(r.body));
  }

  static Future<List<Reservation>> getAll({int? restaurantId, String? statusFilter}) async {
    final r = await ApiClient.post('get_reservations', body: json.encode({
      if (restaurantId != null) 'restaurant_id': restaurantId,
      if (statusFilter != null) 'status_filter': statusFilter,
    }));
    if (r.statusCode != 200) throw Exception('Failed to load reservations');
    final List<dynamic> body = json.decode(r.body);
    return body.map((e) => Reservation.fromJson(e)).toList();
  }
}