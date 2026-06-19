import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:prbd_2526_c06/model/restaurant.dart';
import 'package:prbd_2526_c06/providers/security_provider.dart';

import '../model/reservation.dart';

final restaurantSearchFilterProvider = StateProvider<String>((ref) => '');

final restaurantsProvider =
    AsyncNotifierProvider<RestaurantsNotifier, List<Restaurant>>(
  RestaurantsNotifier.new,
);

class RestaurantsNotifier extends AsyncNotifier<List<Restaurant>> {
  @override
  Future<List<Restaurant>> build() async {
    ref.watch(securityProvider);
    final filter = ref.watch(restaurantSearchFilterProvider).trim();
    return Restaurant.getAll(searchFilter: filter.isEmpty ? null : filter);
  }

  Future<void> refresh() async {
    final filter = ref.read(restaurantSearchFilterProvider);
    state = const AsyncLoading();
    state = AsyncData(await Restaurant.getAll(
      searchFilter: filter.isEmpty ? null : filter,
    ));
  }

  void _patch( int restaurantId,{
    required DateTime? lastReservationDate,
    required int pendingRequests,
  }) {
    final list = state.value;
    if (list == null) return;
    state = AsyncData([
      for (final r in list)
        r.id == restaurantId
            ? r.copyWith(
          lastReservationDate: lastReservationDate,
          pendingRequests: pendingRequests,
        )
            : r,
    ]);
  }



  void syncCardAfterReservationSaved({
    required Reservation reservation,
    required bool isCreate,
  }) {
    final card = _cardFor(reservation.restaurantId);
    if (card == null) return;

    final pending = reservation.status == 'pending'
        ? (card.pendingRequests ?? 0) + 1
        : card.pendingRequests ?? 0;
    final lastReservationDate = card.lastReservationDate == null ||
        reservation.datetime.isAfter(card.lastReservationDate!)
        ? reservation.datetime
        : card.lastReservationDate;

    _patch(reservation.restaurantId,
        lastReservationDate: lastReservationDate, pendingRequests: pending);
  }


  void syncCardAfterReservationCancelled({required Reservation before}) {
    final card = _cardFor(before.restaurantId);
    if (card == null) return;

    final pending = before.status == 'pending' && (card.pendingRequests ?? 0) > 0
        ? card.pendingRequests! - 1
        : card.pendingRequests ?? 0;

    _patch(before.restaurantId,
        lastReservationDate: card.lastReservationDate, pendingRequests: pending);
  }

  Restaurant? _cardFor(int restaurantId) {
    final list = state.value;
    if (list == null) return null;
    for (final r in list) {
      if (r.id == restaurantId) return r;
    }
    return null;
  }
}
