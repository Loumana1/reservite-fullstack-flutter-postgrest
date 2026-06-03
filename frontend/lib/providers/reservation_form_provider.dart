import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prbd_2526_c06/model/reservation.dart';
import 'package:prbd_2526_c06/model/slot.dart';
import 'package:prbd_2526_c06/providers/client_reservations_provider.dart';
import 'package:prbd_2526_c06/providers/simulated_time_provider.dart';

class ReservationFormState {
  const ReservationFormState({
    required this.restaurantId,
    required this.selectedDate,
    this.reservationId,
    this.selectedSlot,
    this.guests = 2,
    this.specialRequests = '',
    this.slotsResponse,
    this.loadingSlots = false,
    this.capacityOk = true,
    this.checkingCapacity = false,
  });

  final int restaurantId;
  final int? reservationId;
  final DateTime selectedDate;
  final Slot? selectedSlot;
  final int guests;
  final String specialRequests;
  final SlotsResponse? slotsResponse;
  final bool loadingSlots;
  final bool capacityOk;
  final bool checkingCapacity;

  ReservationFormState copyWith({
    DateTime? selectedDate,
    Slot? selectedSlot,
    int? guests,
    String? specialRequests,
    SlotsResponse? slotsResponse,
    bool? loadingSlots,
    bool? capacityOk,
    bool? checkingCapacity,
    bool clearSelectedSlot = false,
  }) =>
      ReservationFormState(
        restaurantId: restaurantId,
        reservationId: reservationId,
        selectedDate: selectedDate ?? this.selectedDate,
        selectedSlot:
            clearSelectedSlot ? null : (selectedSlot ?? this.selectedSlot),
        guests: guests ?? this.guests,
        specialRequests: specialRequests ?? this.specialRequests,
        slotsResponse: slotsResponse ?? this.slotsResponse,
        loadingSlots: loadingSlots ?? this.loadingSlots,
        capacityOk: capacityOk ?? this.capacityOk,
        checkingCapacity: checkingCapacity ?? this.checkingCapacity,
      );
}

typedef ReservationFormArg = ({int restaurantId, int? reservationId});

final reservationFormProvider = NotifierProvider.family<
    ReservationFormNotifier, ReservationFormState, ReservationFormArg>(
  ReservationFormNotifier.new,
);

class ReservationFormNotifier extends Notifier<ReservationFormState> {
  ReservationFormNotifier(this.arg);

  final ReservationFormArg arg;

  int get restaurantId => arg.restaurantId;
  int? get reservationId => arg.reservationId;
  
  Timer? _guestsDebounce;

  @override
  ReservationFormState build() {
    final simAsync = ref.watch(simulatedTimeProvider);
    final reference = simAsync.value ?? DateTime.now();
    final initialDate =
        DateTime(reference.year, reference.month, reference.day);

    ref.onDispose(() => _guestsDebounce?.cancel());
    Future.microtask(_initialLoad);

    return ReservationFormState(
      restaurantId: restaurantId,
      reservationId: reservationId,
      selectedDate: initialDate,
    );
  }

  Future<void> _initialLoad() async {
    if (reservationId != null) {
      await _loadFromReservation(reservationId!);
    } else {
      final reference =
          ref.read(simulatedTimeProvider).value ?? DateTime.now();
      await loadSlots(DateTime(
        reference.year,
        reference.month,
        reference.day,
      ));
    }
  }

  /// Rafraîchit créneaux, capacité et (en édition) les données serveur.
  Future<void> reload() async {
    await ref.read(simulatedTimeProvider.notifier).refresh();
    if (reservationId != null) {
      await _loadFromReservation(reservationId!);
    } else {
      await loadSlots(state.selectedDate);
    }
  }

  Future<void> _loadFromReservation(int id) async {
    try {
      final r = await Reservation.getById(id);
      final date = DateTime(r.datetime.year, r.datetime.month, r.datetime.day);
      state = state.copyWith(
        selectedDate: date,
        guests: r.numberOfGuests,
        specialRequests: r.specialRequests ?? '',
      );
      await loadSlots(date);
      final slots = state.slotsResponse?.slots ?? [];
      for (final s in slots) {
        if (_sameMinute(s.datetime, r.datetime)) {
          state = state.copyWith(selectedSlot: s);
          await _refreshCapacity();
          break;
        }
      }
    } catch (_) {
      await loadSlots(state.selectedDate);
    }
  }

  static bool _sameMinute(DateTime a, DateTime b) =>
      a.year == b.year &&
      a.month == b.month &&
      a.day == b.day &&
      a.hour == b.hour &&
      a.minute == b.minute;

  Future<void> loadSlots(DateTime date) async {
    state = state.copyWith(
      selectedDate: date,
      loadingSlots: true,
      clearSelectedSlot: true,
    );
    try {
      final resp = await SlotsResponse.fetch(
        restaurantId: restaurantId,
        date: date,
        excludeReservationId: reservationId,
      );
      final firstAvailable = resp.slots.where((s) => s.available).isNotEmpty
          ? resp.slots.firstWhere((s) => s.available)
          : null;
      state = state.copyWith(
        slotsResponse: resp,
        selectedSlot: firstAvailable,
        loadingSlots: false,
      );
      if (firstAvailable != null) {
        await _refreshCapacity();
      }
    } catch (e) {
      state = state.copyWith(loadingSlots: false);
    }
  }

  void selectSlot(Slot slot) {
    state = state.copyWith(selectedSlot: slot);
    _refreshCapacity();
  }

  void setSpecialRequests(String value) {
    state = state.copyWith(specialRequests: value);
  }

  void setGuests(int guests) {
    state = state.copyWith(guests: guests);
    _guestsDebounce?.cancel();
    _guestsDebounce =
        Timer(const Duration(milliseconds: 500), _refreshCapacity);
  }

  Future<void> _refreshCapacity() async {
    final slot = state.selectedSlot;
    if (slot == null) return;
    state = state.copyWith(checkingCapacity: true);
    try {
      final ok = await SlotsResponse.checkCapacity(
        restaurantId: restaurantId,
        datetime: slot.datetime,
        guests: state.guests,
        excludeReservationId: reservationId,
      );
      state = state.copyWith(capacityOk: ok, checkingCapacity: false);
    } catch (_) {
      state = state.copyWith(checkingCapacity: false);
    }
  }

  Future<Reservation?> submit() async {
    final slot = state.selectedSlot;
    if (slot == null) return null;
    try {
      final reservation = await Reservation.save(
        restaurantId: restaurantId,
        datetime: slot.datetime,
        numberOfGuests: state.guests,
        specialRequests:
            state.specialRequests.isEmpty ? null : state.specialRequests,
        reservationId: reservationId,
      );
      ref
          .read(clientReservationsProvider.notifier)
          .patchReservation(reservation);
      return reservation;
    } catch (_) {
      return null;
    }
  }
}
