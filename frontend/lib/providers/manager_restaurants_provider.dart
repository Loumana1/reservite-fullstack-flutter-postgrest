import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prbd_2526_c06/model/reservation.dart';
import 'package:prbd_2526_c06/model/restaurant.dart';
import 'package:prbd_2526_c06/providers/security_provider.dart';

final managerRestaurantsProvider =
AsyncNotifierProvider<ManagerRestaurantsNotifier, List<Restaurant>>(
  ManagerRestaurantsNotifier.new,
);

class ManagerRestaurantsNotifier extends AsyncNotifier<List<Restaurant>> {
  static const _loadTimeout = Duration(seconds: 12);

  @override
  Future<List<Restaurant>> build() {
    ref.watch(securityProvider);
    return _fetch();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  Future<List<Restaurant>> _fetch() {
    return Restaurant.getAll().timeout(_loadTimeout);
  }


  void syncAfterReservationChange({
    required int restaurantId,
    required Reservation updated,
    Reservation? before,
  }) {
    final card = _cardFor(restaurantId);
    if (card == null) return;

    final pending = _nextPendingCount(
      current: card.pendingRequests ?? 0,
      previousStatus: before?.status,
      newStatus: updated.status,
    );
    final lastReservationDate = card.lastReservationDate == null ||
        updated.datetime.isAfter(card.lastReservationDate!)
        ? updated.datetime
        : card.lastReservationDate;

    _patch(restaurantId,
        lastReservationDate: lastReservationDate, pendingRequests: pending);
  }

  int _nextPendingCount({
    required int current,
    required String? previousStatus,
    required String newStatus,
  }) {
    if (previousStatus == 'pending' && newStatus != 'pending') {
      return current > 0 ? current - 1 : 0;
    }
    if (previousStatus != 'pending' && newStatus == 'pending') {
      return current + 1;
    }
    return current;
  }

  void _patch(
      int restaurantId, {
        required DateTime? lastReservationDate,
        required int pendingRequests,
      }) {
    final list = state.value;
    if (list == null) return;
    final patched = [
      for (final r in list)
        r.id == restaurantId
            ? r.copyWith(
          lastReservationDate: lastReservationDate,
          pendingRequests: pendingRequests,
        )
            : r,
    ]..sort(_byLastReservationDesc);
    state = AsyncData(patched);
  }

  Restaurant? _cardFor(int restaurantId) {
    final list = state.value;
    if (list == null) return null;

    for (final r in list) {
      if (r.id == restaurantId) return r;
    }

    return null;
  }

  Future<Restaurant> toggleSponsor(Restaurant r) async {

    final updated = await r.updateSponsor(!r.is_sponsored);

    final list = state.value ?? [];

    state = AsyncData([
      for (final item in list) item.id == updated.id ? updated : item,
    ]);



    return updated;

  }


  static int _byLastReservationDesc(Restaurant r, Restaurant r2) {
    final a = r.lastReservationDate;
    final b = r2.lastReservationDate;

    if (a == null && b == null)
      return r.name.compareTo(r2.name);

    if (a == null)
      return 1;

    if (b == null) return -1;

    final compare = b.compareTo(a);
    return compare != 0 ? compare : r.name.compareTo(r2.name);
  }
}
