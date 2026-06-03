import 'package:flutter/material.dart';

import 'package:prbd_2526_c06/core/tools/date_formatters.dart';
import 'package:prbd_2526_c06/core/Widgets/status_badge.dart';
import 'package:prbd_2526_c06/model/reservation.dart';

class ReservationTile extends StatelessWidget {
  const ReservationTile({
    super.key,
    required this.reservation,
    required this.title,
    this.subtitle,
    required this.subtitleIcon,
    required this.onTap,
  });

  final Reservation reservation;
  final String title;
  final String? subtitle;
  final IconData subtitleIcon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Tooltip(
                message: statusLabel(reservation.status),
                child: statusIcon(reservation.status),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(subtitleIcon, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            subtitle!,
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
                        const Icon(Icons.access_time, size: 16),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            '${formatReservationDateLabel(reservation.datetime)} '
                            '${formatReservationTimeLabel(reservation.datetime)}',
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
                          '${reservation.numberOfGuests} convives',
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
  }
}
