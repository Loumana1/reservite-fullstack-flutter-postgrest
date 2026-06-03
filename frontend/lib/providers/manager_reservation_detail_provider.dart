import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:prbd_2526_c06/model/reservation.dart';
import 'package:prbd_2526_c06/model/service.dart';
import 'package:prbd_2526_c06/providers/simulated_time_provider.dart';

class ManagerReservationDetailParams {
  const ManagerReservationDetailParams({
    required this.reservationId,
    required this.restaurantId,
  });

  final int reservationId;
  final int restaurantId;

  @override
  bool operator ==(Object other) =>
      other is ManagerReservationDetailParams &&
      other.reservationId == reservationId &&
      other.restaurantId == restaurantId;

  @override
  int get hashCode => Object.hash(reservationId, restaurantId);
}

class ManagerReservationDetail {
  const ManagerReservationDetail({
    required this.reservation,
    required this.services,
    required this.simulatedTime,
  });

  final Reservation reservation;
  final List<Service> services;
  final DateTime simulatedTime;
}

final managerReservationDetailProvider = FutureProvider.family<
    ManagerReservationDetail?, ManagerReservationDetailParams>(
  (ref, params) async {
    final reservation = await Reservation.getById(params.reservationId);
    final services = await Service.getByRestaurant(params.restaurantId);
    final simulatedTime =
        await ref.watch(simulatedTimeProvider.future);
    return ManagerReservationDetail(
      reservation: reservation,
      services: services,
      simulatedTime: simulatedTime,
    );
  },
);

void refreshManagerReservationDetail(
  WidgetRef ref,
  ManagerReservationDetailParams params,
) {
  ref.invalidate(managerReservationDetailProvider(params));
}
