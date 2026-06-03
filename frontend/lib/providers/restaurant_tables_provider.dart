import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prbd_2526_c06/model/table.dart';

final restaurantTablesProvider =
    FutureProvider.family<List<Table>, int>((ref, restaurantId) async {
  return Table.getByRestaurant(restaurantId);
});
