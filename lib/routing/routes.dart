import '../data/repositories/settings_repository.dart';

/// I nomi delle schermate raggiungibili con il navigatore.
abstract final class Routes {
  static const String login = '/accesso';

  static const String register = '/registrazione';

  static const String home = '/';

  static const String diary = '/diario';

  static const String profile = '/profilo';

  static const String sos = '/aiuto';

  static const List<String> all = <String>[
    login,
    register,
    home,
    diary,
    profile,
    sos,
  ];
}

/// La schermata da cui parte l'applicazione.
///
/// Chi ha già una sessione aperta - con profilo o come ospite - entra
/// direttamente, senza rivedere l'accesso a ogni avvio.
Future<String> startRoute(SettingsRepository settings) async {
  final aperta = await settings.isLoggedIn();
  return aperta.valueOrNull == true ? Routes.home : Routes.login;
}
