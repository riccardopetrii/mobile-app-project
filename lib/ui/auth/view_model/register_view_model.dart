import 'package:flutter/foundation.dart';

import '../../../data/repositories/settings_repository.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../domain/models/user.dart';
import '../../../utils/command.dart';
import '../../core/ui/vivo_message.dart';
import '../../../utils/password.dart';
import '../../../utils/result.dart';

/// I dati raccolti dal modulo di registrazione.
class RegistrationData {
  const RegistrationData({
    required this.nome,
    required this.email,
    required this.password,
    required this.confermaPassword,
    this.cognome,
  });

  final String nome;

  final String? cognome;

  /// L'indirizzo di posta con cui si accede: insieme alla password è la
  /// credenziale confrontata dalla schermata di accesso.
  final String email;

  final String password;

  /// La stessa password scritta una seconda volta.
  ///
  /// Serve perché la password non si recupera: se la prima scrittura contiene
  /// un errore di battitura, non c'è modo di risalirvi.
  final String confermaPassword;
}

/// Lo stato della schermata di registrazione.
///
/// Crea l'unico profilo locale e apre subito la sessione: non essendoci alcun
/// server, non c'è niente da confermare o da verificare altrove.
class RegisterViewModel extends ChangeNotifier {
  RegisterViewModel({
    required UserRepository users,
    required SettingsRepository settings,
  }) : _users = users,
       _settings = settings {
    register = Command1<void, RegistrationData>(_register);
  }

  final UserRepository _users;
  final SettingsRepository _settings;

  late final Command1<void, RegistrationData> register;

  String? _errorMessage;
  MessageTone _errorTone = MessageTone.notice;

  String? get errorMessage => _errorMessage;

  /// Il tono con cui va mostrato [errorMessage].
  ///
  /// Un guasto dell'applicazione e un'istruzione all'utente non si mostrano
  /// uguali: vedi `MessageTone`.
  MessageTone get errorTone => _errorTone;

  Future<Result<void>> _register(RegistrationData dati) async {
    _errorMessage = null;

    final nome = dati.nome.trim();
    if (nome.isEmpty) {
      return _rifiuta('Scrivi il tuo nome per creare il profilo.');
    }

    final email = dati.email.trim();
    if (email.isEmpty) {
      return _rifiuta('Scrivi la tua email per creare il profilo.');
    }
    if (!_emailValida(email)) {
      return _rifiuta('Questa email non sembra giusta. Controllala.');
    }

    final passwordNonValida = PasswordHasher.validationError(dati.password);
    if (passwordNonValida != null) return _rifiuta(passwordNonValida);

    if (dati.password != dati.confermaPassword) {
      return _rifiuta('Le due password non coincidono. Riscrivile.');
    }

    final salvato = await _users.save(
      User(
        nome: nome,
        cognome: dati.cognome?.trim(),
        email: email,
        password: PasswordHasher.hash(dati.password),
        createdAt: DateTime.now(),
      ),
    );
    if (salvato case final Error<User> errore) {
      _errorMessage = 'Impossibile creare il profilo. Riprova.';
      _errorTone = MessageTone.failure;
      return Result<void>.error(errore.error);
    }

    return _settings.startSession(guest: false);
  }

  /// Ferma l'operazione dicendo all'utente che cosa manca: è un'istruzione,
  /// non un guasto, quindi resta nel tono neutro.
  Result<void> _rifiuta(String messaggio) {
    _errorMessage = messaggio;
    _errorTone = MessageTone.notice;
    return Result<void>.error(Exception(messaggio));
  }

  /// Un controllo minimo: qualcosa, una chiocciola, qualcosa con un punto.
  ///
  /// Non serve di più, perché l'indirizzo non viene spedito a nessun server:
  /// resta sul telefono e serve solo a riconoscere il profilo all'accesso.
  static bool _emailValida(String email) =>
      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
}
