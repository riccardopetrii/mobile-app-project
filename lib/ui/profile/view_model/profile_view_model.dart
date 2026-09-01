import 'package:flutter/foundation.dart';

import '../../../data/repositories/settings_repository.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../data/services/avatar_service.dart';
import '../../../data/services/notification_service.dart';
import '../../../domain/models/reminder_settings.dart';
import '../../../domain/models/user.dart';
import '../../../domain/use_cases/delete_account_use_case.dart';
import '../../../utils/command.dart';
import '../../../utils/password.dart';
import '../../../utils/result.dart';
import '../../core/ui/vivo_message.dart';

/// I dati anagrafici scritti nella card "I tuoi dati personali".
class ProfileData {
  const ProfileData({
    required this.nome,
    required this.email,
    this.cognome,
    this.dataNascita,
    this.genere,
  });

  final String nome;

  final String email;

  final String? cognome;

  final DateTime? dataNascita;

  final String? genere;
}

/// La sostituzione della password chiesta dal profilo.
class PasswordChange {
  const PasswordChange({
    required this.attuale,
    required this.nuova,
    required this.conferma,
  });

  final String attuale;

  final String nuova;

  final String conferma;
}

/// L'orario scelto per il promemoria giornaliero.
class ReminderTime {
  const ReminderTime({required this.hour, required this.minute});

  final int hour;

  final int minute;
}

/// Lo stato del profilo.
///
/// Tiene insieme le tre parti della schermata: i dati anagrafici con la loro
/// immagine, le impostazioni - promemoria e password - e le due uscite,
/// disconnessione ed eliminazione dell'account.
class ProfileViewModel extends ChangeNotifier {
  ProfileViewModel({
    required UserRepository users,
    required SettingsRepository settings,
    required NotificationService notifications,
    required AvatarService avatar,
    required DeleteAccountUseCase deleteAccount,
  }) : _users = users,
       _settings = settings,
       _notifications = notifications,
       _avatar = avatar,
       _deleteAccount = deleteAccount {
    load = Command0<void>(_load);
    saveProfile = Command1<void, ProfileData>(_saveProfile);
    changeAvatar = Command0<void>(_changeAvatar);
    changePassword = Command1<void, PasswordChange>(_changePassword);
    setReminderEnabled = Command1<void, bool>(_setReminderEnabled);
    setReminderTime = Command1<void, ReminderTime>(_setReminderTime);
    logout = Command0<void>(_logout);
    this.deleteAccount = Command0<void>(_delete);
  }

  static const List<String> generi = <String>[
    'Donna',
    'Uomo',
    'Non binario',
    'Preferisco non dirlo',
  ];

  final UserRepository _users;
  final SettingsRepository _settings;
  final NotificationService _notifications;
  final AvatarService _avatar;
  final DeleteAccountUseCase _deleteAccount;

  late final Command0<void> load;

  late final Command1<void, ProfileData> saveProfile;

  late final Command0<void> changeAvatar;

  late final Command1<void, PasswordChange> changePassword;

  late final Command1<void, bool> setReminderEnabled;

  late final Command1<void, ReminderTime> setReminderTime;

  late final Command0<void> logout;

  late final Command0<void> deleteAccount;

  User? _user;
  bool _isGuest = false;
  ReminderSettings _reminder = const ReminderSettings.initial();
  String? _errorMessage;
  String? _statusMessage;
  MessageTone _errorTone = MessageTone.notice;

  User? get user => _user;

  /// Vero se la sessione è stata aperta come ospite: non ci sono dati
  /// anagrafici da mostrare né da salvare.
  bool get isGuest => _isGuest;

  ReminderSettings get reminder => _reminder;

  String? get errorMessage => _errorMessage;

  String? get statusMessage => _statusMessage;

  MessageTone get errorTone => _errorTone;

  /// Nasconde i due messaggi, dopo che la schermata li ha mostrati.
  void clearMessages() {
    _errorMessage = null;
    _statusMessage = null;
    notifyListeners();
  }

