import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:prbd_2526_c06/core/Widgets/reservite_app_bar.dart';
import 'package:prbd_2526_c06/model/restaurant.dart';
import 'package:prbd_2526_c06/providers/security_provider.dart';
import 'package:prbd_2526_c06/providers/simulated_time_provider.dart';
import 'package:prbd_2526_c06/views/pages/manager/restaurant_management_reservations_page.dart';
import 'package:prbd_2526_c06/providers/manager_restaurants_provider.dart';



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
        builder: (_) => RestaurantManagementReservationsPage(
          restaurantId: restaurantId,
          restaurantName: restaurantName,
        ),
      ),
    );
  }

  Future<void> _toggleSponsor(
      BuildContext context,
      WidgetRef ref,
      Restaurant r )
  async {

    try {
      await
      ref.
      read(managerRestaurantsProvider.notifier)
          .toggleSponsor(r);

    } catch (e) {
      if (!context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final restaurantsAsync = ref.watch(managerRestaurantsProvider);

    return Scaffold(
      appBar: ReserviteAppBar(
        title: 'Mes restaurants',
        onRefresh: () async {
          await ref.read(simulatedTimeProvider.notifier).refresh();
          await ref.read(managerRestaurantsProvider.notifier).refresh();
        },
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Déconnexion',
            onPressed: () {
              ref.read(securityProvider.notifier).logOut();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
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
                        if (pending > 0) ...[
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
                        ]
                      ],
                    ),
                    trailing:


                      IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                      icon: r.is_sponsored ?
                      Icon(Icons.diamond, size: 28, color: Colors.amber)
                      :  Icon(Icons.diamond_outlined, size: 28, color: Colors.grey),
                      onPressed: () { _toggleSponsor(context, ref,r);},
                    ),
                   //     const Icon(Icons.chevron_right),





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

