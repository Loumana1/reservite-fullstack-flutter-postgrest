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
  void patchRestaurantCard({
    required int restaurantId,
    required DateTime? lastReservationDate,
    required int pendingRequests,
  }) {
    final list = state.value;
    if (list == null) return;
    state = AsyncData([
      for (final r in list)
        if (r.id == restaurantId)
          Restaurant(
            id: r.id,
            name: r.name,
            address: r.address,
            city: r.city,
            phone: r.phone,
            description: r.description,
            rating: r.rating,
            priceRange: r.priceRange,
            slotDuration: r.slotDuration,
            lastReservationDate: lastReservationDate,
            pendingRequests: pendingRequests,
          )
        else
          r,
    ]);
  }

  void syncCardAfterReservationSaved({
    required Reservation reservation,
    required bool isCreate,
  }) {
    final card = _cardFor(reservation.restaurantId);
    if (card == null) return;

    var pending = card.pendingRequests ?? 0;
    if (isCreate && reservation.status == 'pending') {
      pending++;
    } else if (!isCreate && reservation.status == 'pending') {
      pending++;
    }

    final oldLast = card.lastReservationDate;
    final newLast = oldLast == null || reservation.datetime.isAfter(oldLast)
        ? reservation.datetime
        : oldLast;

    patchRestaurantCard(
      restaurantId: reservation.restaurantId,
      lastReservationDate: newLast,
      pendingRequests: pending,
    );
  }


  void syncCardAfterReservationCancelled({required Reservation before}) {
    final card = _cardFor(before.restaurantId);
    if (card == null) return;

    var pending = card.pendingRequests ?? 0;
    if (before.status == 'pending' && pending > 0) {
      pending--;
    }

    patchRestaurantCard(
      restaurantId: before.restaurantId,
      lastReservationDate: card.lastReservationDate,
      pendingRequests: pending,
    );
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
