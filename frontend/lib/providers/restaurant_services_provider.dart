import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prbd_2526_c06/model/service.dart';

/// Renvoie la liste des services d'un restaurant donné.
/// Usage : ref.watch(restaurantServicesProvider(restaurantId));
final restaurantServicesProvider =
    FutureProvider.family<List<Service>, int>((ref, restaurantId) async {
  return Service.getByRestaurant(restaurantId);
});
