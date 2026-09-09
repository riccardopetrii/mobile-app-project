import 'package:flutter/foundation.dart';

import '../../../domain/use_cases/sos_session_use_case.dart';

/// I momenti che compongono una sessione di aiuto.
enum SosStage {
  transition,

  exercise,

  questionnaire,

  done,
}

/// Tiene il segno di dove si trova la sessione di aiuto.
///
/// Esiste in due forme: la sessione intera, che parte dalla transizione e
/// percorre i tre esercizi prima del questionario, e il singolo esercizio
/// avviato dalle attività consigliate della home, che finisce da solo.
class SosFlowViewModel extends ChangeNotifier {
  /// La sessione completa, avviata dal pulsante "Ho bisogno di aiuto".
  SosFlowViewModel() : _single = null, _stage = SosStage.transition;

  /// Un solo esercizio, avviato dalle attività consigliate.
  SosFlowViewModel.singleExercise(SosStep exercise)
    : _single = exercise,
      _stage = SosStage.exercise,
      _step = exercise;

  final SosStep? _single;

  SosStage _stage;
  SosStep? _step;

  SosStage get stage => _stage;

  SosStep? get step => _step;

  /// Vero quando va mostrato l'indicatore a tre pallini.
  ///
  /// Un esercizio singolo non fa parte di una sequenza, quindi i pallini
  /// racconterebbero un avanzamento che non esiste.
  bool get showsProgress => _single == null;

  /// Vero quando è stato aperto un esercizio solo, dalle attività consigliate
  /// della home, invece della sessione di aiuto intera.
  bool get isSingleExercise => _single != null;

  void next() {
    switch (_stage) {
      case SosStage.transition:
        _stage = SosStage.exercise;
        _step = SosStep.breathing;
      case SosStage.exercise:
        final successivo = _single != null ? null : _step?.next;
        if (successivo != null) {
          _step = successivo;
        } else {
          _step = null;
          _stage = _single != null
              ? SosStage.done
              : SosStage.questionnaire;
        }
      case SosStage.questionnaire:
        _stage = SosStage.done;
      case SosStage.done:
        return;
    }
    notifyListeners();
  }

  /// Ricomincia dalla respirazione, saltando la transizione.
  ///
  /// Serve al bottone "Avvia un'altra sessione" del questionario: chi lo tocca
  /// ha già letto la frase di accoglienza.
  void restart() {
    _stage = SosStage.exercise;
    _step = SosStep.breathing;
    notifyListeners();
  }
}
