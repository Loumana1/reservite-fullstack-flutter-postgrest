import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:prbd_2526_c06/core/Widgets/confirm_dialog.dart';
import 'package:prbd_2526_c06/core/tools/date_formatters.dart';
import 'package:prbd_2526_c06/core/tools/service_time_picker.dart';
import 'package:prbd_2526_c06/core/Widgets/reservite_app_bar.dart';
import 'package:prbd_2526_c06/core/widgets/status_badge.dart';
import 'package:prbd_2526_c06/model/service.dart';
import 'package:prbd_2526_c06/model/table.dart' as model;
import 'package:prbd_2526_c06/providers/manager_reservations_provider.dart';
import 'package:prbd_2526_c06/providers/restaurant_services_provider.dart';
import 'package:prbd_2526_c06/providers/restaurant_tables_provider.dart';
import 'package:prbd_2526_c06/views/pages/manager/manager_reservation_details_page.dart';
import 'package:prbd_2526_c06/views/pages/manager/edit_service_page.dart';
import 'package:prbd_2526_c06/views/pages/manager/edit_table_page.dart';

class RestaurantManagementReservationsPage extends ConsumerStatefulWidget {
  const RestaurantManagementReservationsPage({
    super.key,
    required this.restaurantId,
    required this.restaurantName,
  });

  final int restaurantId;
  final String restaurantName;

  @override
  ConsumerState<RestaurantManagementReservationsPage> createState() =>
      _RestaurantManagementReservationsMockupScreenState();
}

class _RestaurantManagementReservationsMockupScreenState
    extends ConsumerState<RestaurantManagementReservationsPage> {
  int _currentIndex = 0;

  void _openDetails(BuildContext context, int reservationId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ManagerReservationDetailsPage(
          reservationId: reservationId,
          restaurantId: widget.restaurantId,
          returnTab: _currentIndex,
        ),
      ),
    ).then((_) => refreshManagerReservations(ref, widget.restaurantId));
  }

  void _openEditService(
    BuildContext context,
    Service? service, {
    int? initialDayOfWeek,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditServicePage(
          restaurantId: widget.restaurantId,
          service: service,
          initialDayOfWeek: initialDayOfWeek,
        ),
      ),
    ).then((_) {
      ref.invalidate(restaurantServicesProvider(widget.restaurantId));
    });
  }

  Future<void> _deleteService(BuildContext context, Service service) async {
    final ok = await showConfirmDialog(
      context,
      title: 'Supprimer le service',
      message:
          'Supprimer le service ${formatServiceTimeLabel(service.startTime)} - '
          '${formatServiceTimeLabel(service.endTime)} ?',
      isDestructive: true,
    );
    if (!ok || !context.mounted) return;

    try {
      await service.delete();
      ref.invalidate(restaurantServicesProvider(widget.restaurantId));
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Service supprimé')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    }
  }

  void _openEditTable(BuildContext context, model.Table? table) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditTablePage(
          restaurantId: widget.restaurantId,
          table: table,
        ),
      ),
    );
  }

  void _onRefresh() {
    switch (_currentIndex) {
      case 0:
        refreshManagerReservations(ref, widget.restaurantId);
      case 1:
        ref.invalidate(restaurantServicesProvider(widget.restaurantId));
      case 2:
        ref.invalidate(restaurantTablesProvider(widget.restaurantId));
    }
  }

  Widget _buildReservationsTab() {
    final reservations =
        ref.watch(managerReservationsProvider(widget.restaurantId));
    final statusFilter = ref
        .read(managerReservationsProvider(widget.restaurantId).notifier)
        .statusFilter;

    return SafeArea(
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
                    .read(managerReservationsProvider(widget.restaurantId).notifier)
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
                                        const Icon(Icons.restaurant, size: 16),
                                        const SizedBox(width: 4),
                                        Text(
                                          widget.restaurantName,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
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
    );
  }

  Widget _buildServicesTab() {
    final services = ref.watch(restaurantServicesProvider(widget.restaurantId));

    return SafeArea(
      child: services.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur : $e')),
        data: (list) {
          final byDay = <int, List<Service>>{};
          for (final s in list) {
            byDay.putIfAbsent(s.dayOfWeek, () => []).add(s);
          }
          for (final dayServices in byDay.values) {
            dayServices.sort((a, b) => a.startTime.compareTo(b.startTime));
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
            children: [
              for (int day = 1; day <= 7; day++)
                _ServiceDayCard(
                  dayOfWeek: day,
                  services: byDay[day] ?? const [],
                  onEdit: (s) => _openEditService(context, s),
                  onDelete: (s) => _deleteService(context, s),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTablesTab() {
    final tables = ref.watch(restaurantTablesProvider(widget.restaurantId));

    return SafeArea(
      child: tables.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur : $e')),
        data: (list) {
          if (list.isEmpty) {
            return const Center(child: Text('Aucune table pour ce restaurant'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: list.length,
            itemBuilder: (context, i) {
              final t = list[i];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  title: Text('Table ${t.tableNumble}'),
                  subtitle: Text('${t.capacity} places'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _openEditTable(context, t),
                ),
              );
            },
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ReserviteAppBar(
        title: widget.restaurantName,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        onRefresh: _onRefresh,
      ),
      body: switch (_currentIndex) {
        0 => _buildReservationsTab(),
        1 => _buildServicesTab(),
        _ => _buildTablesTab(),
      },
      floatingActionButton: _currentIndex == 0
          ? null
          : FloatingActionButton(
              onPressed: () {
                if (_currentIndex == 1) {
                  _openEditService(context, null);
                } else {
                  _openEditTable(context, null);
                }
              },
              child: const Icon(Icons.add),
            ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.book),
            label: 'Réservations',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.schedule),
            label: 'Services',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.table_restaurant),
            label: 'Tables',
          ),
        ],
      ),
    );
  }
}

class _ServiceDayCard extends StatelessWidget {
  const _ServiceDayCard({
    required this.dayOfWeek,
    required this.services,
    required this.onEdit,
    required this.onDelete,
  });

  final int dayOfWeek;
  final List<Service> services;
  final void Function(Service service) onEdit;
  final void Function(Service service) onDelete;

  @override
  Widget build(BuildContext context) {
    final dayLabel = serviceDayLabel(dayOfWeek);

    if (services.isEmpty) {
      return Card(
        margin: const EdgeInsets.only(bottom: 16),
        color: Colors.grey[100],
        child: ListTile(
          leading: Icon(Icons.schedule, color: Colors.grey[600]),
          title: Text(
            dayLabel,
            style: TextStyle(color: Colors.grey[600]),
          ),
          subtitle: const Text(
            'Aucun service',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        leading: const Icon(Icons.schedule),
        title: Text(dayLabel),
        subtitle: Text(servicesDaySummary(services)),
        children: [
          for (final s in services)
            ListTile(
              title: Text(
                '${formatServiceTimeLabel(s.startTime)} - '
                '${formatServiceTimeLabel(s.endTime)}',
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    tooltip: 'Modifier',
                    onPressed: () => onEdit(s),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    tooltip: 'Supprimer le service',
                    onPressed: () => onDelete(s),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
