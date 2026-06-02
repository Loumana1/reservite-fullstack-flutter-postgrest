import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prbd_2526_c06/core/tools/date_formatters.dart';
import 'package:prbd_2526_c06/core/Widgets/reservite_app_bar.dart';
import 'package:prbd_2526_c06/model/restaurant.dart';
import 'package:prbd_2526_c06/model/slot.dart';
import 'package:prbd_2526_c06/providers/reservation_form_provider.dart';

import 'package:prbd_2526_c06/providers/simulated_time_provider.dart';

class ReservationFormPage extends ConsumerStatefulWidget {
  const ReservationFormPage({super.key, required this.restaurant});

  final Restaurant restaurant;

  @override
  ConsumerState<ReservationFormPage> createState() =>
      _ReservationFormPageState();
}

class _ReservationFormPageState extends ConsumerState<ReservationFormPage> {
  bool _submitting = false;

  Future<void> _pickDate(
    ReservationFormNotifier notifier,
    DateTime selectedDate,
    DateTime simTime,
  ) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(simTime.year, simTime.month, simTime.day),
      lastDate: simTime.add(const Duration(days: 365)),
      locale: const Locale('fr', 'FR'),
    );
    if (picked != null) {
      await notifier.loadSlots(picked);
    }
  }

  Future<void> _submit(ReservationFormNotifier notifier) async {
    setState(() => _submitting = true);
    final created = await notifier.submit();
    if (!mounted) return;
    setState(() => _submitting = false);

    if (created != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Réservation créée avec succès !'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.popUntil(context, ModalRoute.withName('/home_client'));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Échec de la création de la réservation'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final restaurant = widget.restaurant;
    final state = ref.watch(reservationFormProvider(restaurant.id));
    final notifier =
        ref.read(reservationFormProvider(restaurant.id).notifier);
    final simTime =
        ref.watch(simulatedTimeProvider).value ?? DateTime.now();
    final selectedDate = state.selectedDate;

    final canSubmit = state.selectedSlot != null &&
        state.capacityOk &&
        !state.loadingSlots &&
        !state.checkingCapacity &&
        !_submitting;

    return Scaffold(
      appBar: ReserviteAppBar(
        title: 'Nouvelle réservation',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        onRefresh: () async {
          await ref.read(simulatedTimeProvider.notifier).refresh();
          await notifier.loadSlots(state.selectedDate);
        },
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: ListTile(
                  leading: const Icon(Icons.restaurant),
                  title: Text(
                    restaurant.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text('${restaurant.address}, ${restaurant.city}'),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _pickDate(notifier, selectedDate, simTime),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Date'),
                                    Text(
                                      formatDateLong(selectedDate),
                                      style: theme.textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.remove),
                    tooltip: 'Jour précédent',
                    onPressed: () {
                      final d = selectedDate.subtract(const Duration(days: 1));
                      final min = DateTime(
                        simTime.year,
                        simTime.month,
                        simTime.day,
                      );
                      if (!d.isBefore(min)) {
                        notifier.loadSlots(d);
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    tooltip: 'Jour suivant',
                    onPressed: () {
                      notifier.loadSlots(
                        selectedDate.add(const Duration(days: 1)),
                      );
                    },
                  ),
                ],
              ),

              if (state.loadingSlots)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (state.slotsResponse?.restaurantClosed == true)
                const _InfoBanner(
                  icon: Icons.lock,
                  color: Colors.grey,
                  title: 'Restaurant fermé',
                  message:
                      "Le restaurant n'a pas de service prévu ce jour-là. "
                      'Choisissez une autre date.',
                )
              else if (state.slotsResponse?.userFullyBooked == true)
                const _InfoBanner(
                  icon: Icons.event_busy,
                  color: Colors.orange,
                  title: 'Plus de créneaux disponibles',
                  message:
                      'Vous avez déjà des réservations couvrant tous les '
                      'services de ce jour. Choisissez une autre date.',
                ),
              const SizedBox(height: 8),
              const Text(
                'Créneaux disponibles',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              if (!state.loadingSlots &&
                  state.slotsResponse?.restaurantClosed != true &&
                  state.slotsResponse?.userFullyBooked != true)
                GridView.count(
                  crossAxisCount: 4,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 2.2,
                  children: (state.slotsResponse?.slots ?? const <Slot>[])
                      .map((slot) {
                    final isSelected =
                        state.selectedSlot?.datetime == slot.datetime;
                    return ChoiceChip(
                      label: Text(formatSlotTime(slot.datetime)),
                      selected: isSelected,
                      onSelected: slot.available
                          ? (_) => notifier.selectSlot(slot)
                          : null,
                      labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    );
                  }).toList(),
                ),
              const SizedBox(height: 24),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.people),
                title: const Text('Nombre de convives'),
                subtitle: Text('${state.guests}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove),
                      onPressed: state.guests > 1
                          ? () => notifier.setGuests(state.guests - 1)
                          : null,
                    ),
                    if (state.checkingCapacity)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: state.guests < 20
                          ? () => notifier.setGuests(state.guests + 1)
                          : null,
                    ),
                  ],
                ),
              ),
              if (!state.capacityOk && state.selectedSlot != null)
                const _InfoBanner(
                  icon: Icons.warning_amber,
                  color: Colors.deepOrange,
                  title: 'Capacité insuffisante',
                  message:
                      'La capacité des tables disponibles ne suffit pas pour '
                      'le créneau et le nombre de convives choisis.',
                ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: state.specialRequests,
                decoration: const InputDecoration(
                  labelText: 'Demandes spéciales (optionnel)',
                  border: OutlineInputBorder(),
                  hintText: 'Allergies, préférences...',
                  prefixIcon: Icon(Icons.notes),
                ),
                maxLines: 3,
                onChanged: notifier.setSpecialRequests,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: canSubmit ? () => _submit(notifier) : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                icon: _submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check),
                label: Text(
                  _submitting ? 'Création…' : 'Créer la réservation',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        border: Border.all(color: color.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(message, style: TextStyle(color: color, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
