import '../../domain/models/reminder_settings.dart';
import '../../utils/result.dart';
import '../services/preferences_service.dart';
import 'storage_exception.dart';

/// Accesso allo stato della sessione e alle impostazioni dell'applicazione.
abstract interface class SettingsRepository {
  /// Vero se esiste una sessione aperta, con profilo o come ospite.
  Future<Result<bool>> isLoggedIn();

  /// Vero se la sessione corrente è stata aperta come ospite.
  Future<Result<bool>> isGuest();

  /// Apre una sessione, indicando se si tratta di un ospite.
  Future<Result<void>> startSession({required bool guest});

  /// Chiude la sessione lasciando intatte le impostazioni.
  Future<Result<void>> endSession();

  /// Le impostazioni del promemoria giornaliero.
  Future<Result<ReminderSettings>> reminder();

  /// Salva le impostazioni del promemoria giornaliero.
  Future<Result<void>> saveReminder(ReminderSettings settings);

  /// Cancella ogni preferenza, usato dall'eliminazione dell'account.
  Future<Result<void>> clearAll();
}

/// Implementazione di [SettingsRepository] sulle preferenze locali.
class LocalSettingsRepository implements SettingsRepository {
  LocalSettingsRepository(this._preferences);

  final PreferencesService _preferences;

  @override
  Future<Result<bool>> isLoggedIn() =>
      _guard(() => _preferences.isLoggedIn());

  @override
  Future<Result<bool>> isGuest() => _guard(() => _preferences.isGuest());

  @override
  Future<Result<void>> startSession({required bool guest}) => _guard(() async {
    await _preferences.setLoggedIn(true);
    await _preferences.setGuest(guest);
  });

  @override
  Future<Result<void>> endSession() =>
      _guard(() => _preferences.clearSession());

  @override
  Future<Result<ReminderSettings>> reminder() => _guard(() async {
    final enabled = await _preferences.isReminderEnabled();
    final time = await _preferences.reminderTime();
    return ReminderSettings.fromTime(enabled: enabled, time: time);
  });

  @override
  Future<Result<void>> saveReminder(ReminderSettings settings) =>
      _guard(() async {
        await _preferences.setReminderEnabled(settings.enabled);
        await _preferences.setReminderTime(settings.formattedTime);
      });

  @override
  Future<Result<void>> clearAll() => _guard(() => _preferences.clearAll());

  Future<Result<T>> _guard<T>(Future<T> Function() azione) async {
    try {
      return Result<T>.ok(await azione());
    } on Object catch (error) {
      return Result<T>.error(asStorageException(error));
    }
  }
}