  Future<Result<void>> _load() async {
    _azzeraMessaggi();

    final ospite = await _settings.isGuest();
    _isGuest = ospite.valueOrNull ?? false;

    final salvato = await _users.currentUser();
    if (salvato case final Error<User?> errore) {
      _errorMessage = 'Impossibile caricare il profilo. Riprova.';
      _errorTone = MessageTone.failure;
      return Result<void>.error(errore.error);
    }
    _user = salvato.valueOrNull;

    final impostazioni = await _settings.reminder();
    _reminder = impostazioni.valueOrNull ?? const ReminderSettings.initial();

    notifyListeners();
    return const Result<void>.ok(null);
  }

  Future<Result<void>> _saveProfile(ProfileData dati) async {
    _azzeraMessaggi();

    final nome = dati.nome.trim();
    if (nome.isEmpty) return _rifiuta('Scrivi il tuo nome.');

    final email = dati.email.trim();
    if (email.isEmpty) return _rifiuta('Scrivi la tua email.');
    if (!_emailValida(email)) {
      return _rifiuta('Questa email non sembra giusta. Controllala.');
    }

    // Il profilo esistente porta con sé la password e la data di creazione, che
    // questa schermata non tocca: senza copyWith andrebbero perse.
    final aggiornato = (_user ?? User(createdAt: DateTime.now())).copyWith(
      nome: nome,
      cognome: dati.cognome?.trim(),
      email: email,
      dataNascita: dati.dataNascita,
      genere: dati.genere,
    );

    final salvato = await _users.save(aggiornato);
    if (salvato case final Error<User> errore) {
      return _fallisce('Non riesco a salvare i tuoi dati.', errore.error);
    }

    _user = salvato.valueOrNull;
    _statusMessage = 'Dati salvati.';
    notifyListeners();
    return const Result<void>.ok(null);
  }

  Future<Result<void>> _changeAvatar() async {
    _azzeraMessaggi();

    // Un ospite non ha un profilo a cui attaccare l'immagine: salvandola si
    // creerebbe una riga utente senza nome, senza email e senza password, e da
    // lì in poi `hasUser()` risponderebbe che un profilo esiste. L'intestazione
    // tiene già il "+" spento; questa è la rete sotto, e tace come lui.
    if (_isGuest) return const Result<void>.ok(null);

    final percorso = await _avatar.pickFromGallery();
    // Galleria chiusa senza scegliere: non è un errore, semplicemente non
    // cambia niente.
    if (percorso == null) return const Result<void>.ok(null);

    final aggiornato = (_user ?? User(createdAt: DateTime.now())).copyWith(
      avatarPath: percorso,
    );

    final salvato = await _users.save(aggiornato);
    if (salvato case final Error<User> errore) {
      return _fallisce('Non riesco a salvare l\'immagine.', errore.error);
    }

    _user = salvato.valueOrNull;
    notifyListeners();
    return const Result<void>.ok(null);
  }

  Future<Result<void>> _changePassword(PasswordChange cambio) async {
    _azzeraMessaggi();

    final profilo = _user;
    if (profilo == null) {
      return _rifiuta('Non c\'è nessun profilo di cui cambiare la password.');
    }

    if (!PasswordHasher.matches(cambio.attuale, profilo.password)) {
      return _rifiuta('La password attuale non è corretta.');
    }

    final nonValida = PasswordHasher.validationError(cambio.nuova);
    if (nonValida != null) return _rifiuta(nonValida);

    if (cambio.nuova != cambio.conferma) {
      return _rifiuta('Le due password non coincidono. Riscrivile.');
    }

    final salvato = await _users.save(
      profilo.copyWith(password: PasswordHasher.hash(cambio.nuova)),
    );
    if (salvato case final Error<User> errore) {
      return _fallisce('Non riesco a salvare la password.', errore.error);
    }

    _user = salvato.valueOrNull;
    _statusMessage = 'Password aggiornata.';
    notifyListeners();
    return const Result<void>.ok(null);
  }

