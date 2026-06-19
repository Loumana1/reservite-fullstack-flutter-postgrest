import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prbd_2526_c06/model/service.dart';
import 'package:prbd_2526_c06/providers/security_provider.dart';


final restaurantServicesProvider =
AsyncNotifierProvider.family<RestaurantServicesNotifier, List<Service>, int>(
    RestaurantServicesNotifier.new,
);

class RestaurantServicesNotifier extends AsyncNotifier<List<Service>> {
RestaurantServicesNotifier(this.restaurantId);

final int restaurantId;

@override
Future<List<Service>> build() {
  ref.watch(securityProvider);
  return Service.getByRestaurant(restaurantId);
}

Future<void> refresh() async {
  state = const AsyncLoading();
  state = await AsyncValue.guard(() => Service.getByRestaurant(restaurantId));
}

void upsertService(Service saved) {
  final list = [...?state.value];
  final i = list.indexWhere((s) => s.id == saved.id);
  if (i >= 0) {
    list[i] = saved;
  } else {
    list.add(saved);
  }
  state = AsyncData(list);
}

void removeService(int id) {
  state = AsyncData(state.value?.where((s) => s.id != id).toList() ?? []);
}
}