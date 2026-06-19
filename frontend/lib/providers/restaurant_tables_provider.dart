import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prbd_2526_c06/model/table.dart';
import 'package:prbd_2526_c06/providers/security_provider.dart';

final restaurantTablesProvider =
AsyncNotifierProvider.family<RestaurantTablesNotifier, List<Table>, int>(
    RestaurantTablesNotifier.new,
);
class RestaurantTablesNotifier extends AsyncNotifier<List<Table>> {
  RestaurantTablesNotifier(this.restaurantId);

  final int restaurantId;

  @override
  Future<List<Table>> build() {
    ref.watch(securityProvider);
    return Table.getByRestaurant(restaurantId);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => Table.getByRestaurant(restaurantId));
  }

  void upsertTable(Table saved) {
    final list = [...?state.value];
    final i = list.indexWhere((t) => t.id == saved.id);
    if (i >= 0) {
      list[i] = saved;
    } else {
      list.add(saved);
    }
    state = AsyncData(list);
  }
}