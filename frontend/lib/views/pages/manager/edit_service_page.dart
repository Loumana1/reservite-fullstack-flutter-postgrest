import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:prbd_2526_c06/core/tools/service_time_picker.dart';
import 'package:prbd_2526_c06/core/Widgets/reservite_app_bar.dart';
import 'package:prbd_2526_c06/model/service.dart';
import 'package:prbd_2526_c06/providers/restaurant_services_provider.dart';

class EditServicePage extends ConsumerStatefulWidget {
  const EditServicePage({
    super.key,
    required this.restaurantId,
    this.service,
    this.initialDayOfWeek,
  });

  final int restaurantId;
  final Service? service;
  final int? initialDayOfWeek;

  @override
  ConsumerState<EditServicePage> createState() => _EditServicePageState();
}

class _EditServicePageState extends ConsumerState<EditServicePage> {
  late int _dayOfWeek;
  late int _startHour;
  late int _startMinute;
  late int _endHour;
  late int _endMinute;
  bool _submitting = false;
  String? _validationError;

  @override
  void initState() {
    super.initState();
    final s = widget.service;
    _dayOfWeek = s?.dayOfWeek ?? widget.initialDayOfWeek ?? 1;
    final start = parseServiceTime(s?.startTime, defaultHour: 12);
    final end = parseServiceTime(s?.endTime, defaultHour: 14);
    _startHour = start.$1;
    _startMinute = start.$2;
    _endHour = end.$1;
    _endMinute = end.$2;
  }

  Future<void> _refreshFromServer() async {
    final serviceId = widget.service?.id;
    if (serviceId == null) return;
    ref.invalidate(restaurantServicesProvider(widget.restaurantId));
    try {
      final services = await ref.read(
        restaurantServicesProvider(widget.restaurantId).future,
      );
      final updated = services.where((s) => s.id == serviceId).firstOrNull;
      if (updated != null && mounted) {
        final start = parseServiceTime(updated.startTime);
        final end = parseServiceTime(updated.endTime);
        setState(() {
          _dayOfWeek = updated.dayOfWeek;
          _startHour = start.$1;
          _startMinute = start.$2;
          _endHour = end.$1;
          _endMinute = end.$2;
          _validationError = null;
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
    setState(() {
      _submitting = true;
      _validationError = null;
    });
    try {
      await Service.save(
        widget.service?.id,
        widget.restaurantId,
        _dayOfWeek,
        formatServiceTime(_startHour, _startMinute),
        formatServiceTime(_endHour, _endMinute),
      );
      ref.invalidate(restaurantServicesProvider(widget.restaurantId));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _validationError = e.toString().replaceFirst('Exception: ', ''));
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
        actions: [
          IconButton(
            tooltip: 'Enregistrer',
            onPressed: _submitting ? null : _save,
            icon: _submitting
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.save),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<int>(
                key: ValueKey(_dayOfWeek),
                initialValue: _dayOfWeek,
                decoration: const InputDecoration(
                  labelText: 'Jour',
                  border: OutlineInputBorder(),
                ),
                items: [
                  for (int d = 1; d <= 7; d++)
                    DropdownMenuItem(
                      value: d,
                      child: Text(serviceDayLabel(d)),
                    ),
                ],
                onChanged: _submitting
                    ? null
                    : (value) {
                        if (value != null) {
                          setState(() {
                            _dayOfWeek = value;
                            _validationError = null;
                          });
                        }
                      },
              ),
              if (_validationError != null) ...[
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.error_outline, color: Colors.red[700], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _validationError!,
                        style: TextStyle(color: Colors.red[700], fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      key: ValueKey('sh-$_startHour'),
                      initialValue: _startHour,
                      decoration: const InputDecoration(
                        labelText: 'Heure de début (heure)',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        for (int h = 0; h < 24; h++)
                          DropdownMenuItem(
                            value: h,
                            child: Text('${h.toString().padLeft(2, '0')} h'),
                          ),
                      ],
                      onChanged: _submitting
                          ? null
                          : (v) => setState(() {
                                _startHour = v ?? _startHour;
                                _validationError = null;
                              }),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      key: ValueKey('sm-$_startMinute'),
                      initialValue: _startMinute,
                      decoration: const InputDecoration(
                        labelText: 'Minutes',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        for (final m in serviceMinuteOptions)
                          DropdownMenuItem(
                            value: m,
                            child: Text('${m.toString().padLeft(2, '0')} min'),
                          ),
                      ],
                      onChanged: _submitting
                          ? null
                          : (v) => setState(() {
                                _startMinute = v ?? _startMinute;
                                _validationError = null;
                              }),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      key: ValueKey('eh-$_endHour'),
                      initialValue: _endHour,
                      decoration: const InputDecoration(
                        labelText: 'Heure de fin (heure)',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        for (int h = 0; h < 24; h++)
                          DropdownMenuItem(
                            value: h,
                            child: Text('${h.toString().padLeft(2, '0')} h'),
                          ),
                      ],
                      onChanged: _submitting
                          ? null
                          : (v) => setState(() {
                                _endHour = v ?? _endHour;
                                _validationError = null;
                              }),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      key: ValueKey('em-$_endMinute'),
                      initialValue: _endMinute,
                      decoration: const InputDecoration(
                        labelText: 'Minutes',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        for (final m in serviceMinuteOptions)
                          DropdownMenuItem(
                            value: m,
                            child: Text('${m.toString().padLeft(2, '0')} min'),
                          ),
                      ],
                      onChanged: _submitting
                          ? null
                          : (v) => setState(() {
                                _endMinute = v ?? _endMinute;
                                _validationError = null;
                              }),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
