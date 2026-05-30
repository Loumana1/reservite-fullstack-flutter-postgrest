import 'package:flutter/material.dart';

Future<bool> showConfirmDialog(
    BuildContext context, {
      required String title,
      required String message,
    }) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Non'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Oui'),
        ),
      ],
    ),
  );
  return result == true;
}