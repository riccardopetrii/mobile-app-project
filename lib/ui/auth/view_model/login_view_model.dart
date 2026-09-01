import 'package:flutter/foundation.dart';

import '../../../data/repositories/settings_repository.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../domain/models/user.dart';
import '../../../utils/command.dart';
import '../../core/ui/vivo_message.dart';
import '../../../utils/password.dart';
import '../../../utils/result.dart';

/// Le credenziali scritte nella schermata di accesso.
class Credentials {
  const Credentials({required this.email, required this.password});

  final String email;

  final String password;
}

/// Lo stato della schermata di accesso.
class LoginViewModel extends ChangeNotifier {
  LoginViewModel({
    required UserRepository users,
    required SettingsRepository settings,
  }) : _users = users,
       _settings = settings {
    login = Command1<void, Credentials>(_login);
    continueAsGuest = Command0<void>(_continueAsGuest);
  }

  /// Il messaggio mostrato quando email o password non corrispondono.
  ///
  /// È lo stesso nei due casi di proposito: dire quale delle due è sbagliata
  /// rivelerebbe a chi prova a caso quali indirizzi esistono sul dispositivo.
  static const String credenzialiErrate = 'Email o password non corretti.';

  final UserRepository _users;
  final SettingsRepository _settings;

  late final Command1<void, Credentials> login;

  late final Command0<void> continueAsGuest;

  String? _errorMessage;
  MessageTone _errorTone = MessageTone.notice;

  String? get errorMessage => _errorMessage;

  /// Il tono con cui va mostrato [errorMessage].
  ///
  /// Un guasto dell'applicazione e un'istruzione all'utente non si mostrano
  /// uguali: vedi `MessageTone`.
  MessageTone get errorTone => _errorTone;

  /// Vero se sul dispositivo esiste già un profilo.
  ///
  /// La schermata lo usa per decidere se invitare all'accesso o alla
  /// registrazione.
  Future<bool> hasProfile() async =>
      (await _users.hasUser()).valueOrNull ?? false;

  Future<Result<void>> _login(Credentials credenziali) async {
    _errorMessage = null;
    _errorTone = MessageTone.notice;

    final email = credenziali.email.trim();
    if (email.isEmpty || credenziali.password.isEmpty) {
      return _rifiuta('Scrivi email e password per entrare.');
    }

    final salvato = await _users.currentUser();
    if (salvato case final Error<User?> errore) {
      _errorMessage = 'Impossibile accedere. Riprova.';
      _errorTone = MessageTone.failure;
      return Result<void>.error(errore.error);
    }

    final profilo = salvato.valueOrNull;
    if (profilo == null) {
      return _rifiuta(
        'Su questo dispositivo non c\'è ancora nessun profilo. '
        'Tocca Registrati per crearne uno.',
      );
    }

    final emailGiusta =
        (profilo.email ?? '').trim().toLowerCase() == email.toLowerCase();
    final passwordGiusta = PasswordHasher.matches(
      credenziali.password,
      profilo.password,
    );
    if (!emailGiusta || !passwordGiusta) {
      return _rifiuta(credenzialiErrate);
    }

    return _settings.startSession(guest: false);
  }

  Future<Result<void>> _continueAsGuest() async {
    _errorMessage = null;
    _errorTone = MessageTone.notice;
    return _settings.startSession(guest: true);
  }

  /// Ferma l'operazione dicendo all'utente che cosa manca: è un'istruzione,
  /// non un guasto, quindi resta nel tono neutro.
  Result<void> _rifiuta(String messaggio) {
    _errorMessage = messaggio;
    _errorTone = MessageTone.notice;
    return Result<void>.error(Exception(messaggio));
  }
}
