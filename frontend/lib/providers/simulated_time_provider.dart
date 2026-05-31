import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:prbd_2526_c06/core/services/time_service.dart';

final simulatedTimeProvider =
AsyncNotifierProvider<SimulatedTimeNotifier, DateTime>(
  SimulatedTimeNotifier.new,
);

class SimulatedTimeNotifier extends AsyncNotifier<DateTime> {
  @override
  Future<DateTime> build() => TimeService.getSimulatedTime();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = AsyncData(await build());
  }
}