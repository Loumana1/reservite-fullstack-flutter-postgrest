import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:prbd_2526_c06/core/tools/date_formatters.dart';
import 'package:prbd_2526_c06/providers/simulated_time_provider.dart';

class ReserviteAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const ReserviteAppBar({
    super.key,
    required this.title,
    this.leading,
    this.actions = const [],
    this.onRefresh,
  });

  final String title;
  final Widget? leading;
  final List<Widget> actions;
  final VoidCallback? onRefresh;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final simulatedAsync = ref.watch(simulatedTimeProvider);

    final barActions = <Widget>[
      if (onRefresh != null)
        IconButton(
          icon: const Icon(Icons.refresh),
          tooltip: 'Rafraîchir les données',
          onPressed: onRefresh,
        ),
      ...actions,
    ];

    return AppBar(
      leading: leading,
      title: Text(title),
      automaticallyImplyLeading: false,
      actions: barActions,
      elevation: 2,
      backgroundColor: theme.colorScheme.primary,
      foregroundColor: theme.colorScheme.onPrimary,
      surfaceTintColor: Colors.transparent,
      flexibleSpace: Align(
        alignment: Alignment.topCenter,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(top: 2.0),
            child: Tooltip(
              message:
              'Date/heure simulée utilisée pour les tests.\nCliquez pour modifier.',
              child: Text(
                simulatedAsync.when(
                  data: formatSimulatedTime,
                  loading: () => '…',
                  error: (_, _) => '—',
                ),
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[400],
                  fontWeight: FontWeight.normal,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}