import 'package:shared_preferences/shared_preferences.dart';

/// Legge e scrive le preferenze dell'applicazione.
///
/// Qui stanno solo lo stato della sessione e le impostazioni: i contenuti creati
/// dall'utente (umore, diario, richieste di aiuto, profilo) vivono nel database
/// SQLite.
class PreferencesService {
  static const String _keyLoggedIn = 'is_logged_in';
  static const String _keyGuest = 'is_guest';
  static const String _keyReminderEnabled = 'reminder_enabled';
  static const String _keyReminderTime = 'reminder_time';

  static const String defaultReminderTime = '20:00';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  /// Vero se esiste una sessione aperta, con profilo o come ospite.
  Future<bool> isLoggedIn() async =>
      (await _prefs).getBool(_keyLoggedIn) ?? false;

  /// Registra l'apertura o la chiusura della sessione.
  Future<void> setLoggedIn(bool value) async =>
      (await _prefs).setBool(_keyLoggedIn, value);

  /// Vero se la sessione corrente è stata aperta come ospite.
  Future<bool> isGuest() async => (await _prefs).getBool(_keyGuest) ?? false;

  /// Registra se la sessione corrente è quella di un ospite.
  Future<void> setGuest(bool value) async =>
      (await _prefs).setBool(_keyGuest, value);

  /// Chiude la sessione senza toccare le impostazioni.
  Future<void> clearSession() async {
    final prefs = await _prefs;
    await prefs.remove(_keyLoggedIn);
    await prefs.remove(_keyGuest);
  }

  /// Vero se il promemoria giornaliero è attivo.
  Future<bool> isReminderEnabled() async =>
      (await _prefs).getBool(_keyReminderEnabled) ?? false;

  /// Attiva o disattiva il promemoria giornaliero.
  Future<void> setReminderEnabled(bool value) async =>
      (await _prefs).setBool(_keyReminderEnabled, value);

  /// Orario del promemoria giornaliero, nel formato `HH:mm`.
  Future<String> reminderTime() async =>
      (await _prefs).getString(_keyReminderTime) ?? defaultReminderTime;

  /// Imposta l'orario del promemoria giornaliero, nel formato `HH:mm`.
  Future<void> setReminderTime(String value) async =>
      (await _prefs).setString(_keyReminderTime, value);

  /// Cancella ogni preferenza, usato dall'eliminazione dell'account.
  Future<void> clearAll() async => (await _prefs).clear();
}
