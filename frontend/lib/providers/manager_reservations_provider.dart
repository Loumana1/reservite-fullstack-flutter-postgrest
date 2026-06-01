import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prbd_2526_c06/model/reservation.dart';


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
  Future<List<Reservation>> build() => _load();

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


  Future<void> cancel(Reservation r) async {
    try {
      patchReservation(await r.cancel());
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> complete(Reservation r) async {
    try {
      patchReservation(await r.complete());
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> confirm(Reservation r, List<int> tableIds) async {
    try {
      patchReservation(await r.confirm(tableIds));
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}

void refreshManagerReservations(WidgetRef ref, int restaurantId) {
  ref.read(managerReservationsProvider(restaurantId).notifier).refresh();
}