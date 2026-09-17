import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:prbd_2526_c06/core/Widgets/simulated_time_bar.dart';

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
      flexibleSpace: const Align(
        alignment: Alignment.topCenter,
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.only(top: 2.0),
            child: SimulatedTimeBar(),
          ),
        ),
      ),
    );
  }
}
