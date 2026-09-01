import 'package:flutter/material.dart';

import '../themes/colors.dart';
import '../themes/dimens.dart';

/// A che punto della sequenza si trova un passo.
enum StepDotState {
  done,

  current,

  upcoming,
}

/// L'indicatore di avanzamento in cima ai tre esercizi della sessione di aiuto.
///
/// Mostra un pallino per passo, uniti da una linea: quelli conclusi portano una
/// spunta, quello corrente è pieno, quelli futuri sono sbiaditi.
class StepDots extends StatelessWidget {
  const StepDots({required this.total, required this.current, super.key});

  final int total;

  final int current;

  @override
  Widget build(BuildContext context) {
    final elementi = <Widget>[];
    for (var i = 0; i < total; i++) {
      if (i > 0) {
        elementi.add(
          Expanded(
            child: Container(
              height: 2,
              color: VivoColors.onHeader.withValues(alpha: 0.26),
            ),
          ),
        );
      }
      elementi.add(
        StepDot(
          state: switch (i.compareTo(current)) {
            < 0 => StepDotState.done,
            0 => StepDotState.current,
            _ => StepDotState.upcoming,
          },
        ),
      );
    }

    return Semantics(
      label: 'Passo ${current + 1} di $total',
      child: ExcludeSemantics(child: Row(children: elementi)),
    );
  }
}

/// Un singolo pallino di [StepDots].
class StepDot extends StatelessWidget {
  const StepDot({required this.state, super.key});

  final StepDotState state;

  @override
  Widget build(BuildContext context) {
    final (Color sfondo, Widget? contenuto) = switch (state) {
      StepDotState.done => (
        VivoColors.accent,
        const Icon(
          Icons.check_rounded,
          size: 14,
          color: VivoColors.onAccent,
        ),
      ),
      StepDotState.current => (VivoColors.onHeader, null),
      StepDotState.upcoming => (
        VivoColors.onHeader.withValues(alpha: 0.3),
        null,
      ),
    };

    return Container(
      width: VivoDimens.lg,
      height: VivoDimens.lg,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: sfondo, shape: BoxShape.circle),
      child: contenuto,
    );
  }
}