  Future<Result<void>> _setReminderEnabled(bool attivo) async {
    _azzeraMessaggi();

    // Il permesso si chiede solo accendendo: spegnere non ha bisogno di
    // nulla, e chiederlo di nuovo sarebbe una domanda senza senso.
    if (attivo) {
      final concesso = await _notifications.requestPermission();
      if (!concesso) {
        notifyListeners();
        return _rifiuta(
          'Per ricevere il promemoria devi permettere le notifiche a Vivo '
          'dalle impostazioni del telefono.',
        );
      }
      // Le sveglie al minuto sono un permesso a parte da Android 12. Si
      // chiede qui, insieme alle notifiche: se il telefono lo nega il
      // promemoria funziona lo stesso, ma può arrivare in ritardo, e lo dice
      // il messaggio di `_applicaPromemoria`.
      await _notifications.requestExactAlarmPermission();
    }

    return _applicaPromemoria(_reminder.copyWith(enabled: attivo));
  }

  Future<Result<void>> _setReminderTime(ReminderTime orario) async {
    _azzeraMessaggi();
    return _applicaPromemoria(
      _reminder.copyWith(hour: orario.hour, minute: orario.minute),
    );
  }

  Future<Result<void>> _applicaPromemoria(ReminderSettings impostazioni) async {
    final salvato = await _settings.saveReminder(impostazioni);
    if (salvato case final Error<void> errore) {
      return _fallisce(
        'Non riesco a salvare le impostazioni del promemoria.',
        errore.error,
      );
    }

    _reminder = impostazioni;
    final esatto = await _notifications.syncWith(impostazioni);
    // Il telefono può negare le sveglie esatte: il promemoria resta, ma non
    // arriva al minuto scelto, e vale la pena dirlo invece di lasciar credere
    // che l'orario sia rispettato.
    if (impostazioni.enabled && !esatto) {
      _statusMessage =
          'Il telefono non concede le sveglie esatte a Vivo: il promemoria '
          'può arrivare in ritardo.';
    }

    notifyListeners();
    return const Result<void>.ok(null);
  }

  Future<Result<void>> _logout() async {
    _azzeraMessaggi();
    return _settings.endSession();
  }

  Future<Result<void>> _delete() async {
    _azzeraMessaggi();

    // Prima il sistema, poi i dati: un promemoria programmato sopravviverebbe
    // all'account e continuerebbe a suonare per un'app ormai vuota.
    await _notifications.cancelDailyReminder();

    final cancellato = await _deleteAccount.deleteEverything();
    if (cancellato case final Error<void> errore) {
      return _fallisce(
        'Non riesco a cancellare tutti i dati. Riprova.',
        errore.error,
      );
    }

    _user = null;
    _reminder = const ReminderSettings.initial();
    notifyListeners();
    return const Result<void>.ok(null);
  }

  void _azzeraMessaggi() {
    _errorMessage = null;
    _statusMessage = null;
    _errorTone = MessageTone.notice;
  }

  /// Ferma l'operazione dicendo all'utente che cosa manca: è un'istruzione,
  /// non un guasto, quindi resta nel tono neutro.
  Result<void> _rifiuta(String messaggio) {
    _errorMessage = messaggio;
    _errorTone = MessageTone.notice;
    notifyListeners();
    return Result<void>.error(Exception(messaggio));
  }

  /// L'applicazione non è riuscita a fare il suo lavoro: tono da guasto.
  Result<void> _fallisce(String messaggio, Exception errore) {
    _errorMessage = messaggio;
    _errorTone = MessageTone.failure;
    notifyListeners();
    return Result<void>.error(errore);
  }

  /// Lo stesso controllo minimo della registrazione: qualcosa, una chiocciola,
  /// qualcosa con un punto.
  static bool _emailValida(String email) =>
      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
}
