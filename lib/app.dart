import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'config/dependencies.dart';
import 'data/services/avatar_service.dart';
import 'data/services/database_service.dart';
import 'data/services/notification_service.dart';
import 'data/services/preferences_service.dart';
import 'routing/router.dart' as router;
import 'ui/core/themes/theme.dart';

/// L'applicazione Vivo.
///
/// Mette a disposizione servizi, repository e casi d'uso a tutto l'albero e
/// apre la schermata decisa all'avvio da `startRoute`.
class VivoApp extends StatelessWidget {
  const VivoApp({
    required this.initialRoute,
    this.database,
    this.preferences,
    this.notifications,
    this.avatar,
    super.key,
  });

  final String initialRoute;

  final DatabaseService? database;
  final PreferencesService? preferences;
  final NotificationService? notifications;
  final AvatarService? avatar;

  @override
  Widget build(BuildContext context) => MultiProvider(
    providers: providers(
      database: database,
      preferences: preferences,
      notifications: notifications,
      avatar: avatar,
    ),
    child: MaterialApp(
      title: 'Vivo',
      debugShowCheckedModeBanner: false,
      theme: VivoTheme.light(),
      // L'interfaccia è in italiano, comprese le parti che arrivano da Flutter:
      // senza queste, il calendario della data di nascita e l'orologio del
      // promemoria comparirebbero in inglese.
      locale: const Locale('it'),
      supportedLocales: const <Locale>[Locale('it')],
      localizationsDelegates: const <LocalizationsDelegate<Object>>[
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      // Vivo usa la propria scala tipografica e ignora la dimensione del
      // carattere scelta nelle impostazioni del telefono. Con il carattere di
      // sistema su "L" i titoli delle card vanno a capo, le schermate crescono
      // e in più punti il contenuto esce dal suo riquadro.
      builder: (context, child) =>
          MediaQuery.withNoTextScaling(child: child ?? const SizedBox.shrink()),
      initialRoute: initialRoute,
      onGenerateRoute: router.onGenerateRoute,
      // Senza questo, da "/accesso" Flutter costruirebbe anche "/" sotto,
      // perché tratta le rotte con la barra come annidate: si ritroverebbe la
      // home sotto la schermata di accesso, raggiungibile tornando indietro.
      onGenerateInitialRoutes: (rotta) => <Route<void>>[
        router.onGenerateRoute(RouteSettings(name: rotta))!,
      ],
    ),
  );
}
