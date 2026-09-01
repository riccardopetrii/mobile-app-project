import 'package:flutter/material.dart';

import '../themes/colors.dart';
import '../themes/dimens.dart';

/// La card chiara usata in tutte le schermate.
///
/// Raccoglie in un posto solo il colore, il raggio e lo spazio interno, così
/// tutte le card della stessa schermata restano allineate.
class VivoCard extends StatelessWidget {
  const VivoCard({
    required this.child,
    this.padding = const EdgeInsets.all(VivoDimens.md),
    this.onTap,
    this.semanticLabel,
    super.key,
  });

  final Widget child;

  final EdgeInsetsGeometry padding;

  final VoidCallback? onTap;

  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final contenuto = Padding(padding: padding, child: child);

    if (onTap == null) {
      return DecoratedBox(decoration: decorazione, child: contenuto);
    }

    return Semantics(
      button: true,
      label: semanticLabel,
      child: DecoratedBox(
        decoration: decorazione,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(VivoDimens.radiusCard),
            child: contenuto,
          ),
        ),
      ),
    );
  }

  /// L'aspetto della card.
  static final BoxDecoration decorazione = BoxDecoration(
    color: VivoColors.card,
    borderRadius: BorderRadius.circular(VivoDimens.radiusCard),
    border: Border.all(color: VivoColors.header.withValues(alpha: 0.07)),
    boxShadow: <BoxShadow>[
      // Un contatto ravvicinato, che àncora la card al fondo.
      BoxShadow(
        color: VivoColors.header.withValues(alpha: 0.06),
        blurRadius: 2,
        offset: const Offset(0, 1),
      ),
      // E una diffusione ampia, che le dà rilievo.
      BoxShadow(
        color: VivoColors.header.withValues(alpha: 0.09),
        blurRadius: 18,
        spreadRadius: -6,
        offset: const Offset(0, 8),
      ),
    ],
  );
}

/// Il titolo di una card, con il sottotitolo facoltativo sotto.
class VivoCardTitle extends StatelessWidget {
  const VivoCardTitle({required this.title, this.subtitle, this.trailing, super.key});

  final String title;

  final String? subtitle;

  /// Un elemento allineato a destra del titolo, come l'ora dell'ultimo
  /// salvataggio.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final testi = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(child: Text(title, style: testi.titleMedium)),
            ?trailing,
          ],
        ),
        if (subtitle != null) ...<Widget>[
          const SizedBox(height: VivoDimens.xs / 2),
          Text(subtitle!, style: testi.bodySmall),
        ],
      ],
    );
  }
}

/// Il sopratitolo maiuscolo, come "MOOD TRACKER".
class VivoEyebrow extends StatelessWidget {
  const VivoEyebrow(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    style: Theme.of(context).textTheme.labelSmall,
  );
}
