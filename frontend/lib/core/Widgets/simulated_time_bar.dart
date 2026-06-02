import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:prbd_2526_c06/core/tools/date_formatters.dart';
import 'package:prbd_2526_c06/providers/simulated_time_provider.dart';


class SimulatedTimeBar extends ConsumerWidget {
  const SimulatedTimeBar({super.key});

  static const _textStyle = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.normal,
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final simulatedAsync = ref.watch(simulatedTimeProvider);

    return simulatedAsync.when(
      loading: () => Text(
        'Chargement du temps simulé…',
        style: _textStyle.copyWith(color: Colors.grey[400]),
      ),
      error: (_, _) => Text(
        'Erreur temps simulé',
        style: _textStyle.copyWith(color: Colors.red[200]),
      ),
      data: (simulatedTime) => GestureDetector(
        onTap: () => editSimulatedTime(context, ref, simulatedTime),
        child: Tooltip(
          message:
              'Date/heure simulée pour les tests.\n'
              'Touchez pour modifier la date ou l\'heure.',
          child: Text(
            formatSimulatedTime(simulatedTime),
            style: _textStyle.copyWith(color: Colors.grey[400]),
          ),
        ),
      ),
    );
  }
}


Future<void> editSimulatedTime(
  BuildContext context,
  WidgetRef ref,
  DateTime current,
) async {
  final choice = await showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(
              formatSimulatedTime(current),
              style: Theme.of(ctx).textTheme.titleSmall,
              textAlign: TextAlign.center,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.calendar_today),
            title: const Text('Modifier la date'),
            subtitle: const Text('Conserver l\'heure actuelle'),
            onTap: () => Navigator.pop(ctx, 'date'),
          ),
          ListTile(
            leading: const Icon(Icons.access_time),
            title: const Text('Modifier l\'heure'),
            subtitle: const Text('Conserver la date actuelle'),
            onTap: () => Navigator.pop(ctx, 'time'),
          ),
        ],
      ),
    ),
  );

  if (!context.mounted || choice == null) return;

  DateTime? updated;
  switch (choice) {
    case 'date':
      updated = await _pickDateOnly(context, current);
      break;
    case 'time':
      updated = await _pickTimeOnly(context, current);
      break;
    default:
      return;
  }

  if (updated == null || !context.mounted) return;
  await ref.read(simulatedTimeProvider.notifier).setTime(updated);
}

Future<DateTime?> _pickDateOnly(BuildContext context, DateTime current) async {
  final date = await showDatePicker(
    context: context,
    initialDate: current,
    firstDate: DateTime(2020),
    lastDate: DateTime(2030),
    helpText: 'Date simulée',
  );
  if (date == null) return null;
  return DateTime(
    date.year,
    date.month,
    date.day,
    current.hour,
    current.minute,
  );
}

Future<DateTime?> _pickTimeOnly(BuildContext context, DateTime current) async {
  final time = await showTimePicker(
    context: context,
    initialTime: TimeOfDay(hour: current.hour, minute: current.minute),
    initialEntryMode: TimePickerEntryMode.input,
    helpText: 'Heure simulée',
  );
  if (time == null) return null;
  return DateTime(
    current.year,
    current.month,
    current.day,
    time.hour,
    time.minute,
  );
}
