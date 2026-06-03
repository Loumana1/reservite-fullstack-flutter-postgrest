import 'package:prbd_2526_c06/model/service.dart';

const serviceMinuteOptions = [0, 15, 30, 45];

(int hour, int minute) parseServiceTime(String? time, {int defaultHour = 12, int defaultMinute = 0}) {
  if (time == null || time.isEmpty) {
    return (defaultHour, defaultMinute);
  }
  final parts = time.split(':');
  final hour = int.tryParse(parts[0]) ?? defaultHour;
  final minute = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? defaultMinute;
  return (hour, snapServiceMinute(minute));
}

int snapServiceMinute(int minute) {
  var best = serviceMinuteOptions.first;
  var diff = (minute - best).abs();
  for (final m in serviceMinuteOptions) {
    final d = (minute - m).abs();
    if (d < diff) {
      diff = d;
      best = m;
    }
  }
  return best;
}

String formatServiceTime(int hour, int minute) =>
    '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

String formatServiceTimeLabel(String time) {
  final (h, m) = parseServiceTime(time);
  return formatServiceTime(h, m);
}

String serviceDayLabel(int day) {
  switch (day) {
    case 1:
      return 'Lundi';
    case 2:
      return 'Mardi';
    case 3:
      return 'Mercredi';
    case 4:
      return 'Jeudi';
    case 5:
      return 'Vendredi';
    case 6:
      return 'Samedi';
    case 7:
      return 'Dimanche';
    default:
      return 'Jour $day';
  }
}

String servicesDaySummary(List<Service> services) {
  if (services.isEmpty) return 'Aucun service';
  return services
      .map((s) {
        final start = formatServiceTimeLabel(s.startTime);
        final end = formatServiceTimeLabel(s.endTime);
        return '$start - $end';
      })
      .join(', ');
}
