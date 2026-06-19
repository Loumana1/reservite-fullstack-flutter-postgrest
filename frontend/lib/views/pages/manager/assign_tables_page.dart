import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:prbd_2526_c06/core/Widgets/reservite_app_bar.dart';
import 'package:prbd_2526_c06/core/tools/date_formatters.dart';
import 'package:prbd_2526_c06/model/reservation.dart';
import 'package:prbd_2526_c06/providers/manager_reservation_detail_provider.dart';
import 'package:prbd_2526_c06/providers/manager_reservations_provider.dart';
import 'package:prbd_2526_c06/providers/restaurant_tables_provider.dart';

class AssignTablesPage extends ConsumerStatefulWidget {
  const AssignTablesPage({
    super.key,
    required this.reservationId,
    required this.restaurantId,
    this.returnTab = 0,
  });

  final int reservationId;
  final int restaurantId;
  final int returnTab;

  @override
  ConsumerState<AssignTablesPage> createState() => _AssignTablesPageState();
}

class _AssignTablesPageState extends ConsumerState<AssignTablesPage> {
  final Set<int> _selected = {};
  bool _submitting = false;

  @override
  Widget build(BuildContext context) {
    final tablesAsync =
        ref.watch(restaurantTablesProvider(widget.restaurantId));
    final detailAsync =
    ref.watch(managerReservationDetailProvider(
      ManagerReservationDetailParams(
        reservationId: widget.reservationId,
        restaurantId: widget.restaurantId,
      ),
    ));
    final reservation = detailAsync.value?.reservation;
    return Scaffold(
      appBar: ReserviteAppBar(
        title: 'Attribuer des tables',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        onRefresh: () {
          ref.invalidate(restaurantTablesProvider(widget.restaurantId));
          ref.invalidate(managerReservationDetailProvider(
            ManagerReservationDetailParams(
              reservationId: widget.reservationId,
              restaurantId: widget.restaurantId,
            ),
          ));
        },
      ),
      body: tablesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur : $e')),
        data: (tables) {
          if (tables.isEmpty) {
            return const Center(
              child: Text('Aucune table configurée pour ce restaurant'),
            );
          }
          final sorted = [...tables]
            ..sort((a, b) {
              final c = a.capacity.compareTo(b.capacity);
              return c != 0 ? c : a.tableNumble.compareTo(b.tableNumble);
            });

          final int totalCapacity = tables
              .where((t) => _selected.contains(t.id))
              .fold(0, (sum, t) => sum + t.capacity);
              
          final int guests = reservation?.numberOfGuests ?? 0;
          final bool isSufficient = totalCapacity >= guests;

          return ListView(
            padding: const EdgeInsets.only(bottom: 88),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Réservation',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('${reservation?.numberOfGuests} convives'),
                      Text(formatReservationDateLabel(reservation!.datetime)),
                      Text(formatReservationTimeLabel(reservation!.datetime))
                    ],
                  ),
                ),
              ),
              if (_selected.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
                  child: Card(
                    color: isSufficient ? Colors.green.shade50 : Colors.orange.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Icon(
                            isSufficient ? Icons.check_circle : Icons.warning,
                            color: isSufficient ? Colors.green[700] : Colors.orange[700],
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Capacité totale: $totalCapacity places',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  isSufficient 
                                      ? '✓ Capacité suffisante pour $guests convives'
                                      : '⚠️ Il manque ${guests - totalCapacity} place(s)',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isSufficient ? Colors.green.shade700 : Colors.orange.shade800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              for (final t in sorted)
                CheckboxListTile(
                  title: Text('Table ${t.tableNumble}'),
                  subtitle: Text('Capacité ${t.capacity}'),
                  value: _selected.contains(t.id),
                  onChanged: _submitting
                      ? null
                      : (v) {
                          setState(() {
                            if (v == true) {
                              _selected.add(t.id);
                            } else {
                              _selected.remove(t.id);
                            }
                          });
                        },
                ),
            ],
          );
        },
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: FilledButton(
          onPressed: _selected.isEmpty || _submitting ? null : () => _confirm(),
          child: _submitting
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Confirmer la réservation'),
        ),
      ),
    );
  }

  Future<void> _confirm() async {
    setState(() => _submitting = true);
    try {
      final reservation =
          await Reservation.getById(widget.reservationId);
      await ref
          .read(managerReservationsProvider(widget.restaurantId).notifier)
          .confirm(reservation, _selected.toList());
      refreshManagerReservations(ref, widget.restaurantId);
      ref.invalidate(managerReservationDetailProvider(
        ManagerReservationDetailParams(
          reservationId: widget.reservationId,
          restaurantId: widget.restaurantId,
        ),
      ));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Réservation confirmée')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}
