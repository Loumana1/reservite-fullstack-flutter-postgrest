import 'package:intl/intl.dart';

String formatSimulatedTime(DateTime dt) {
  return DateFormat('EEEE dd/MM/yyyy HH:mm', 'fr_FR').format(dt);
}

String formatReservationDateLabel(DateTime dt) {
  return 'Date: ${DateFormat('EEE dd/MM/yyyy', 'fr_FR').format(dt)}';
}

String formatReservationTimeLabel(DateTime dt) {
  return 'Heure: ${DateFormat('HH:mm').format(dt)}';
}

String statusLabel(String status) {
  switch (status) {
    case 'pending':
      return 'En attente';
    case 'confirmed':
      return 'Confirmée';
    case 'completed':
      return 'Terminée';
    case 'cancelled':
      return 'Annulée';
    default:
      return status;
  }
}

String formatSlotTime(DateTime dt) {
  return DateFormat('HH:mm').format(dt);
}

String formatDateLong(DateTime dt) {
  return DateFormat('EEEE dd/MM/yyyy', 'fr_FR').format(dt);
}