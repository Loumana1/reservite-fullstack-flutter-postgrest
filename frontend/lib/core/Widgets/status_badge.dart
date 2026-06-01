import 'package:flutter/material.dart';

import 'package:prbd_2526_c06/core/tools/date_formatters.dart';

export 'package:prbd_2526_c06/core/tools/date_formatters.dart' show statusLabel;

Icon statusIcon(String status, {double size = 32}) {
  switch (status) {
    case 'pending':
      return Icon(Icons.pending, size: size, color: Colors.orange);
    case 'confirmed':
      return Icon(Icons.check_circle, size: size, color: Colors.green);
    case 'completed':
      return Icon(Icons.event_available, size: size, color: Colors.blue);
    case 'cancelled':
      return Icon(Icons.cancel, size: size, color: Colors.red);
    default:
      return Icon(Icons.help_outline, size: size, color: Colors.grey);
  }
}