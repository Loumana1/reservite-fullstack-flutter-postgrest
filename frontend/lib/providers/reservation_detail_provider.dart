import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:prbd_2526_c06/model/reservation.dart';
import 'package:prbd_2526_c06/model/restaurant.dart';
import 'package:prbd_2526_c06/providers/client_reservations_provider.dart';
import 'package:prbd_2526_c06/providers/restaurants_provider.dart';

class ReservationDetailState {
  const ReservationDetailState({
    required this.reservation,
    this.restaurant,
  });

  final Reservation reservation;
  final Restaurant? restaurant;
}

final reservationDetailProvider =
AsyncNotifierProvider.family<ReservationDetailNotifier, ReservationDetailState?, int>(
  ReservationDetailNotifier.new,
);

class ReservationDetailNotifier extends AsyncNotifier<ReservationDetailState?> {
  ReservationDetailNotifier(this.reservationId);
  final int reservationId;
  @override
  Future<ReservationDetailState?> build() async {
    final reservation = await Reservation.getById(reservationId);
    final restaurant = await Restaurant.getById(reservation.restaurantId);
    return ReservationDetailState(reservation: reservation, restaurant: restaurant);
  }
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(build);
  }
  void patchDetail(Reservation updated) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(ReservationDetailState(
      reservation: updated,
      restaurant: current.restaurant,
    ));
  }
}


void refreshReservationDetail(WidgetRef ref, int reservationId) {
  ref.read(reservationDetailProvider(reservationId).notifier).refresh();
}


Future<Reservation> cancelReservationDetail(
  WidgetRef ref,
  Reservation reservation,
) async {
  final updated = await reservation.cancel();
  final listNotifier = ref.read(clientReservationsProvider.notifier);
  final filter = listNotifier.statusFilter;
  if (filter != 'all' && updated.status != filter ) {
    listNotifier.removeReservation(reservation.id);
  } else {
    listNotifier.patchReservation(updated);
  }
  ref.read(restaurantsProvider.notifier).syncCardAfterReservationCancelled(
    before: reservation,
  );
  ref.read(reservationDetailProvider(reservation.id).notifier).patchDetail(updated);

  return updated;
}
