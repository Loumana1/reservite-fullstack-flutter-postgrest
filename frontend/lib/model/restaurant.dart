import 'dart:convert';

import '../core/app_config.dart';
import '../core/services/api_client.dart';

class Restaurant {


  const Restaurant({
    required this.id,
    required this.name,
    required this.address,
    required this.city,
    required this.phone,
    this.description,
    this.rating,
    this.priceRange,
    required this.slotDuration,
    this.lastReservationDate,
    this.pendingRequests,
  });

  final int id;
  final String name;
  final String address;
  final String city;
  final String phone;
  final String? description;
  final double? rating;
  final int? priceRange;
  final int slotDuration;
  final DateTime? lastReservationDate;
  final int? pendingRequests;

  factory Restaurant.fromJson(Map<String, dynamic> json) {
    return Restaurant(
      id: json['id'] as int,
      name: json['name'] as String,
      address: json['address'] as String? ?? '',
      city: json['city'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      description: json['description'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
      priceRange: json['price_range'] as int?,
      slotDuration: json['slot_duration'] as int? ?? 30,
      lastReservationDate: json['last_reservation_date'] != null
          ? DateTime.parse(json['last_reservation_date'].toString())
          : null,
      pendingRequests: json['pending_requests'] as int?,
    );
  }
  Restaurant copyWith({
    DateTime? lastReservationDate,
    int? pendingRequests,
  }) {
    return Restaurant(
      id: id,
      name: name,
      address: address,
      city: city,
      phone: phone,
      description: description,
      rating: rating,
      priceRange: priceRange,
      slotDuration: slotDuration,
      lastReservationDate: lastReservationDate ?? this.lastReservationDate,
      pendingRequests: pendingRequests ?? this.pendingRequests,
    );
  }

  static Future<List<Restaurant>> getAll({String? searchFilter}) async {
    final r = await ApiClient.post('get_restaurants', body: json.encode({
      'search_filter': ?searchFilter,
      'limit_count': AppConfig.maxSearchResults,
    }));
    if (r.statusCode != 200) throw Exception('Impossible de charger la liste des restaurants.');
    final List<dynamic> body = json.decode(r.body);
    return body.map((e) => Restaurant.fromJson(e)).toList();
  }

  static Future<Restaurant> getById(int id) async {
    final r = await ApiClient.post('get_restaurant',
        body: json.encode({'restaurant_id': id}));
    if (r.statusCode != 200) throw Exception('Impossible de charger la liste des restaurants.');
    return Restaurant.fromJson(json.decode(r.body));
  }

}