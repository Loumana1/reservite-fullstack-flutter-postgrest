import 'package:flutter/material.dart';

import 'package:prbd_2526_c06/core/tools/date_formatters.dart';
import 'package:prbd_2526_c06/model/reservation.dart';
import 'package:prbd_2526_c06/model/restaurant.dart';

class ReservationDetailCard extends StatelessWidget {
  const ReservationDetailCard({
    super.key,
    required this.reservation,
    this.restaurant,
  });

  final Reservation reservation;
  final Restaurant? restaurant;

  @override
  Widget build(BuildContext context) {
    final name = restaurant?.name ?? reservation.restaurantName ?? '';
    final address = restaurant != null
        ? '${restaurant!.address}, ${restaurant!.city}'
        : reservation.restaurantCity ?? '';
    final phone = restaurant?.phone ?? '';
    final special = reservation.specialRequests?.trim();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.restaurant),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            if (address.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      address,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                ],
              ),
            ],
            if (phone.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.phone, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(phone, style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            ],
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 20),
                const SizedBox(width: 8),
                Text(formatReservationDateLabel(reservation.datetime)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.access_time, size: 20),
                const SizedBox(width: 8),
                Text(formatReservationTimeLabel(reservation.datetime)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.people, size: 20),
                const SizedBox(width: 8),
                Text('Nombre de convives: ${reservation.numberOfGuests}'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.info, size: 20),
                const SizedBox(width: 8),
                const Text('Statut: '),
                Chip(
                  label: Text(
                    statusLabel(reservation.status),
                    style: const TextStyle(fontSize: 12, color: Colors.white),
                  ),
                  backgroundColor: _statusColor(reservation.status),
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
      ),
    );
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