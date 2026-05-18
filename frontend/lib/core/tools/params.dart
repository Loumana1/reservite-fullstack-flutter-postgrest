import 'package:flutter/foundation.dart';
import 'dart:io';

import 'package:hive_ce/hive.dart';
class Params {
  static const String _box = 'params';

  static Future<void> init() async {
    if (kIsWeb || !Platform.isAndroid) {
      Hive.init('.hive');
    } else {
      Hive.init('/data/data/com.example.reservite/files/.hive');
    }
    await Hive.openBox(_box);
  }

  static Future<void> setValue(String key, dynamic value) async {
    var box = Hive.box(_box);
    await box.put(key, value);
    await box.compact();
  }


}