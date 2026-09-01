import 'package:flutter/material.dart';

import '../themes/colors.dart';
import '../themes/dimens.dart';

/// Il pannello teal arrotondato in cima alle schermate.
class VivoHeader extends StatelessWidget {
  const VivoHeader({
    required this.title,
    this.subtitle,
    this.trailing,
    this.bottomPadding = VivoDimens.lg,
    this.titleStyle,
    super.key,
  });

  final String title;

  final String? subtitle;

  final Widget? trailing;

  final double bottomPadding;

  final TextStyle? titleStyle;

  @override
  Widget build(BuildContext context) {
    final testi = Theme.of(context).textTheme;

    return Container(
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
          padding: EdgeInsets.fromLTRB(
            VivoDimens.lg,
            VivoDimens.md,
            VivoDimens.lg,
            bottomPadding,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: (titleStyle ?? testi.headlineSmall)?.copyWith(
                        color: VivoColors.onHeader,
                      ),
                    ),
                    if (subtitle != null) ...<Widget>[
                      const SizedBox(height: VivoDimens.xs / 2),
                      Text(
                        subtitle!,
                        style: testi.bodySmall?.copyWith(
                          color: VivoColors.onHeader.withValues(alpha: 0.72),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...<Widget>[
                const SizedBox(width: VivoDimens.md),
                trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Il bottone "✕ Esci" in alto a destra delle schermate della sessione.
class VivoExitButton extends StatelessWidget {
  const VivoExitButton({required this.onPressed, super.key});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'Esci',
    child: InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(VivoDimens.radiusField),
      child: Padding(
        padding: const EdgeInsets.all(VivoDimens.xs),
        child: ExcludeSemantics(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(Icons.close_rounded, color: VivoColors.onHeader),
              Text(
                'Esci',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  letterSpacing: 0,
                  color: VivoColors.onHeader.withValues(alpha: 0.75),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
