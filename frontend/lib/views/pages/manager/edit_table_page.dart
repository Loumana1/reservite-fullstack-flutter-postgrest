import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:prbd_2526_c06/core/Widgets/reservite_app_bar.dart';
import 'package:prbd_2526_c06/model/reservation.dart';
import 'package:prbd_2526_c06/model/table.dart' as model;
import 'package:prbd_2526_c06/providers/restaurant_tables_provider.dart';

class EditTablePage extends ConsumerStatefulWidget {
  const EditTablePage({
    super.key,
    required this.restaurantId,
    this.table,
  });

  final int restaurantId;
  final model.Table? table;

  @override
  ConsumerState<EditTablePage> createState() => _EditTablePageState();
}

class _EditTablePageState extends ConsumerState<EditTablePage> {
  late final TextEditingController _numberController;
  late int _capacity;
  bool _submitting = false;
  bool? _tableHasReservations; // null = chargement, true = bloqué, false = OK

  @override
  void initState() {
    super.initState();
    _numberController = TextEditingController(
      text: '${widget.table?.tableNumble ?? 1}',
    );
    _capacity = widget.table?.capacity ?? 2;

    if (widget.table != null) {
      _checkReservations();
    }
  }

  @override
  void dispose() {
    _numberController.dispose();
    super.dispose();
  }

  Future<void> _checkReservations() async {
    final reservations = await Reservation.getAll(
      restaurantId: widget.restaurantId,
      statusFilter: 'confirmed',
    );
    if (!mounted) return;
    setState(() {
      _tableHasReservations = reservations.any(
        (r) => r.assignedTables.any((t) => t.id == widget.table!.id),
      );
    });
  }

  Future<void> _save() async {
    final tableNumber = int.tryParse(_numberController.text.trim());
    if (tableNumber == null || tableNumber <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le numéro de table doit être un entier positif')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      await model.Table.save(
        widget.table?.id,
        widget.restaurantId,
        tableNumber,
        _capacity,
      );
      ref.invalidate(restaurantTablesProvider(widget.restaurantId));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.table != null;
    final blocked = _tableHasReservations == true;

    return Scaffold(
      appBar: ReserviteAppBar(
        title: isEdit ? 'Modifier la table' : 'Nouvelle table',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _submitting ? null : () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (blocked)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    border: Border.all(color: Colors.orange.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber, color: Colors.orange.shade800),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Cette table est assignée à une réservation confirmée et ne peut pas être modifiée.',
                        ),
                      ),
                    ],
                  ),
                ),
              TextField(
                controller: _numberController,
                enabled: !_submitting && !blocked,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Numéro de table',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              if (_tableHasReservations == null && isEdit)
                const Center(child: CircularProgressIndicator())
              else
                Row(
                  children: [
                    const Text('Capacité', style: TextStyle(fontSize: 16)),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.remove),
                      onPressed: !_submitting && !blocked && _capacity > 1
                          ? () => setState(() => _capacity--)
                          : null,
                    ),
                    Text(
                      '$_capacity personne${_capacity > 1 ? 's' : ''}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: !_submitting && !blocked
                          ? () => setState(() => _capacity++)
                          : null,
                    ),
                  ],
                ),
              const Spacer(),
              ElevatedButton(
                onPressed: _submitting || blocked ? null : _save,
                child: _submitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(isEdit ? 'Enregistrer' : 'Créer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
