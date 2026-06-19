import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prbd_2526_c06/core/Widgets/reservite_app_bar.dart';
import 'package:prbd_2526_c06/model/restaurant.dart';
import 'package:prbd_2526_c06/model/service.dart';
import 'package:prbd_2526_c06/providers/restaurant_services_provider.dart';
import 'package:prbd_2526_c06/providers/simulated_time_provider.dart';
import 'package:prbd_2526_c06/views/pages/client/reservation_form_page.dart';

class RestaurantDetailsPage extends ConsumerWidget {
  const RestaurantDetailsPage({super.key, required this.restaurant});

  final Restaurant restaurant;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final servicesAsync = ref.watch(restaurantServicesProvider(restaurant.id));

    return Scaffold(
      appBar: ReserviteAppBar(
        title: 'Détails du restaurant',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        onRefresh: () async {
          await ref.read(simulatedTimeProvider.notifier).refresh();
          await ref
              .read(restaurantServicesProvider(restaurant.id).notifier)
              .refresh();
        },
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                restaurant.name,
                style: const TextStyle(
                    fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  if (restaurant.rating != null) ...[
                    const Icon(Icons.star, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text(restaurant.rating!.toStringAsFixed(1)),
                    const SizedBox(width: 16),
                  ],
                  if (restaurant.priceRange != null &&
                      restaurant.priceRange! > 0) ...[
                    Text('€' * restaurant.priceRange!),
                    const SizedBox(width: 16),
                  ],
                  const Icon(Icons.location_on, size: 16),
                  const SizedBox(width: 4),
                  Text(restaurant.city),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.place, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      restaurant.address,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (restaurant.description != null &&
                  restaurant.description!.isNotEmpty) ...[
                const Text(
                  'Description',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(restaurant.description!),
                const SizedBox(height: 24),
              ],
              const Text(
                'Horaires',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              servicesAsync.when(
                loading: () => const Center(
                    child: CircularProgressIndicator()),
                error: (e, _) =>
                    Text('Erreur chargement horaires : $e'),
                data: (services) =>
                    _buildSchedule(services),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ReservationFormPage(
                          restaurant: restaurant),
                    ),
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text('Réserver'),
                  style: ElevatedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSchedule(List<Service> services) {
    const dayNames = {
      1: 'Lundi',
      2: 'Mardi',
      3: 'Mercredi',
      4: 'Jeudi',
      5: 'Vendredi',
      6: 'Samedi',
      7: 'Dimanche',
    };

    final Map<int, List<Service>> byDay = {};
    for (final s in services) {
      byDay.putIfAbsent(s.dayOfWeek, () => []).add(s);
    }

    for (final list in byDay.values) {
      list.sort((a, b) => a.startTime.compareTo(b.startTime));
    }

    final rows = <Widget>[];
    for (int day = 1; day <= 7; day++) {
      final dayServices = byDay[day];
      final timeText = dayServices != null
          ? dayServices
              .map((s) =>
                  '${s.startTime.substring(0, 5)} - ${s.endTime.substring(0, 5)}')
              .join(', ')
          : 'Fermé';

      rows.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 90,
                child: Text(
                  dayNames[day]!,
                  style:
                      const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
              Expanded(
                child: Text(
                  timeText,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    color: dayServices != null
                        ? null
                        : Colors.grey,
                    fontStyle: dayServices != null
                        ? FontStyle.normal
                        : FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(children: rows);
  }
}