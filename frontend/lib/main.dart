
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:prbd_2526_c06/app/my_app.dart';

import 'core/tools/params.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Params.init();
  await initializeDateFormatting('fr_FR', null);
  runApp(const ProviderScope(child : MyApp()));
}