import 'dart:math';

import 'package:flutter/foundation.dart';

/// Una stella del cielo notturno da comporre.
class Star {
  const Star({
    required this.x,
    required this.y,
    required this.size,
    required this.rotation,
    required this.lit,
  });

  final double x;

  final double y;

  final double size;

  final double rotation;

  final bool lit;

  Star get litUp => Star(
    x: x,
    y: y,
    size: size,
    rotation: rotation,
    lit: true,
  );
}

/// Lo stato dell'esercizio "Fai brillare le stelle".
///
/// È un esercizio di distrazione: toccare una stella alla volta sposta
/// l'attenzione dal respiro affannato a un gesto semplice e prevedibile.
/// L'esercizio finisce quando tutte brillano.
class StarsViewModel extends ChangeNotifier {
  StarsViewModel({int? seed, int count = 10}) {
    final caso = Random(seed ?? DateTime.now().millisecondsSinceEpoch);
    _stars = List<Star>.generate(count, (indice) {
      // Le stelle si distribuiscono su una griglia irregolare: così restano
      // sparse senza accavallarsi, ma non sembrano allineate.
      final riga = indice ~/ 2;
      final colonna = indice % 2;
      return Star(
        x: 0.12 + colonna * 0.42 + caso.nextDouble() * 0.28,
        y: 0.06 + riga * 0.18 + caso.nextDouble() * 0.08,
        size: 34 + caso.nextDouble() * 22,
        rotation: (caso.nextDouble() - 0.5) * 0.6,
        lit: false,
      );
    }, growable: false);
  }

  late final List<Star> _stars;

  List<Star> get stars => List<Star>.unmodifiable(_stars);

  int get litCount => _stars.where((s) => s.lit).length;

  bool get isComplete => litCount == _stars.length;

  /// Accende la stella in posizione [index].
  ///
  /// Toccare una stella già accesa non fa nulla: una volta accesa resta tale,
  /// così l'esercizio va sempre avanti e mai indietro.
  void light(int index) {
    if (index < 0 || index >= _stars.length) return;
    if (_stars[index].lit) return;

    _stars[index] = _stars[index].litUp;
    notifyListeners();
  }
}
