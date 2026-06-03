import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:prbd_2526_c06/core/Widgets/confirm_dialog.dart';
import 'package:prbd_2526_c06/core/Widgets/reservite_app_bar.dart';
import 'package:prbd_2526_c06/core/tools/date_formatters.dart';
import 'package:prbd_2526_c06/core/tools/reservation_completion.dart';
import 'package:prbd_2526_c06/model/reservation.dart';
import 'package:prbd_2526_c06/model/table.dart' as model;
import 'package:prbd_2526_c06/providers/manager_reservation_detail_provider.dart';
import 'package:prbd_2526_c06/providers/manager_reservations_provider.dart';
import 'package:prbd_2526_c06/views/pages/manager/assign_tables_page.dart';

class ManagerReservationDetailsPage extends ConsumerWidget {
  const ManagerReservationDetailsPage({
    super.key,
    required this.reservationId,
    required this.restaurantId,
    this.returnTab = 0,
  });

  final int reservationId;
  final int restaurantId;
  final int returnTab;

  ManagerReservationDetailParams get _params => ManagerReservationDetailParams(
        reservationId: reservationId,
        restaurantId: restaurantId,
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(managerReservationDetailProvider(_params));

    return Scaffold(
      appBar: ReserviteAppBar(
        title: 'Détails de la réservation',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        onRefresh: () => refreshManagerReservationDetail(ref, _params),
      ),
      body: detailAsync.when(
        loading: () => const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Chargement de la réservation…'),
            ],
          ),
        ),
        error: (e, _) => Center(child: Text('Erreur : $e')),
        data: (detail) {
          if (detail == null) {
            return const Center(child: Text('Réservation introuvable'));
          }
          return _ManagerReservationBody(
            detail: detail,
            returnTab: returnTab,
            onChanged: () {
              refreshManagerReservationDetail(ref, _params);
              refreshManagerReservations(ref, restaurantId);
            },
          );
        },
      ),
    );
  }
}

class _ManagerReservationBody extends ConsumerWidget {
  const _ManagerReservationBody({
    required this.detail,
    required this.returnTab,
    required this.onChanged,
  });

  final ManagerReservationDetail detail;
  final int returnTab;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = detail.reservation;
    final canComplete = canMarkReservationCompleted(
      reservation: r,
      services: detail.services,
      simulatedTime: detail.simulatedTime,
    );
    final (firstName, _) = splitClientFullName(r.clientFullName);
    final special = r.specialRequests?.trim();

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SectionCard(
              title: 'Informations client',
              children: [
                _InfoRow(Icons.person, 'Nom: $firstName'),
                const SizedBox(height: 8),

                _InfoRow(
                  Icons.email,
                  'Email: ${r.clientEmail ?? 'Non renseigné'}',
                ),
              ],
            ),
            const SizedBox(height: 16),
            _SectionCard(
              title: 'Détails de la réservation',
              children: [
                _InfoRow(
                  Icons.restaurant,
                  r.restaurantName ?? 'Restaurant',
                  bold: true,
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                _InfoRow(
                  Icons.calendar_today,
                  formatReservationDateLabel(r.datetime),
                ),
                const SizedBox(height: 8),
                _InfoRow(
                  Icons.access_time,
                  formatReservationTimeLabel(r.datetime),
                ),
                const SizedBox(height: 8),
                _InfoRow(
                  Icons.people,
                  'Nombre de convives: ${r.numberOfGuests}',
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.info, size: 20),
                    const SizedBox(width: 8),
                    const Text('Statut: '),
                    Chip(
                      label: Text(
                        statusLabel(r.status),
                        style: const TextStyle(fontSize: 12, color: Colors.white),
                      ),
                      backgroundColor: _statusColor(r.status),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
                if (special != null && special.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  const Text(
                    'Demandes spéciales',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(special, style: TextStyle(color: Colors.grey[700])),
                ],
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Tables assignées',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _AssignedTablesSection(reservation: r),
            const SizedBox(height: 24),
            ..._actionButtons(context, ref, r, canComplete),
          ],
        ),
      ),
    );
  }

