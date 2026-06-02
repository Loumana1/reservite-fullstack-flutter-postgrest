import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prbd_2526_c06/model/reservation.dart';
import 'package:prbd_2526_c06/model/slot.dart';
import 'package:prbd_2526_c06/providers/client_reservations_provider.dart';
import 'package:prbd_2526_c06/providers/simulated_time_provider.dart';

class ReservationFormState {
  const ReservationFormState({
    this.restaurantId,
    this.selectedDate,
    this.selectedSlot,
    this.guests = 2,
    this.specialRequests = '',
    this.slotsResponse,
    this.loadingSlots = false,
    this.capacityOk = true,
    this.checkingCapacity = false,
  });

  final int? restaurantId;
  final DateTime? selectedDate;
  final Slot? selectedSlot;
  final int guests;
  final String specialRequests;
  final SlotsResponse? slotsResponse;
  final bool loadingSlots;
  final bool capacityOk;
  final bool checkingCapacity;

  ReservationFormState copyWith({
    int? restaurantId,
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
        restaurantId: restaurantId ?? this.restaurantId,
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


final reservationFormProvider =
    NotifierProvider<ReservationFormNotifier, ReservationFormState>(
  ReservationFormNotifier.new,
);

class ReservationFormNotifier
    extends Notifier<ReservationFormState> {
  ReservationFormNotifier(this.restaurantId);

  final int restaurantId;
  Timer? _guestsDebounce;
  bool _initialized = false;

  @override
  ReservationFormState build() {
    return const ReservationFormState();
  }

    Future.microtask(() => loadSlots(initialDate));

  void init(int restaurantId) {
    if (_initialized && state.restaurantId == restaurantId) return;
    _initialized = true;
    final reference = ref.read(simulatedTimeProvider).value ?? DateTime.now();
    final initialDate =
        DateTime(reference.year, reference.month, reference.day);

    state = ReservationFormState(
      restaurantId: restaurantId,
      selectedDate: initialDate,
    );
    Future.microtask(() => loadSlots(initialDate));
  }

  Future<void> loadSlots(DateTime date) async {
    final restaurantId = state.restaurantId;
    if (restaurantId == null) return;

    state = state.copyWith(
      selectedDate: date,
      loadingSlots: true,
      clearSelectedSlot: true,
    );
    try {
      final resp = await SlotsResponse.fetch(
        restaurantId: restaurantId,
        date: date,
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
      print(' loadSlots error: $e');
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
    final restaurantId = state.restaurantId;
    if (slot == null || restaurantId == null) return;
    state = state.copyWith(checkingCapacity: true);
    try {
      final ok = await SlotsResponse.checkCapacity(
        restaurantId: restaurantId,
        datetime: slot.datetime,
        guests: state.guests,
      );
      state = state.copyWith(capacityOk: ok, checkingCapacity: false);
    } catch (_) {
      state = state.copyWith(checkingCapacity: false);
    }
  }


  void reset() {
    _initialized = false;
    _guestsDebounce?.cancel();
    state = const ReservationFormState();
  }

  Future<Reservation?> submit() async {
    final slot = state.selectedSlot;
    final restaurantId = state.restaurantId;
    if (slot == null || restaurantId == null) return null;
    try {
      final reservation = await Reservation.save(
        restaurantId: restaurantId,
        datetime: slot.datetime,
        numberOfGuests: state.guests,
        specialRequests:
            state.specialRequests.isEmpty ? null : state.specialRequests,
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
