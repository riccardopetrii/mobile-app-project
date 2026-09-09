import '../../data/repositories/diary_repository.dart';
import '../../data/repositories/help_request_repository.dart';
import '../../data/repositories/mood_repository.dart';
import '../../data/repositories/settings_repository.dart';
import '../../data/repositories/user_repository.dart';
import '../../utils/result.dart';

/// Cancella dal dispositivo ogni traccia dell'utente.
///
/// È l'azione dietro il bottone "Elimina Account" del profilo. Tocca tutti i
/// repository perché i dati sono divisi fra il database e le preferenze: qui
/// sta l'unico punto che conosce l'elenco completo.
class DeleteAccountUseCase {
  DeleteAccountUseCase({
    required UserRepository users,
    required MoodRepository moods,
    required DiaryRepository diary,
    required HelpRequestRepository requests,
    required SettingsRepository settings,
  }) : _users = users,
       _moods = moods,
       _diary = diary,
       _requests = requests,
       _settings = settings;

  final UserRepository _users;
  final MoodRepository _moods;
  final DiaryRepository _diary;
  final HelpRequestRepository _requests;
  final SettingsRepository _settings;

  /// Cancella profilo, umori, riflessioni, richieste di aiuto e preferenze.
  ///
  /// Se una cancellazione fallisce le altre vengono comunque tentate, per non
  /// lasciare il dispositivo in uno stato a metà, e il primo errore incontrato
  /// viene restituito.
  Future<Result<void>> deleteEverything() async {
    Exception? primoErrore;

    for (final cancella in <Future<Result<void>> Function()>[
      _users.deleteAll,
      _moods.deleteAll,
      _diary.deleteAll,
      _requests.deleteAll,
      _settings.clearAll,
    ]) {
      final result = await cancella();
      if (result case final Error<void> errore) {
        primoErrore ??= errore.error;
      }
    }

    if (primoErrore != null) return Result<void>.error(primoErrore);
    return const Result<void>.ok(null);
  }
}
