import 'package:flutter/material.dart';

Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  bool isDestructive = false,
  String confirmText = 'Oui',
  String cancelText = 'Non',
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(cancelText),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(
            confirmText,
            style: isDestructive ? const TextStyle(color: Colors.red) : null,
          ),
        ),
      ],
    ),
  );
  return result == true;
}