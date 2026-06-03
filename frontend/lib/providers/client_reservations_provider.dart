import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prbd_2526_c06/model/reservation.dart';

final clientReservationsProvider =
AsyncNotifierProvider<ClientReservationsNotifier, List<Reservation>>(
  ClientReservationsNotifier.new,
);

class ClientReservationsNotifier extends AsyncNotifier<List<Reservation>> {
  String _statusFilter = 'pending';

  String get statusFilter => _statusFilter;

  @override
  Future<List<Reservation>> build() => Reservation.getAll(statusFilter: _statusFilter);

  Future<void> setStatusFilter(String? status) async {
    _statusFilter = status ?? 'all';
    state = const AsyncLoading();
    state = AsyncData(await Reservation.getAll(
      statusFilter: _statusFilter == 'all' ? null : _statusFilter,
    ));
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = AsyncData(await Reservation.getAll(
      statusFilter: _statusFilter == 'all' ? null : _statusFilter,
    ));
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
}
