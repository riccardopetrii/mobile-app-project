import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'data/repositories/settings_repository.dart';
import 'data/services/database_service.dart';
import 'data/services/notification_service.dart';
import 'data/services/preferences_service.dart';
import 'routing/routes.dart';

/// Avvia Vivo.
///
/// Prima di disegnare qualsiasi cosa apre il database, prepara le notifiche e
/// controlla se esiste già una sessione: chi è entrato una volta non rivede
/// l'accesso a ogni avvio.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Serve a scrivere le date per esteso in italiano, come "Mercoledì, 12 Agosto".
  await initializeDateFormatting('it');

  final database = DatabaseService();
  final preferences = PreferencesService();
  final notifications = NotificationService();

  await database.database;
  await notifications.init();

  final settings = LocalSettingsRepository(preferences);

  // Riallinea il promemoria a quanto scelto nel profilo: il sistema può averlo
  // dimenticato dopo un riavvio del telefono o un aggiornamento dell'app.
  final promemoria = await settings.reminder();
  final impostazioni = promemoria.valueOrNull;
  if (impostazioni != null) {
    await notifications.syncWith(impostazioni);
  }

  runApp(
    VivoApp(
      initialRoute: await startRoute(settings),
      database: database,
      preferences: preferences,
      notifications: notifications,
    ),
  );
}
