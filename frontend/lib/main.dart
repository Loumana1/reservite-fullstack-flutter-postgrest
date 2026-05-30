/*
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

 */

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:prbd_2526_c06/core/tools/params.dart';
import 'package:prbd_2526_c06/views/pages/client/reservation_details_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR', null);
  await Params.init();

  runApp(
    ProviderScope(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        home: const ReservationDetailsPage(reservationId: 1),
      ),
    ),
  );
}