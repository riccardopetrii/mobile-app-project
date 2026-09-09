import 'package:flutter/material.dart';

import '../../../domain/use_cases/sos_session_use_case.dart';
import '../../core/themes/colors.dart';
import '../../core/themes/dimens.dart';
import '../../core/ui/step_dots.dart';
import '../../core/ui/vivo_header.dart';

/// L'intestazione teal condivisa dai tre esercizi.
///
/// Porta l'indicatore a tre pallini, il titolo dell'esercizio e la "✕ Esci".
/// Un esercizio avviato da solo dalla home non mostra i pallini, perché non fa
/// parte di una sequenza.
class SosHeader extends StatelessWidget {
  const SosHeader({
    required this.step,
    required this.showsProgress,
    required this.onExit,
    super.key,
  });

  final SosStep step;

  final bool showsProgress;

  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    decoration: const BoxDecoration(
      color: VivoColors.header,
      borderRadius: BorderRadius.vertical(
        bottom: Radius.circular(VivoDimens.radiusPanel),
      ),
    ),
    child: SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          VivoDimens.lg,
          VivoDimens.md,
          VivoDimens.lg,
          VivoDimens.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (showsProgress) ...<Widget>[
              StepDots(total: SosStep.count, current: step.index),
              const SizedBox(height: VivoDimens.md),
            ],
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        step.title,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(color: VivoColors.onHeader),
                      ),
                      const SizedBox(height: VivoDimens.xs / 2),
                      Text(
                        step.subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: VivoColors.onHeader.withValues(alpha: 0.72),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: VivoDimens.sm),
                VivoExitButton(onPressed: onExit),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

/// La riga in fondo agli esercizi: la "i" delle informazioni e il bottone che
/// porta avanti.
class SosBottomBar extends StatelessWidget {
  const SosBottomBar({
    required this.label,
    required this.onPressed,
    required this.infoTitle,
    required this.infoBody,
    super.key,
  });

  final String label;

  final VoidCallback onPressed;

  final String infoTitle;

  final String infoBody;

  void _mostraInformazioni(BuildContext context) => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(infoTitle),
      content: Text(infoBody),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Ho capito'),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      VivoDimens.lg,
      VivoDimens.sm,
      VivoDimens.lg,
      VivoDimens.lg,
    ),
    child: Row(
      children: <Widget>[
        Semantics(
          button: true,
          label: 'Informazioni',
          child: IconButton(
            onPressed: () => _mostraInformazioni(context),
            icon: const Icon(Icons.info_outline_rounded),
            color: VivoColors.ink,
            style: IconButton.styleFrom(
              side: const BorderSide(color: VivoColors.line),
            ),
          ),
        ),
        const SizedBox(width: VivoDimens.md),
        Expanded(
          child: FilledButton(
            onPressed: onPressed,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
                const SizedBox(width: VivoDimens.sm),
                const Icon(Icons.arrow_forward_rounded, size: 18),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
