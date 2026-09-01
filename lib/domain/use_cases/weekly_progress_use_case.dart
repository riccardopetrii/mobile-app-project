import '../../data/repositories/help_request_repository.dart';
import '../../utils/dates.dart';
import '../../utils/result.dart';

/// I numeri mostrati nella card "I tuoi progressi" della home.
class WeeklyProgress {
  const WeeklyProgress({
    required this.currentWeek,
    required this.previousWeek,
  });

  final int currentWeek;

  final int previousWeek;

  /// La variazione percentuale rispetto alla settimana precedente.
  int? get changePercent {
    if (previousWeek == 0) return null;
    return (((currentWeek - previousWeek) / previousWeek) * 100).truncate();
  }

  bool get isImproving => currentWeek < previousWeek;

  @override
  String toString() =>
      'WeeklyProgress(corrente: $currentWeek, precedente: $previousWeek)';
}

/// Calcola quante volte è stato usato il pulsante di aiuto nelle ultime due
/// settimane, per la card dei progressi.
class WeeklyProgressUseCase {
  WeeklyProgressUseCase(this._requests);

  final HelpRequestRepository _requests;

  /// I progressi alla data indicata, prendendo la settimana da lunedì a
  /// domenica.
  Future<Result<WeeklyProgress>> progressAt(DateTime date) async {
    final inizioCorrente = startOfWeek(date);
    final fineCorrente = inizioCorrente.add(const Duration(days: 6));
    final inizioPrecedente = inizioCorrente.subtract(const Duration(days: 7));
    final finePrecedente = inizioCorrente.subtract(const Duration(days: 1));

    final corrente = await _requests.countBetween(inizioCorrente, fineCorrente);
    if (corrente case final Error<int> errore) {
      return Result<WeeklyProgress>.error(errore.error);
    }

    final precedente = await _requests.countBetween(
      inizioPrecedente,
      finePrecedente,
    );
    if (precedente case final Error<int> errore) {
      return Result<WeeklyProgress>.error(errore.error);
    }

    return Result<WeeklyProgress>.ok(
      WeeklyProgress(
        currentWeek: corrente.valueOrNull!,
        previousWeek: precedente.valueOrNull!,
      ),
    );
  }
}