  List<Widget> _actionButtons(
    BuildContext context,
    WidgetRef ref,
    Reservation r,
    bool canComplete,
  ) {
    if (r.status == 'completed' || r.status == 'cancelled') {
      return [];
    }

    final buttons = <Widget>[];

    if (r.canComplete) {
      buttons.add(
        ElevatedButton.icon(
          onPressed: canComplete
              ? () => _onComplete(context, ref, r)
              : null,
          icon: const Icon(Icons.check_circle),
          label: const Text('Marquer comme terminée'),
        ),
      );
      if (!canComplete) {
        buttons.add(
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'La réservation ne peut être terminée que durant son service ou après celui-ci',
              style: TextStyle(color: Colors.red[700], fontSize: 13),
            ),
          ),
        );
      }
      buttons.add(const SizedBox(height: 8));
    }

    if (r.canCancel) {
      buttons.add(
        OutlinedButton.icon(
          onPressed: () => _onCancel(context, ref, r),
          icon: const Icon(Icons.cancel),
          label: const Text('Annuler'),
        ),
      );
      buttons.add(const SizedBox(height: 8));
    }

    if (r.canConfirm) {
      buttons.add(
        FilledButton.icon(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AssignTablesPage(
                reservationId: r.id,
                restaurantId: r.restaurantId,
                returnTab: returnTab,
              ),
            ),
          ).then((_) => onChanged()),
          icon: const Icon(Icons.table_restaurant),
          label: const Text('Confirmer'),
        ),
      );
      buttons.add(
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            'Attribuez au moins une table pour confirmer la réservation.',
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
        ),
      );
    }

    return buttons;
  }

  Future<void> _onCancel(BuildContext context, WidgetRef ref, Reservation r) async {
    final ok = await showConfirmDialog(
      context,
      title: 'Annuler la réservation',
      message: 'Confirmer l\'annulation de cette réservation ?',
      isDestructive: true,
    );
    if (!ok || !context.mounted) return;

    try {
      await ref
          .read(managerReservationsProvider(r.restaurantId).notifier)
          .cancel(r);
      onChanged();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Réservation annulée')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _onComplete(
    BuildContext context,
    WidgetRef ref,
    Reservation r,
  ) async {
    final ok = await showConfirmDialog(
      context,
      title: 'Terminer la réservation',
      message: 'Marquer cette réservation comme terminée ?',
    );
    if (!ok || !context.mounted) return;

    try {
      await ref
          .read(managerReservationsProvider(r.restaurantId).notifier)
          .complete(r);
      onChanged();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Réservation terminée')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return const Color(0xFFFF9800);
      case 'confirmed':
        return Colors.green;
      case 'completed':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

class _AssignedTablesSection extends StatelessWidget {
  const _AssignedTablesSection({required this.reservation});

  final Reservation reservation;

  @override
  Widget build(BuildContext context) {
    if (reservation.status == 'pending') {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Aucune table assignée (en attente de confirmation)',
            style: TextStyle(color: Colors.grey[700]),
          ),
        ),
      );
    }

    if (reservation.assignedTables.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Aucune table assignée',
            style: TextStyle(color: Colors.grey[700]),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < reservation.assignedTables.length; i++) ...[
              if (i > 0) const SizedBox(height: 8),
              _TableRow(table: reservation.assignedTables[i]),
            ],
          ],
        ),
      ),
    );
  }
}

class _TableRow extends StatelessWidget {
  const _TableRow({required this.table});

  final model.Table table;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.table_restaurant, size: 20),
        const SizedBox(width: 8),
        Text('Table ${table.tableNumble}'),
        const SizedBox(width: 8),
        Text(
          '(${table.capacity} places)',
          style: TextStyle(color: Colors.grey[600]),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.icon, this.text, {this.bold = false});

  final IconData icon;
  final String text;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: bold ? 16 : 14,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }
}
