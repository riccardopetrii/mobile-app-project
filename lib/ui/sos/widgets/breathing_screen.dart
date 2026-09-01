import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../domain/use_cases/sos_session_use_case.dart';
import '../../core/themes/colors.dart';
import '../../core/themes/dimens.dart';
import '../view_model/breathing_view_model.dart';
import 'sos_header.dart';

/// L'esercizio di respirazione guidata, come in `wireframes/task-1.png`.
class BreathingScreen extends StatefulWidget {
  const BreathingScreen({
    required this.viewModel,
    required this.showsProgress,
    required this.onNext,
    required this.onExit,
    super.key,
  });

  final BreathingViewModel viewModel;

  final bool showsProgress;

  final VoidCallback onNext;

  final VoidCallback onExit;

  @override
  State<BreathingScreen> createState() => _BreathingScreenState();
}

class _BreathingScreenState extends State<BreathingScreen>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;

  @override
  void initState() {
    super.initState();
    // Il ticker scatta una volta per fotogramma, al ritmo dello schermo: su un
    // pannello a 120 Hz l'arco si muove il doppio più fitto di quanto potrebbe
    // fare un timer a intervallo fisso, e senza fotogrammi fuori tempo.
    _ticker = createTicker((trascorso) {
      widget.viewModel.setElapsed(trascorso);
      if (widget.viewModel.isFinished) _ticker.stop();
    })..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  /// Il tempo rimasto scritto come "2:06".
  String _tempo(Duration rimasto) {
    final minuti = rimasto.inMinutes;
    final secondi = rimasto.inSeconds % 60;
    return '$minuti:${secondi.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final testi = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        top: false,
        child: Column(
          children: <Widget>[
            SosHeader(
              step: SosStep.breathing,
              showsProgress: widget.showsProgress,
              onExit: widget.onExit,
            ),
            Expanded(
              child: ListenableBuilder(
                listenable: widget.viewModel,
                builder: (context, _) {
                  final vm = widget.viewModel;
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        _tempo(vm.remaining),
                        style: testi.titleLarge?.copyWith(
                          fontFeatures: const <FontFeature>[
                            FontFeature.tabularFigures(),
                          ],
                        ),
                      ),
                      const SizedBox(height: VivoDimens.xl),
                      BreathingCircle(
                        phase: vm.phase,
                        progress: vm.phaseProgress,
                      ),
                      const SizedBox(height: VivoDimens.xl),
                      OutlinedButton(
                        onPressed: vm.canSkipHold ? vm.skipHold : null,
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Text('Salta Pausa'),
                            SizedBox(width: VivoDimens.sm),
                            Icon(Icons.skip_next_rounded, size: 18),
                          ],
                        ),
                      ),
                      const SizedBox(height: VivoDimens.sm),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: VivoDimens.xl,
                        ),
                        child: Text(
                          '*Il pulsante si attiverà nelle fasi di '
                          'mantenimento.',
                          textAlign: TextAlign.center,
                          style: testi.bodySmall?.copyWith(fontSize: 11),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            SosBottomBar(
              label: 'Prossimo Passo',
              onPressed: widget.onNext,
              infoTitle: 'Respirazione 4-4-4-4',
              infoBody:
                  'Inspira per quattro secondi, trattieni per quattro, espira '
                  'per quattro e trattieni ancora per quattro. Allungare '
                  'l\'espirazione rallenta il battito e dice al corpo che il '
                  'pericolo è passato. Segui il cerchio: si allarga mentre '
                  'inspiri e si stringe mentre espiri.',
            ),
          ],
        ),
      ),
    );
  }
}

/// Il cerchio che accompagna il respiro.
///
/// Si allarga inspirando, resta fermo mentre si trattiene e si stringe
/// espirando: il movimento dà il ritmo senza bisogno di contare.
class BreathingCircle extends StatelessWidget {
  const BreathingCircle({
    required this.phase,
    required this.progress,
    super.key,
  });

  static const double size = 280;

  /// Il raggio più stretto, alla fine dell'espirazione.
  ///
  /// Non scende oltre perché il cerchio deve restare largo abbastanza da
  /// contenere l'istruzione senza sfiorarla: una frase che tocca il bordo
  /// mentre si sta male dà un senso di soffocamento.
  static const double minRadius = size * 0.4;

  static const double maxRadius = size * 0.46;

  static const double textInset = 46;

  final BreathPhase phase;

  final double progress;

  @override
  Widget build(BuildContext context) {
    // Da 0 (stretto) a 1 (largo), secondo la fase.
    final apertura = switch (phase) {
      BreathPhase.inhale => progress,
      BreathPhase.holdIn => 1.0,
      BreathPhase.exhale => 1 - progress,
      BreathPhase.holdOut => 0.0,
    };

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          CustomPaint(
            size: const Size.square(size),
            painter: _AnelloPainter(apertura: apertura, phase: phase),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(Icons.air_rounded, size: 30, color: VivoColors.ink),
              const SizedBox(height: VivoDimens.sm),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: textInset),
                child: Text(
                  phase.label,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AnelloPainter extends CustomPainter {
  const _AnelloPainter({required this.apertura, required this.phase});

  final double apertura;
  final BreathPhase phase;

  @override
  void paint(Canvas canvas, Size size) {
    final centro = size.center(Offset.zero);
    const raggioMinimo = BreathingCircle.minRadius;
    const raggioMassimo = BreathingCircle.maxRadius;
    final raggio = raggioMinimo + (raggioMassimo - raggioMinimo) * apertura;

    canvas.drawCircle(
      centro,
      raggio,
      Paint()
        ..color = VivoColors.accent.withValues(alpha: 0.18)
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      centro,
      raggio,
      Paint()
        ..color = VivoColors.ink.withValues(alpha: 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );

    // L'anello esterno resta sempre visibile per intero: senza, l'arco che
    // avanza sembrerebbe un graffio staccato dal disegno.
    const raggioAnello = raggioMassimo + 8;
    final anello = Rect.fromCircle(center: centro, radius: raggioAnello);
    canvas.drawCircle(
      centro,
      raggioAnello,
      Paint()
        ..color = VivoColors.ink.withValues(alpha: 0.12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    // Sopra all'anello, l'arco d'accento racconta a che punto è la fase.
    canvas.drawArc(
      anello,
      -math.pi / 2,
      2 * math.pi * apertura,
      false,
      Paint()
        ..color = VivoColors.accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_AnelloPainter oldDelegate) =>
      oldDelegate.apertura != apertura || oldDelegate.phase != phase;
}
