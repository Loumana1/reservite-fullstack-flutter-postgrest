import 'package:prbd_2526_c06/model/reservation.dart';
import 'package:prbd_2526_c06/model/service.dart';

Service? serviceForReservation(Reservation reservation, List<Service> services) {
  final dow = reservation.datetime.weekday;
  final time = reservation.datetime;
  final minutes = time.hour * 60 + time.minute;

  for (final s in services) {
    if (s.dayOfWeek != dow) continue;
    final start = _minutesFromHhMm(s.startTime);
    final end = _minutesFromHhMm(s.endTime);
    if (minutes >= start && minutes < end) return s;
  }
  return null;
}

bool canMarkReservationCompleted({
  required Reservation reservation,
  required List<Service> services,
  required DateTime simulatedTime,
}) {
  if (reservation.status != 'confirmed') return false;

  final resDay = DateTime(
    reservation.datetime.year,
    reservation.datetime.month,
    reservation.datetime.day,
  );
  final simDay = DateTime(
    simulatedTime.year,
    simulatedTime.month,
    simulatedTime.day,
  );
  if (simDay.isBefore(resDay)) return false;
  if (simDay.isAfter(resDay)) return true;

  final svc = serviceForReservation(reservation, services);
  if (svc == null) return false;
  final serviceStart = _dateTimeOnDay(resDay, svc.startTime);
  return !simulatedTime.isBefore(serviceStart);
}

int _minutesFromHhMm(String hhMm) {
  final parts = hhMm.split(':');
  return int.parse(parts[0]) * 60 + int.parse(parts[1]);
}

DateTime _dateTimeOnDay(DateTime day, String hhMm) {
  final parts = hhMm.split(':');
  return DateTime(
    day.year,
    day.month,
    day.day,
    int.parse(parts[0]),
    int.parse(parts[1]),
  );
}

(String firstName, String lastName) splitClientFullName(String? fullName) {
  if (fullName == null || fullName.trim().isEmpty) {
    return ('—', '—');
  }
  final parts = fullName.trim().split(RegExp(r'\s+'));
  if (parts.length == 1) return (parts.first, '—');
  return (parts.first, parts.sublist(1).join(' '));
}
