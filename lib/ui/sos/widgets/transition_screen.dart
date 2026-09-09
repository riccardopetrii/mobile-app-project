import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/themes/colors.dart';
import '../../core/themes/dimens.dart';

/// La schermata di passaggio che apre la sessione di aiuto.
///
/// Non chiede nulla: dà solo il tempo di leggere una frase e di respirare una
/// volta prima di cominciare. Prosegue da sola, ma un tocco la salta, perché
/// chi sta male non deve aspettare.
class TransitionScreen extends StatefulWidget {
  const TransitionScreen({required this.onDone, super.key});

  /// Quanto resta sullo schermo prima di proseguire da sola.
  static const Duration duration = Duration(milliseconds: 3500);

  final VoidCallback onDone;

  @override
  State<TransitionScreen> createState() => _TransitionScreenState();
}

class _TransitionScreenState extends State<TransitionScreen> {
  Timer? _timer;
  bool _concluso = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer(TransitionScreen.duration, _prosegui);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _prosegui() {
    if (_concluso) return;
    _concluso = true;
    _timer?.cancel();
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: GestureDetector(
      onTap: _prosegui,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: CustomPaint(painter: const _SegniAManoPainter()),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: VivoDimens.xl),
              child: Text(
                'Ok, vediamo insieme come posso aiutarti. Sono qui per te. '
                'Cominciamo…',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  height: 1.45,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

/// I segni disegnati a mano che attraversano lo sfondo.
class _SegniAManoPainter extends CustomPainter {
  const _SegniAManoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final teal = Paint()
      ..color = VivoColors.header.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;

    final rosa = Paint()
      ..color = VivoColors.accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;

    // Due gruppi di curve, uno in alto e uno in basso, così il testo al centro
    // resta su uno sfondo pulito.
    canvas.drawPath(
      Path()
        ..moveTo(-w * 0.06, h * 0.16)
        ..cubicTo(w * 0.2, h * 0.03, w * 0.45, h * 0.3, w * 0.36, h * 0.36)
        ..cubicTo(w * 0.27, h * 0.42, w * 0.02, h * 0.3, w * 0.24, h * 0.2)
        ..cubicTo(w * 0.6, h * 0.04, w * 0.92, h * 0.12, w * 1.04, h * 0.28),
      teal,
    );
    canvas.drawPath(
      Path()
        ..moveTo(w * 1.05, h * 0.26)
        ..cubicTo(w * 0.8, h * 0.36, w * 0.86, h * 0.5, w * 0.6, h * 0.56)
        ..cubicTo(w * 0.36, h * 0.62, w * 0.16, h * 0.46, -w * 0.05, h * 0.6),
      teal,
    );
    canvas.drawPath(
      Path()
        ..moveTo(-w * 0.04, h * 0.76)
        ..cubicTo(w * 0.24, h * 0.66, w * 0.4, h * 0.84, w * 0.62, h * 0.79)
        ..cubicTo(w * 0.8, h * 0.75, w * 0.78, h * 0.62, w * 1.02, h * 0.68),
      rosa,
    );
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.1, h * 0.94)
        ..cubicTo(w * 0.3, h * 0.82, w * 0.6, h * 0.96, w * 1.0, h * 0.86),
      rosa,
    );
  }

  @override
  bool shouldRepaint(_SegniAManoPainter oldDelegate) => false;
}
