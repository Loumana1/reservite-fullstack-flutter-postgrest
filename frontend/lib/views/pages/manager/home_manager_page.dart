import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:prbd_2526_c06/model/restaurant.dart';
import 'package:prbd_2526_c06/providers/security_provider.dart';
import 'package:prbd_2526_c06/views/pages/manager/restaurant_dashboard_page.dart';

final managerRestaurantsProvider =
    AsyncNotifierProvider<ManagerRestaurantsNotifier, List<Restaurant>>(
  ManagerRestaurantsNotifier.new,
);

class ManagerRestaurantsNotifier extends AsyncNotifier<List<Restaurant>> {
  static const _loadTimeout = Duration(seconds: 12);

  @override
  Future<List<Restaurant>> build() {
    return _fetch();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  Future<List<Restaurant>> _fetch() {
    return Restaurant.getAll().timeout(_loadTimeout);
  }
}

class HomeManagerPage extends ConsumerWidget {
  const HomeManagerPage({super.key});

  void _openDashboard(
    BuildContext context,
    int restaurantId,
    String restaurantName,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RestaurantDashboardPage(restaurantId, restaurantName),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final simulatedTime = DateTime(2024, 12, 4, 16, 0);
    final restaurantsAsync = ref.watch(managerRestaurantsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes restaurants'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Rafraîchir les données',
            onPressed: () =>
                ref.read(managerRestaurantsProvider.notifier).refresh(),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Déconnexion',
            onPressed: () {
              ref.read(securityProvider.notifier).logOut();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
        elevation: 2,
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        surfaceTintColor: Colors.transparent,
        flexibleSpace: Align(
          alignment: Alignment.topCenter,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(top: 2.0),
              child: Tooltip(
                message:
                    'Date/heure simulée utilisée pour les tests.\nCliquez pour modifier.',
                child: Text(
                  DateFormat('EEEE dd/MM/yyyy HH:mm', 'fr_FR')
                      .format(simulatedTime),
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[400],
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: restaurantsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'Erreur de chargement : $e',
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () =>
                      ref.read(managerRestaurantsProvider.notifier).refresh(),
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          ),
          data: (restaurants) {
            if (restaurants.isEmpty) {
              return const Center(child: Text('Aucun restaurant géré'));
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: restaurants.length,
              itemBuilder: (context, i) {
                final r = restaurants[i];
                final pending = r.pendingRequests ?? 0;
                final lastDate = r.lastReservationDate != null
                    ? DateFormat('EEE dd/MM/yyyy', 'fr_FR')
                        .format(r.lastReservationDate!)
                    : null;

                return Card(
                  margin: EdgeInsets.only(
                    bottom: i == restaurants.length - 1 ? 0 : 8,
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.restaurant, size: 40),
                    title: Text(r.name),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on,
                              size: 14,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Text(r.city),
                            if (r.rating != null) ...[
                              const SizedBox(width: 12),
                              const Icon(
                                Icons.star,
                                size: 14,
                                color: Colors.amber,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                r.rating!.toStringAsFixed(1),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                            if (r.priceRange != null) ...[
                              const SizedBox(width: 12),
                              Text(
                                '€' * r.priceRange!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (lastDate != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.access_time,
                                size: 14,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Dernière réservation: $lastDate',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.pending,
                              size: 14,
                              color: Colors.orange,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$pending demande${pending > 1 ? 's' : ''} en attente',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.orange,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _openDashboard(context, r.id, r.name),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
