import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:prbd_2526_c06/core/Widgets/reservite_app_bar.dart';
import 'package:prbd_2526_c06/model/restaurant.dart';
import 'package:prbd_2526_c06/providers/restaurants_provider.dart';
import 'package:prbd_2526_c06/views/pages/client/restaurant_details_page.dart';

class SearchRestaurantsPage extends ConsumerStatefulWidget {
  const SearchRestaurantsPage({super.key});

  @override
  ConsumerState<SearchRestaurantsPage> createState() =>
      _SearchRestaurantsPageState();
}

class _SearchRestaurantsPageState extends ConsumerState<SearchRestaurantsPage> {
  late final TextEditingController _searchController;

  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: ref.read(restaurantSearchFilterProvider),
    );
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      ref.read(restaurantSearchFilterProvider.notifier).state =
          _searchController.text.trim();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final restaurantsAsync = ref.watch(restaurantsProvider);

    return Scaffold(
      appBar: ReserviteAppBar(
        title: 'Rechercher un restaurant',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        onRefresh: () => ref.read(restaurantsProvider.notifier).refresh(),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                autofocus: true,
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Rechercher par nom, ville, description...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) =>
                    ref.read(restaurantSearchFilterProvider.notifier).state =
                        value,
              ),
            ),
            Expanded(
              child: restaurantsAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Erreur : $e')),
                data: (list) {
                  if (list.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Text(
                          'Aucun restaurant trouvé.\nAffinez votre recherche.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }

                  return Column(
                    children: [
                      if (list.length >= Restaurant.maxSearchResults)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 16,
                          ),
                          color: Colors.orange.shade50,
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 20,
                                color: Colors.orange.shade800,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Trop de résultats trouvés. Veuillez affiner '
                                  'votre recherche pour voir plus de restaurants.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.orange.shade900,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: list.length,
                          itemBuilder: (context, index) {
                            final r = list[index];
                            return Card(
                              margin: EdgeInsets.only(
                                bottom: index < list.length - 1 ? 8 : 0,
                              ),
                              child: ListTile(
                                leading: const Icon(Icons.restaurant, size: 40),
                                title: Text(r.name),
                                subtitle: _RestaurantSubtitle(restaurant: r),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        RestaurantDetailsPage(restaurant: r),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
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

class _RestaurantSubtitle extends StatelessWidget {
  const _RestaurantSubtitle({required this.restaurant});

  final Restaurant restaurant;

  @override
  Widget build(BuildContext context) {
    final price = _formatPriceRange(restaurant.priceRange);
    final lastResa = restaurant.lastReservationDate;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.location_on, size: 14, color: Colors.grey),
            const SizedBox(width: 4),
            Text(restaurant.city),
            if (restaurant.rating != null) ...[
              const SizedBox(width: 12),
              const Icon(Icons.star, size: 14, color: Colors.amber),
              const SizedBox(width: 2),
              Text(
                restaurant.rating!.toStringAsFixed(1),
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
            if (price.isNotEmpty) ...[
              const SizedBox(width: 12),
              Text(
                price,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ],
        ),
        if (lastResa != null) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.access_time, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                'Dernière réservation: '
                '${DateFormat('EEE dd/MM/yyyy', 'fr_FR').format(lastResa)}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ],
        if (restaurant.pendingRequests != null &&
            restaurant.pendingRequests! > 0) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.pending, size: 14, color: Colors.orange),
              const SizedBox(width: 4),
              Text(
                '${restaurant.pendingRequests} demande(s) en attente',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.orange,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  String _formatPriceRange(int? range) {
    if (range == null || range <= 0) return '';
    return '€' * range;
  }
}
