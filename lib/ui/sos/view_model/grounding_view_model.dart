import 'package:flutter/foundation.dart';

/// I cinque sensi dell'esercizio 5-4-3-2-1, nell'ordine in cui si percorrono.
enum GroundingSense {
  see(
    5,
    '5 cose che vedi',
    'Iniziamo. Prova a individuare e nominare cinque cose che vedi in questo '
        'momento.',
  ),
  touch(
    4,
    '4 cose che tocchi',
    'Bene. Ora prova a individuare e nominare quattro cose che stai toccando '
        'in questo momento.',
  ),
  hear(
    3,
    '3 cose che senti',
    'Continua così. Adesso concentrati sui suoni intorno a te e prova a '
        'riconoscerne tre.',
  ),
  smell(
    2,
    '2 cose che odori',
    'Ci sei quasi. Fai un bel respiro e prova a riconoscere due odori.',
  ),
  taste(
    1,
    '1 cosa che gusti',
    'L\'ultimo passo. Nomina un sapore che senti adesso, anche solo quello '
        'della tua bocca.',
  );

  const GroundingSense(this.count, this.title, this.guidance);

  final int count;

  final String title;

  final String guidance;
}

/// Lo stato dell'esercizio di grounding 5-4-3-2-1.
///
/// L'utente non scrive nulla: nomina le cose a mente e tocca per proseguire,
/// perché durante un attacco d'ansia scrivere è faticoso.
class GroundingViewModel extends ChangeNotifier {
  int _indice = 0;

  GroundingSense get current =>
      GroundingSense.values[_indice.clamp(0, GroundingSense.values.length - 1)];

  List<GroundingSense> get completed =>
      GroundingSense.values.take(_indice).toList(growable: false);

  bool get isLastStep => _indice == GroundingSense.values.length - 1;

  bool get isComplete => _indice >= GroundingSense.values.length;

  void next() {
    if (isComplete) return;
    _indice++;
    notifyListeners();
  }
}
