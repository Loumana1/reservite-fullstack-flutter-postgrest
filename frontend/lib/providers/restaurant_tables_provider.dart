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

  Future<Table> togglesponsorTable(Table t) async{
    final update = await  t.updateTableSponsor(!t.is_signature);

    final list = state.value ?? [];
    state = AsyncData([
      for(final table in list )
        table.id == update.id ?
            update : table,


    ]);

    return update;

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