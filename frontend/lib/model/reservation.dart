import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/services/api_client.dart';
import 'table.dart' as model;

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
    this.clientPhone,
    this.assignedTables = const [],
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
  final String? clientPhone;
  final List<model.Table> assignedTables;


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
      clientPhone: json['client_phone'] as String?,
      assignedTables: (json['assigned_tables'] as List<dynamic>? ?? [])
          .map((e) => model.Table.fromJson(e as Map<String, dynamic>))
          .toList(),
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
      'restaurant_id': ?restaurantId,
      'status_filter': ?statusFilter,
    }));
    if (r.statusCode != 200) throw Exception('Failed to load reservations');
    final List<dynamic> body = json.decode(r.body);
    return body.map((e) => Reservation.fromJson(e)).toList();
  }

  static Future<Reservation> save({
    required int restaurantId,
    required DateTime datetime,
    required int numberOfGuests,
    String? specialRequests,
    int? reservationId,
  }) async {
    final r = await ApiClient.post('save_reservation', body: json.encode({
      'restaurant_id': restaurantId,
      'datetime': datetime.toIso8601String(),
      'number_of_guests': numberOfGuests,
      if (specialRequests != null && specialRequests.isNotEmpty)
        'special_requests': specialRequests,
      'reservation_id': ?reservationId,
    }));
    if (r.statusCode != 200) throw Exception(_errorMessage(r));
    return Reservation.fromJson(json.decode(r.body));
  }

  Future<Reservation> cancel() async {
    final r = await ApiClient.post('cancel_reservation',
        body: json.encode({'reservation_id': id}));
    if (r.statusCode != 200) throw Exception(_errorMessage(r));
    return Reservation.fromJson(json.decode(r.body));
  }

  Future<Reservation> confirm(List<int> tableIds) async {
    final r = await ApiClient.post('confirm_reservation',
        body: json.encode({'reservation_id': id, 'table_ids': tableIds}));
    if (r.statusCode != 200) throw Exception(_errorMessage(r));
    return Reservation.fromJson(json.decode(r.body));
  }

  Future<Reservation> complete() async {
    final r = await ApiClient.post('complete_reservation',
        body: json.encode({'reservation_id': id}));
    if (r.statusCode != 200) throw Exception(_errorMessage(r));
    return Reservation.fromJson(json.decode(r.body));
  }

  static String _errorMessage(http.Response response) {
    final raw = ApiClient.errorMessage(response).toLowerCase();
    
    if (raw.contains('br-4') || raw.contains('horaire')) {
      return 'Modification impossible : en dehors des horaires du service.';
    }
    if (raw.contains('br-9') || raw.contains('statut')) {
      return 'Changement de statut invalide.';
    }
    if (raw.contains('br-12') || raw.contains('conflit') || raw.contains('conflict')) {
      return 'Conflit : une des tables est déjà réservée pour ce créneau.';
    }
    if (raw.contains('br-6') || raw.contains('br-2') || raw.contains('capacité') || raw.contains('capacity')) {
      return 'Capacité insuffisante pour le nombre de convives.';
    }
    if (raw.contains('permission denied') || raw.contains('accès refusé') || raw.contains('access denied')) {
      return 'Accès refusé.';
    }
    if (raw.contains('non trouvée') || raw.contains('not found')) {
      return 'Réservation introuvable.';
    }
    
    return 'Une erreur est survenue lors de l\'enregistrement de la réservation.';
  }
}