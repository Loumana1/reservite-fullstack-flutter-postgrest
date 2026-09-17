import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:prbd_2526_c06/core/Widgets/confirm_dialog.dart';
import 'package:prbd_2526_c06/core/Widgets/reservation_detail_card.dart';
import 'package:prbd_2526_c06/core/Widgets/reservite_app_bar.dart';
import 'package:prbd_2526_c06/model/restaurant.dart';
import 'package:prbd_2526_c06/providers/client_reservations_provider.dart';
import 'package:prbd_2526_c06/providers/reservation_detail_provider.dart';
import 'package:prbd_2526_c06/providers/simulated_time_provider.dart';
import 'package:prbd_2526_c06/views/pages/client/reservation_form_page.dart';

import '../../../model/reservation.dart';

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
        onRefresh: () async {
          await ref.read(simulatedTimeProvider.notifier).refresh();
          refreshReservationDetail(ref, reservationId);
          await ref.read(clientReservationsProvider.notifier).refresh();
        },
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
            final simulatedTime =
                ref.watch(simulatedTimeProvider).value ?? DateTime.now();
            final isPast = reservation.datetime.isBefore(simulatedTime);

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
                                onPressed: isPast
                                    ? null
                                    : () async {
                                        final restaurant =
                                            await Restaurant.getById(
                                                reservation.restaurantId);
                                        if (!context.mounted) return;
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                ReservationFormPage(
                                              restaurant: restaurant,
                                              existingReservation: reservation,
                                            ),
                                          ),
                                        );
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
                                  reservation,
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

  Future<void> _onCancelPressed(BuildContext context, WidgetRef ref, Reservation reservation,) async {
    final ok = await showConfirmDialog(
      context,
      title: 'Annuler la réservation',
      message: 'Êtes-vous sûr de vouloir annuler cette réservation ?',
      isDestructive: true,
    );
    if (!ok || !context.mounted) return;

    try {
      await cancelReservationDetail(ref, reservation);
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
