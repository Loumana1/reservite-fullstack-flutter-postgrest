import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/services/api_client.dart';
import 'reservation.dart';

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

  static Future<List<Service>> getByRestaurant(int restaurantId) async {
    final response = await ApiClient.post(
      'get_services',
      body: json.encode({'restaurant_id': restaurantId}),
    );
    if (response.statusCode == 200) {
      final List<dynamic> body = json.decode(response.body);
      return body.map((e) => Service.fromJson(e as Map<String, dynamic>)).toList();
    }
    throw Exception('Failed to load services');
  }

  static Future<Service> save(
    int? id,
    int restaurantId,
    int dayOfWeek,
    String startTime,
    String endTime,
  ) async {
    _assertEndAfterStart(startTime, endTime);

    final services = await getByRestaurant(restaurantId);
    _assertNoOverlap(
      services,
      serviceId: id,
      dayOfWeek: dayOfWeek,
      startTime: startTime,
      endTime: endTime,
    );

    if (id != null) {
      await _assertReservationsStillInService(
        serviceId: id,
        restaurantId: restaurantId,
        services: services,
        dayOfWeek: dayOfWeek,
        startTime: startTime,
        endTime: endTime,
      );
    }

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
    throw Exception(_saveErrorMessage(response, dayOfWeek: dayOfWeek));
  }

  static void _assertEndAfterStart(String startTime, String endTime) {
    if (_minutes(endTime) - _minutes(startTime) < 60) {
      throw Exception(_msgEndAfterStart);
    }
  }

  static void _assertNoOverlap(
    List<Service> services, {
    required int? serviceId,
    required int dayOfWeek,
    required String startTime,
    required String endTime,
  }) {
    for (final s in services) {
      if (s.id == serviceId) continue;
      if (s.dayOfWeek != dayOfWeek) continue;
      if (_minutes(startTime) < _minutes(s.endTime) &&
          _minutes(endTime) > _minutes(s.startTime)) {
        throw Exception('$_msgOverlapPrefix${_dayName(dayOfWeek)}.');
      }
    }
  }

  static Future<void> _assertReservationsStillInService({
    required int serviceId,
    required int restaurantId,
    required List<Service> services,
    required int dayOfWeek,
    required String startTime,
    required String endTime,
  }) async {
    final reservations = await Reservation.getAll(restaurantId: restaurantId);

    for (final r in reservations) {
      if (r.status != 'pending' && r.status != 'confirmed') continue;

      final serviceForReservation = _serviceAt(
        services,
        r.datetime.weekday,
        r.datetime.hour,
        r.datetime.minute,
      );
      if (serviceForReservation?.id != serviceId) continue;

      if (r.datetime.weekday != dayOfWeek ||
          !_timeInRange(r.datetime, startTime, endTime)) {
        throw Exception(_msgReservationsOutside);
      }
    }
  }

  static Service? _serviceAt(
    List<Service> services,
    int dayOfWeek,
    int hour,
    int minute,
  ) {
    final minutes = hour * 60 + minute;
    for (final s in services) {
      if (s.dayOfWeek != dayOfWeek) continue;
      if (minutes >= _minutes(s.startTime) && minutes < _minutes(s.endTime)) {
        return s;
      }
    }
    return null;
  }

  static bool _timeInRange(DateTime dt, String startTime, String endTime) {
    final m = dt.hour * 60 + dt.minute;
    return m >= _minutes(startTime) && m < _minutes(endTime);
  }

  static int _minutes(String hhMm) {
    final p = hhMm.split(':');
    return int.parse(p[0]) * 60 + int.parse(p[1]);
  }

  static const _msgReservationsOutside =
      'Modification impossible : des réservations confirmées ou en attente seraient en dehors des horaires du service.';

  static const _msgOverlapPrefix = 'Ce service chevauche avec un service existant le ';

  static const _msgEndAfterStart =
      'L\'heure de fin doit être après l\'heure de début.';

  static String _dayName(int dayOfWeek) {
    switch (dayOfWeek) {
      case 1:
        return 'lundi';
      case 2:
        return 'mardi';
      case 3:
        return 'mercredi';
      case 4:
        return 'jeudi';
      case 5:
        return 'vendredi';
      case 6:
        return 'samedi';
      case 7:
        return 'dimanche';
      default:
        return 'jour $dayOfWeek';
    }
  }

  static String _saveErrorMessage(http.Response response, {required int dayOfWeek}) {
    final raw = ApiClient.errorMessage(response).toLowerCase();

    if (raw.contains('br-7') || raw.contains('chevauche') || raw.contains('overlap')) {
      return '$_msgOverlapPrefix${_dayName(dayOfWeek)}.';
    }
    if (raw.contains('service_min_length') || raw.contains('violates check constraint')) {
      return _msgEndAfterStart;
    }
    if (raw.contains('dehors') ||
        raw.contains('horaires du service') ||
        raw.contains('br-4')) {
      return _msgReservationsOutside;
    }

    return 'Ce service chevauche avec un service existant le ${_dayName(dayOfWeek)}.';
  }

  Future<void> delete() async {
    final response = await ApiClient.post('delete_service', body: json.encode({'service_id': id}));
    if (response.statusCode != 204 && response.statusCode != 200) {
      throw Exception(ApiClient.errorMessage(response));
    }
  }
}
