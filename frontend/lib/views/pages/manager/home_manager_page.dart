import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:prbd_2526_c06/model/reservation.dart';
import 'package:prbd_2526_c06/providers/security_provider.dart';
import 'package:prbd_2526_c06/views/pages/manager/restaurant_dashboard_page.dart';

final managerPendingCountProvider = FutureProvider.family<int, int>((
  ref,
  restaurantId,
) async {
  final list = await Reservation.getAll(
    restaurantId: restaurantId,
    statusFilter: 'pending',
  );
  return list.length;
});

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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes restaurants'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Rafraîchir les données',
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Déconnexion (Benoît P.)',
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
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: const Icon(Icons.restaurant, size: 40),
                title: const Text('Le Gourmet'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        const Text('Bruxelles'),
                        const SizedBox(width: 12),
                        const Icon(Icons.star, size: 14, color: Colors.amber),
                        const SizedBox(width: 2),
                        Text(
                          '4.5',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '€€€',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.access_time, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          'Dernière réservation: mer. 04/12/2024',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    _PendingCountText(restaurantId: 1),
                  ],
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _openDashboard(context, 1, 'Le Gourmet'),
              ),
            ),
            Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: const Icon(Icons.restaurant, size: 40),
                title: const Text('La Trattoria'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        const Text('Bruxelles'),
                        const SizedBox(width: 12),
                        const Icon(Icons.star, size: 14, color: Colors.amber),
                        const SizedBox(width: 2),
                        Text(
                          '4.2',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '€€',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.access_time, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          'Dernière réservation: jeu. 05/12/2024',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    _PendingCountText(restaurantId: 2),
                  ],
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _openDashboard(context, 2, 'La Trattoria'),
              ),
            ),
            Card(
              margin: EdgeInsets.zero,
              child: ListTile(
                leading: const Icon(Icons.restaurant, size: 40),
                title: const Text('Sushi House'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        const Text('Bruxelles'),
                        const SizedBox(width: 12),
                        const Icon(Icons.star, size: 14, color: Colors.amber),
                        const SizedBox(width: 2),
                        Text(
                          '4.7',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '€€€',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ],
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _openDashboard(context, 8, 'Sushi House'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PendingCountText extends ConsumerWidget {
  const _PendingCountText({required this.restaurantId});

  final int restaurantId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final countAsync = ref.watch(managerPendingCountProvider(restaurantId));
    return Row(
      children: [
        const Icon(Icons.pending, size: 14, color: Colors.orange),
        const SizedBox(width: 4),
        Text(
          countAsync.when(
            data: (count) => '$count demande${count > 1 ? 's' : ''} en attente',
            loading: () => '… demandes en attente',
            error: (_, _) => 'Demandes indisponibles',
          ),
          style: const TextStyle(
            fontSize: 12,
            color: Colors.orange,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
