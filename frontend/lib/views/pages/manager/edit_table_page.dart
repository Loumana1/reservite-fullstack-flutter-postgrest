import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:prbd_2526_c06/core/Widgets/reservite_app_bar.dart';
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
  late final TextEditingController _capacityController;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _numberController = TextEditingController(
      text: '${widget.table?.tableNumble ?? 1}',
    );
    _capacityController = TextEditingController(
      text: '${widget.table?.capacity ?? 2}',
    );
  }

  @override
  void dispose() {
    _numberController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  Future<void> _refreshFromServer() async {
    ref.invalidate(restaurantTablesProvider(widget.restaurantId));
    final tableId = widget.table?.id;
    if (tableId == null) return;
    try {
      final tables = await ref.read(
        restaurantTablesProvider(widget.restaurantId).future,
      );
      final updated = tables.where((t) => t.id == tableId).firstOrNull;
      if (updated != null && mounted) {
        setState(() {
          _numberController.text = '${updated.tableNumble}';
          _capacityController.text = '${updated.capacity}';
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    }
  }

  Future<void> _save() async {
    final tableNumber = int.tryParse(_numberController.text.trim());
    final capacity = int.tryParse(_capacityController.text.trim());
    if (tableNumber == null || tableNumber <= 0 || capacity == null || capacity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Numéro et capacité doivent être des entiers positifs')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      await model.Table.save(
        widget.table?.id,
        widget.restaurantId,
        tableNumber,
        capacity,
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

    return Scaffold(
      appBar: ReserviteAppBar(
        title: isEdit ? 'Modifier la table' : 'Nouvelle table',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _submitting ? null : () => Navigator.pop(context),
        ),
        onRefresh: isEdit ? _refreshFromServer : null,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _numberController,
                enabled: !_submitting,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Numéro de table'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _capacityController,
                enabled: !_submitting,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Capacité'),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: _submitting ? null : _save,
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
