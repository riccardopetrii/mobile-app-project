import 'package:flutter/foundation.dart';

/// Le quattro fasi della tecnica 4-4-4-4.
enum BreathPhase {
  inhale('Ora inspira…'),
  holdIn('Trattieni il respiro…'),
  exhale('Ok, ora espira…'),
  holdOut('Trattieni…');

  const BreathPhase(this.label);

  final String label;

  Duration get duration => const Duration(seconds: 4);

  /// Vero nelle due fasi in cui il respiro si trattiene.
  ///
  /// Sono le uniche in cui "Salta Pausa" ha senso: interrompere un'inspirazione
  /// a metà non aiuterebbe nessuno.
  bool get isHold => this == BreathPhase.holdIn || this == BreathPhase.holdOut;
}

/// Lo stato dell'esercizio di respirazione guidata.
class BreathingViewModel extends ChangeNotifier {
  BreathingViewModel({this.totalCycles = 11});

  /// Quanti cicli completi compongono l'esercizio.
  ///
  /// Undici cicli da sedici secondi fanno poco meno di tre minuti, la durata
  /// indicata nella card delle attività consigliate.
  final int totalCycles;

  Duration _tempoScorso = Duration.zero;

  /// Il tempo guadagnato saltando le pause.
  ///
  /// Va tenuto da parte perché la schermata comunica il tempo assoluto misurato
  /// dall'inizio: senza questa somma, il primo fotogramma dopo un salto lo
  /// riscriverebbe da capo e il salto sparirebbe.
  Duration _tempoSaltato = Duration.zero;

  Duration get _elapsed => _tempoScorso + _tempoSaltato;

  /// Quanto dura un ciclo intero.
  static const Duration cycleDuration = Duration(seconds: 16);

  Duration get totalDuration => cycleDuration * totalCycles;

  Duration get elapsed => _elapsed;

  Duration get remaining {
    final rimasto = totalDuration - _elapsed;
    return rimasto.isNegative ? Duration.zero : rimasto;
  }

  bool get isFinished => _elapsed >= totalDuration;

  int get completedCycles =>
      (_elapsed.inMilliseconds ~/ cycleDuration.inMilliseconds).clamp(
        0,
        totalCycles,
      );

  BreathPhase get phase {
    final dentroAlCiclo =
        _elapsed.inMilliseconds % cycleDuration.inMilliseconds;
    final indice =
        dentroAlCiclo ~/ BreathPhase.inhale.duration.inMilliseconds;
    return BreathPhase.values[indice.clamp(0, BreathPhase.values.length - 1)];
  }

  /// A che punto è la fase corrente, da 0 a 1: è il valore che muove il
  /// cerchio.
  double get phaseProgress {
    final durata = phase.duration.inMilliseconds;
    final dentroAllaFase = _elapsed.inMilliseconds % durata;
    return dentroAllaFase / durata;
  }

  bool get canSkipHold => phase.isHold && !isFinished;

  /// Fa passare il tempo di [delta].
  void tick(Duration delta) => setElapsed(_tempoScorso + delta);

  /// Comunica il tempo trascorso dall'inizio, misurato da chi fa scorrere
  /// l'esercizio.
  void setElapsed(Duration value) {
    if (isFinished) return;
    _tempoScorso = value;
    notifyListeners();
  }

  /// Salta il resto della pausa e passa alla fase successiva.
  ///
  /// Non fa nulla mentre si sta inspirando o espirando.
  void skipHold() {
    if (!canSkipHold) return;
    final durata = phase.duration.inMilliseconds;
    final dentroAllaFase = _elapsed.inMilliseconds % durata;
    _tempoSaltato += Duration(milliseconds: durata - dentroAllaFase);
    notifyListeners();
  }

  void reset() {
    _tempoScorso = Duration.zero;
    _tempoSaltato = Duration.zero;
    notifyListeners();
  }
}
