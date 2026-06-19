import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prbd_2526_c06/model/reservation.dart';
import 'package:prbd_2526_c06/providers/security_provider.dart';
import 'package:prbd_2526_c06/providers/manager_restaurants_provider.dart';



final managerReservationsProvider =
AsyncNotifierProvider.family<ManagerReservationsNotifier, List<Reservation>, int>(
  ManagerReservationsNotifier.new,
);

class ManagerReservationsNotifier extends AsyncNotifier<List<Reservation>> {
  ManagerReservationsNotifier(this.restaurantId);

  final int restaurantId;

  String _statusFilter = 'pending';

  String get statusFilter => _statusFilter;

  @override
  Future<List<Reservation>> build() {
    ref.watch(securityProvider);
    return _load();
  }

  Future<List<Reservation>> _load() {
    return Reservation.getAll(
      restaurantId: restaurantId,
      statusFilter: _statusFilter == 'all' ? null : _statusFilter,
    );
  }

  Future<void> setStatusFilter(String? status) async {
    _statusFilter = status ?? 'all';
    state = const AsyncLoading();
    state = AsyncData(await _load());
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = AsyncData(await _load());
  }

  void patchReservation(Reservation updated) {
    final list = [...?state.value];
    final i = list.indexWhere((r) => r.id == updated.id);
    if (i >= 0) {
      list[i] = updated;
    } else {
      list.insert(0, updated);
    }
    state = AsyncData(list);
  }

  void removeReservation(int id) {
    state = AsyncData(state.value?.where((r) => r.id != id).toList() ?? []);
  }


  Future<Reservation> cancel(Reservation r) => _mutate(r.cancel());


  Future<Reservation> complete(Reservation r)  => _mutate(r.complete());


  Future<Reservation> confirm(Reservation r, List<int> tableIds)=>
      _mutate(r.confirm(tableIds));

  Future<Reservation> _mutate(Future<Reservation> action) async {
    try {
      final updated = await action;
      patchReservation(updated);
      return updated;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}



void syncAfterManagerReservationChange(
    WidgetRef ref,
    int restaurantId,
    Reservation updated, {
      Reservation? before,
    }) {
  final listNotifier = ref.read(managerReservationsProvider(restaurantId).notifier);
  if (listNotifier.statusFilter != 'all' &&
      updated.status != listNotifier.statusFilter) {
    listNotifier.removeReservation(updated.id);
  }

  ref.read(managerRestaurantsProvider.notifier).syncAfterReservationChange(
    restaurantId: restaurantId,
    updated: updated,
    before: before,
  );
}


void refreshManagerReservationsFromServer(WidgetRef ref, int restaurantId) {
  ref.read(managerReservationsProvider(restaurantId).notifier).refresh();
  ref.read(managerRestaurantsProvider.notifier).refresh();
}