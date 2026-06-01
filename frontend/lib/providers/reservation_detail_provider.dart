import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:prbd_2526_c06/core/services/reservation_service.dart';
import 'package:prbd_2526_c06/model/reservation.dart';
import 'package:prbd_2526_c06/model/restaurant.dart';
import 'package:prbd_2526_c06/providers/client_reservations_provider.dart';

class ReservationDetailState {
  const ReservationDetailState({
    required this.reservation,
    this.restaurant,
  });

  final Reservation reservation;
  final Restaurant? restaurant;
}

final reservationDetailProvider =
    FutureProvider.family<ReservationDetailState?, int>(
  (ref, reservationId) async {
    final reservation = await ReservationService.getById(reservationId);
    if (reservation == null) return null;

    return ReservationDetailState(
      reservation: reservation,
      restaurant: null,
    );
  },
);

void refreshReservationDetail(WidgetRef ref, int reservationId) {
  ref.invalidate(reservationDetailProvider(reservationId));
}


Future<Reservation> cancelReservationDetail(
  WidgetRef ref,
  int reservationId,
) async {
  final updated = await ReservationService.cancel(reservationId);
  final listNotifier = ref.read(clientReservationsProvider.notifier);
  if (listNotifier.statusFilter == 'pending' && updated.status == 'cancelled') {
    listNotifier.removeReservation(reservationId);
  } else {
    listNotifier.patchReservation(updated);
  }
  ref.invalidate(reservationDetailProvider(reservationId));
  return updated;
}
