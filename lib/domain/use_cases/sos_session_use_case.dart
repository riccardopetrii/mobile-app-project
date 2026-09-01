import '../../data/repositories/help_request_repository.dart';
import '../../utils/result.dart';
import '../models/help_request.dart';

/// I tre esercizi della sessione di aiuto, nell'ordine in cui si susseguono.
///
/// Sono anche i tre pallini dell'indicatore in cima alle schermate: la
/// posizione di ciascun passo corrisponde al pallino acceso.
enum SosStep {
  breathing('Respirazione guidata', 'utilizzando la tecnica 4-4-4-4'),
  stars('Fai brillare le stelle', 'per comporre il tuo cielo notturno'),
  grounding('Grounding 5-4-3-2-1', 'concentrati su ciò che ti circonda…');

  const SosStep(this.title, this.subtitle);

  final String title;

  final String subtitle;

  SosStep? get next =>
      index + 1 < SosStep.values.length ? SosStep.values[index + 1] : null;

  static int get count => SosStep.values.length;
}

/// Conclude una sessione di aiuto salvando quanto raccolto dal questionario
/// finale.
class SosSessionUseCase {
  SosSessionUseCase(this._requests);

  final HelpRequestRepository _requests;

  /// Salva la sessione conclusa.
  ///
  /// Un'intensità fuori dalla scala 0-10 non viene scritta: il modello la
  /// rifiuta e l'errore risale a chi ha chiamato, senza lasciare righe
  /// incoerenti nel diario.
  Future<Result<HelpRequest>> complete({
    required int intensity,
    HelpTrigger? trigger,
    required HelpOutcome outcome,
    DateTime? completedAt,
  }) async {
    final HelpRequest richiesta;
    try {
      richiesta = HelpRequest(
        completedAt: completedAt ?? DateTime.now(),
        intensity: intensity,
        trigger: trigger,
        outcome: outcome,
      );
    } on ArgumentError catch (errore) {
      return Result<HelpRequest>.error(
        Exception('intensità non valida: ${errore.message}'),
      );
    }

    return _requests.add(richiesta);
  }
}
