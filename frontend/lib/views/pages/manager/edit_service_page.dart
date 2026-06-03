import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:prbd_2526_c06/core/Widgets/confirm_dialog.dart';
import 'package:prbd_2526_c06/core/Widgets/reservite_app_bar.dart';
import 'package:prbd_2526_c06/model/service.dart';
import 'package:prbd_2526_c06/providers/restaurant_services_provider.dart';

class EditServicePage extends ConsumerStatefulWidget {
  const EditServicePage({
    super.key,
    required this.restaurantId,
    this.service,
  });

  final int restaurantId;
  final Service? service;

  @override
  ConsumerState<EditServicePage> createState() => _EditServicePageState();
}

class _EditServicePageState extends ConsumerState<EditServicePage> {
  late int _dayOfWeek;
  late final TextEditingController _startController;
  late final TextEditingController _endController;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _dayOfWeek = widget.service?.dayOfWeek ?? 1;
    _startController = TextEditingController(text: widget.service?.startTime ?? '12:00');
    _endController = TextEditingController(text: widget.service?.endTime ?? '14:00');
  }

  @override
  void dispose() {
    _startController.dispose();
    _endController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _submitting = true);
    try {
      await Service.save(
        widget.service?.id,
        widget.restaurantId,
        _dayOfWeek,
        _startController.text.trim(),
        _endController.text.trim(),
      );
      ref.invalidate(restaurantServicesProvider(widget.restaurantId));
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

  Future<void> _refreshFromServer() async {
    ref.invalidate(restaurantServicesProvider(widget.restaurantId));
    final serviceId = widget.service?.id;
    if (serviceId == null) return;
    try {
      final services = await ref.read(
        restaurantServicesProvider(widget.restaurantId).future,
      );
      final updated = services.where((s) => s.id == serviceId).firstOrNull;
      if (updated != null && mounted) {
        setState(() {
          _dayOfWeek = updated.dayOfWeek;
          _startController.text = updated.startTime;
          _endController.text = updated.endTime;
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

  Future<void> _delete() async {
    final service = widget.service;
    if (service == null) return;

    final ok = await showConfirmDialog(
      context,
      title: 'Supprimer le service',
      message: 'Confirmer la suppression de ce service ?',
      isDestructive: true,
    );
    if (!ok || !mounted) return;

    setState(() => _submitting = true);
    try {
      await service.delete();
      ref.invalidate(restaurantServicesProvider(widget.restaurantId));
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
    final isEdit = widget.service != null;

    return Scaffold(
      appBar: ReserviteAppBar(
        title: isEdit ? 'Modifier le service' : 'Nouveau service',
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
              DropdownButtonFormField<int>(
                key: ValueKey(_dayOfWeek),
                initialValue: _dayOfWeek,
                decoration: const InputDecoration(labelText: 'Jour'),
                items: const [
                  DropdownMenuItem(value: 1, child: Text('Lundi')),
                  DropdownMenuItem(value: 2, child: Text('Mardi')),
                  DropdownMenuItem(value: 3, child: Text('Mercredi')),
                  DropdownMenuItem(value: 4, child: Text('Jeudi')),
                  DropdownMenuItem(value: 5, child: Text('Vendredi')),
                  DropdownMenuItem(value: 6, child: Text('Samedi')),
                  DropdownMenuItem(value: 7, child: Text('Dimanche')),
                ],
                onChanged: _submitting
                    ? null
                    : (value) {
                        if (value != null) setState(() => _dayOfWeek = value);
                      },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _startController,
                enabled: !_submitting,
                decoration: const InputDecoration(
                  labelText: 'Heure de début',
                  hintText: '12:00',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _endController,
                enabled: !_submitting,
                decoration: const InputDecoration(
                  labelText: 'Heure de fin',
                  hintText: '14:00',
                ),
              ),
              const Spacer(),
              if (isEdit)
                OutlinedButton.icon(
                  onPressed: _submitting ? null : _delete,
                  icon: const Icon(Icons.delete, color: Colors.red),
                  label: const Text('Supprimer', style: TextStyle(color: Colors.red)),
                ),
              if (isEdit) const SizedBox(height: 8),
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
