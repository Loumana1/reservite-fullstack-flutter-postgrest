import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:prbd_2526_c06/core/widgets/confirm_dialog.dart';
import 'package:prbd_2526_c06/core/widgets/reservation_detail_card.dart';
import 'package:prbd_2526_c06/core/Widgets/reservite_app_bar.dart';
import 'package:prbd_2526_c06/providers/reservation_detail_provider.dart';

class ReservationDetailsPage extends ConsumerWidget {
  const ReservationDetailsPage({super.key, required this.reservationId});

  final int reservationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(reservationDetailProvider(reservationId));

    return Scaffold(
      appBar: ReserviteAppBar(
        title: 'Détails de la réservation',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        onRefresh: () => refreshReservationDetail(ref, reservationId),
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

            final reservation = detail.reservation;

            return SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ReservationDetailCard(
                      reservation: reservation,
                      restaurant: detail.restaurant,
                    ),
                    if (reservation.canEdit || reservation.canCancel) ...[
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          if (reservation.canEdit)
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                 // formulaire édition
                                },
                                icon: const Icon(Icons.edit),
                                label: const Text('Modifier'),
                              ),
                            ),
                          if (reservation.canEdit && reservation.canCancel)
                            const SizedBox(width: 8),
                          if (reservation.canCancel)
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _onCancelPressed(
                                  context,
                                  ref,
                                ),
                                icon: const Icon(Icons.cancel),
                                label: const Text('Annuler'),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
    );
  }

  Future<void> _onCancelPressed(BuildContext context, WidgetRef ref) async {
    final ok = await showConfirmDialog(
      context,
      title: 'Confirmation',
      message: 'Annuler cette réservation ?',
    );
    if (!ok || !context.mounted) return;

    try {
      await cancelReservationDetail(ref, reservationId);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Réservation annulée')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    }
  }
}
