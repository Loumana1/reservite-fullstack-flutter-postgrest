import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:prbd_2526_c06/model/restaurant.dart';

final restaurantSearchFilterProvider = StateProvider<String>((ref) => '');

final restaurantsProvider =
    AsyncNotifierProvider<RestaurantsNotifier, List<Restaurant>>(
  RestaurantsNotifier.new,
);

class RestaurantsNotifier extends AsyncNotifier<List<Restaurant>> {
  @override
  Future<List<Restaurant>> build() async {
    final filter = ref.watch(restaurantSearchFilterProvider);
    return Restaurant.getAll(searchFilter: filter.isEmpty ? null : filter);
  }

  Future<void> refresh() async {
    final filter = ref.read(restaurantSearchFilterProvider);
    state = const AsyncLoading();
    state = AsyncData(await Restaurant.getAll(
      searchFilter: filter.isEmpty ? null : filter,
    ));
  }
}
