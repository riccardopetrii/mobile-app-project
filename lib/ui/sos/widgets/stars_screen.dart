import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../domain/use_cases/sos_session_use_case.dart';
import '../../core/themes/colors.dart';
import '../../core/themes/dimens.dart';
import '../view_model/stars_view_model.dart';
import 'sos_header.dart';

/// L'esercizio delle stelle, come in `wireframes/task-2.png`.
class StarsScreen extends StatelessWidget {
  const StarsScreen({
    required this.viewModel,
    required this.showsProgress,
    required this.onNext,
    required this.onExit,
    super.key,
  });

  final StarsViewModel viewModel;

  final bool showsProgress;

  final VoidCallback onNext;

  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      top: false,
      child: Column(
        children: <Widget>[
          SosHeader(
            step: SosStep.stars,
            showsProgress: showsProgress,
            onExit: onExit,
          ),
          Expanded(
            child: ListenableBuilder(
              listenable: viewModel,
              builder: (context, _) => LayoutBuilder(
                builder: (context, vincoli) => Stack(
                  children: <Widget>[
                    for (var i = 0; i < viewModel.stars.length; i++)
                      Positioned(
                        left: viewModel.stars[i].x * vincoli.maxWidth,
                        top: viewModel.stars[i].y * vincoli.maxHeight,
                        child: StarWidget(
                          star: viewModel.stars[i],
                          index: i,
                          onTap: () => viewModel.light(i),
                        ),
                      ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Center(
                        child: Text(
                          '${viewModel.litCount} di '
                          '${viewModel.stars.length}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                fontFeatures: const <FontFeature>[
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SosBottomBar(
            label: 'Prossimo Passo',
            onPressed: onNext,
            infoTitle: 'Perché accendere le stelle',
            infoBody:
                'Toccare una stella alla volta sposta l\'attenzione dal '
                'respiro affannato a un gesto semplice e prevedibile. Non '
                'devi accenderle tutte: puoi proseguire quando vuoi.',
          ),
        ],
      ),
    ),
  );
}

/// Una stella toccabile.
class StarWidget extends StatelessWidget {
  const StarWidget({
    required this.star,
    required this.index,
    required this.onTap,
    super.key,
  });

  final Star star;

  final int index;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: star.lit
        ? 'Stella ${index + 1}, accesa'
        : 'Stella ${index + 1}, da accendere',
    child: GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: star.lit ? 1.1 : 1,
        duration: const Duration(milliseconds: 220),
        child: Padding(
          // Lo spazio attorno allarga l'area toccabile senza allargare il
          // disegno: durante un attacco d'ansia le mani non sono precise.
          padding: const EdgeInsets.all(VivoDimens.sm),
          child: Transform.rotate(
            angle: star.rotation,
            child: CustomPaint(
              size: Size.square(star.size),
              painter: _StellaPainter(lit: star.lit),
            ),
          ),
        ),
      ),
    ),
  );
}

class _StellaPainter extends CustomPainter {
  const _StellaPainter({required this.lit});

  final bool lit;

  @override
  void paint(Canvas canvas, Size size) {
    final centro = size.center(Offset.zero);
    final raggioEsterno = size.width / 2;
    final raggioInterno = raggioEsterno * 0.42;

    final percorso = Path();
    for (var i = 0; i < 10; i++) {
      final raggio = i.isEven ? raggioEsterno : raggioInterno;
      final angolo = -math.pi / 2 + i * math.pi / 5;
      final punto = Offset(
        centro.dx + raggio * math.cos(angolo),
        centro.dy + raggio * math.sin(angolo),
      );
      i == 0
          ? percorso.moveTo(punto.dx, punto.dy)
          : percorso.lineTo(punto.dx, punto.dy);
    }
    percorso.close();

    canvas.drawPath(
      percorso,
      Paint()
        ..color = lit ? VivoColors.accent : VivoColors.field
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      percorso,
      Paint()
        ..color = lit
            ? VivoColors.onAccent.withValues(alpha: 0.55)
            : VivoColors.muted.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_StellaPainter oldDelegate) => oldDelegate.lit != lit;
}
