import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../domain/models/mood_entry.dart';

/// Disegna la faccina di un livello d'umore.
class MoodFace extends StatelessWidget {
  const MoodFace({required this.mood, required this.color, this.size = 32, super.key});

  final Mood mood;

  final Color color;

  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: CustomPaint(painter: _MoodFacePainter(mood: mood, color: color)),
  );
}

class _MoodFacePainter extends CustomPainter {
  const _MoodFacePainter({required this.mood, required this.color});

  final Mood mood;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final lato = size.shortestSide;
    final centro = Offset(size.width / 2, size.height / 2);
    final tratto = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = lato * 0.055
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(centro, lato * 0.42, tratto);

    final occhioY = centro.dy - lato * 0.09;
    final occhioX = lato * 0.155;
    _occhio(canvas, tratto, Offset(centro.dx - occhioX, occhioY), lato);
    _occhio(canvas, tratto, Offset(centro.dx + occhioX, occhioY), lato);

    _bocca(canvas, tratto, centro, lato);
  }

  /// Gli occhi: due archi rivolti verso l'alto agli estremi della scala, due
  /// punti pieni nei livelli intermedi.
  void _occhio(Canvas canvas, Paint tratto, Offset centro, double lato) {
    final raggio = lato * 0.075;
    switch (mood) {
      case Mood.triste:
        canvas.drawArc(
          Rect.fromCircle(center: centro, radius: raggio),
          math.pi,
          math.pi,
          false,
          tratto,
        );
      case Mood.felice:
        canvas.drawArc(
          Rect.fromCircle(center: centro, radius: raggio),
          math.pi,
          math.pi,
          false,
          tratto,
        );
      case Mood.pocoBene || Mood.cosiCosi || Mood.bene:
        canvas.drawCircle(
          centro,
          raggio * 0.55,
          Paint()
            ..color = color
            ..style = PaintingStyle.fill,
        );
    }
  }

  /// La bocca: una curva la cui apertura passa dal broncio al sorriso.
  void _bocca(Canvas canvas, Paint tratto, Offset centro, double lato) {
    final larghezza = lato * 0.34;
    final y = centro.dy + lato * 0.16;
    final sinistra = Offset(centro.dx - larghezza / 2, y);
    final destra = Offset(centro.dx + larghezza / 2, y);

    // Da -1 (broncio) a +1 (sorriso), passando per 0 (bocca dritta).
    final curvatura = switch (mood) {
      Mood.triste => -1.0,
      Mood.pocoBene => -0.5,
      Mood.cosiCosi => 0.0,
      Mood.bene => 0.6,
      Mood.felice => 1.0,
    };

    if (curvatura == 0) {
      canvas.drawLine(sinistra, destra, tratto);
      return;
    }

    final controllo = Offset(centro.dx, y + curvatura * lato * 0.2);
    final percorso = Path()
      ..moveTo(sinistra.dx, sinistra.dy)
      ..quadraticBezierTo(controllo.dx, controllo.dy, destra.dx, destra.dy);

    if (mood == Mood.felice) {
      // Il sorriso più aperto è pieno, come nel wireframe.
      canvas.drawPath(
        percorso..close(),
        Paint()
          ..color = color
          ..style = PaintingStyle.fill,
      );
    }
    canvas.drawPath(percorso, tratto);
  }

  @override
  bool shouldRepaint(_MoodFacePainter oldDelegate) =>
      oldDelegate.mood != mood || oldDelegate.color != color;
}
