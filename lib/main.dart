import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'data/secure_store.dart';
import 'services/billing_service.dart';
import 'state/app_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await initializeDateFormatting('es');

  final store = SecureStore();
  await store.init();
  final state = AppState(store);
  final billing = BillingService(onPremiumChanged: state.setPremium);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: state),
        ChangeNotifierProvider.value(value: billing),
      ],
      child: const SamaiApp(),
    ),
  );

  // Billing se inicia después del primer frame para no retrasar el arranque.
  billing.init();
}
