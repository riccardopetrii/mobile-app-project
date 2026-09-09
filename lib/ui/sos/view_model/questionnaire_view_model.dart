import 'package:flutter/foundation.dart';

import '../../../domain/models/help_request.dart';
import '../../../domain/use_cases/sos_session_use_case.dart';
import '../../../utils/command.dart';
import '../../../utils/result.dart';
import '../../core/ui/vivo_message.dart';

/// Lo stato del questionario finale.
///
/// Raccoglie le tre risposte - quanto è stato intenso l'attacco, che cosa lo ha
/// scatenato e come si sente adesso l'utente - e le salva come sessione
/// conclusa.
class QuestionnaireViewModel extends ChangeNotifier {
  QuestionnaireViewModel({
    required SosSessionUseCase session,
    DateTime Function()? now,
  }) : _session = session,
       _now = now ?? DateTime.now {
    save = Command0<void>(_save);
  }

  /// Il valore da cui parte lo slider: metà scala, senza suggerire una
  /// risposta.
  static const int initialIntensity = 5;

  final SosSessionUseCase _session;
  final DateTime Function() _now;

  late final Command0<void> save;

  int _intensity = initialIntensity;
  HelpTrigger? _trigger;
  HelpOutcome? _outcome;
  String? _errorMessage;
  MessageTone _errorTone = MessageTone.notice;

  int get intensity => _intensity;

  HelpTrigger? get trigger => _trigger;

  HelpOutcome? get outcome => _outcome;

  String? get errorMessage => _errorMessage;

  /// Il tono con cui va mostrato [errorMessage].
  ///
  /// Un guasto dell'applicazione e un'istruzione all'utente non si mostrano
  /// uguali: vedi `MessageTone`.
  MessageTone get errorTone => _errorTone;

  bool get canSave => _outcome != null;

  /// Sposta lo slider, restando dentro la scala.
  void setIntensity(int valore) {
    _intensity = valore.clamp(
      HelpRequest.minIntensity,
      HelpRequest.maxIntensity,
    );
    notifyListeners();
  }

  /// Sceglie un trigger, oppure lo annulla se era già scelto.
  void selectTrigger(HelpTrigger scelto) {
    _trigger = _trigger == scelto ? null : scelto;
    notifyListeners();
  }

  /// Sceglie come si sente l'utente adesso.
  void selectOutcome(HelpOutcome scelto) {
    _outcome = scelto;
    notifyListeners();
  }

  /// Ripulisce le risposte per avviare un'altra sessione.
  void reset() {
    _intensity = initialIntensity;
    _trigger = null;
    _outcome = null;
    _errorMessage = null;
    save.clearResult();
    notifyListeners();
  }

  Future<Result<void>> _save() async {
    _errorMessage = null;
    _errorTone = MessageTone.notice;

    final esito = _outcome;
    if (esito == null) {
      _errorMessage = 'Dimmi come ti senti adesso prima di uscire.';
      return Result<void>.error(Exception('esito non scelto'));
    }

    final salvata = await _session.complete(
      intensity: _intensity,
      trigger: _trigger,
      outcome: esito,
      completedAt: _now(),
    );

    if (salvata case final Error<HelpRequest> errore) {
      _errorMessage = 'Impossibile salvare la sessione. Riprova.';
      _errorTone = MessageTone.failure;
      return Result<void>.error(errore.error);
    }

    return const Result<void>.ok(null);
  }
}
