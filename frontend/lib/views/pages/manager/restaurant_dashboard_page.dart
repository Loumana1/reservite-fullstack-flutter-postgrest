import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:prbd_2526_c06/core/tools/date_formatters.dart';
import 'package:prbd_2526_c06/core/Widgets/reservite_app_bar.dart';
import 'package:prbd_2526_c06/core/Widgets/status_badge.dart';
import 'package:prbd_2526_c06/providers/manager_reservations_provider.dart';
import 'package:prbd_2526_c06/providers/simulated_time_provider.dart';
import 'package:prbd_2526_c06/views/pages/manager/manager_reservation_details_page.dart';

class RestaurantDashboardPage extends ConsumerWidget {
  const RestaurantDashboardPage(this.restaurantId, this.restaurantName, {super.key});

  final int restaurantId;
  final String restaurantName;

  void _openDetails(BuildContext context, int reservationId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ManagerReservationDetailsPage(
          reservationId: reservationId,
          restaurantId: restaurantId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reservations = ref.watch(managerReservationsProvider(restaurantId));
    final statusFilter =
        ref.read(managerReservationsProvider(restaurantId).notifier).statusFilter;

    return Scaffold(
      appBar: ReserviteAppBar(
        title: restaurantName,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        onRefresh: () async {
          await ref.read(simulatedTimeProvider.notifier).refresh();
          refreshManagerReservations(ref, restaurantId);
        },
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0),
              child: SegmentedButton<String>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(
                    value: 'all',
                    icon: Icon(Icons.list, size: 24),
                    tooltip: 'Toutes',
                  ),
                  ButtonSegment(
                    value: 'pending',
                    icon: Icon(Icons.pending, size: 24, color: Colors.orange),
                    tooltip: 'En attente',
                  ),
                  ButtonSegment(
                    value: 'confirmed',
                    icon: Icon(Icons.check_circle, size: 24, color: Colors.green),
                    tooltip: 'Confirmées',
                  ),
                  ButtonSegment(
                    value: 'completed',
                    icon: Icon(Icons.event_available, size: 24, color: Colors.blue),
                    tooltip: 'Terminées',
                  ),
                  ButtonSegment(
                    value: 'cancelled',
                    icon: Icon(Icons.cancel, size: 24, color: Colors.red),
                    tooltip: 'Annulées',
                  ),
                ],
                selected: {statusFilter},
                onSelectionChanged: (selected) {
                  ref
                      .read(managerReservationsProvider(restaurantId).notifier)
                      .setStatusFilter(selected.first);
                },
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: reservations.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Erreur : $e')),
                data: (list) {
                  if (list.isEmpty) {
                    return const Center(
                      child: Text('Aucune réservation pour ce filtre'),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: list.length,
                    itemBuilder: (context, i) {
                      final r = list[i];
                      final clientName =
                          r.clientFullName ?? 'Client #${r.clientId}';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: InkWell(
                          onTap: () => _openDetails(context, r.id),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                Tooltip(
                                  message: statusLabel(r.status),
                                  child: statusIcon(r.status),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        clientName,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(Icons.access_time, size: 16),
                                          const SizedBox(width: 4),
                                          Flexible(
                                            child: Text(
                                              '${formatReservationDateLabel(r.datetime)} '
                                              '${formatReservationTimeLabel(r.datetime)}',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          const Icon(Icons.people, size: 16),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${r.numberOfGuests} convives',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
