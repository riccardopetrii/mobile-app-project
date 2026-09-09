import 'package:flutter/material.dart';

import '../themes/colors.dart';
import '../themes/dimens.dart';

/// Le tre schede principali dell'applicazione.
enum VivoTab {
  home('Home', Icons.home_outlined),
  diario('Diario', Icons.menu_book_outlined),
  profilo('Profilo', Icons.person_outline_rounded);

  const VivoTab(this.label, this.icon);

  final String label;

  final IconData icon;
}

/// La barra di navigazione in fondo a tutte le schermate principali.
class VivoBottomNav extends StatelessWidget {
  const VivoBottomNav({
    required this.current,
    required this.onSelected,
    super.key,
  });

  final VivoTab current;

  final ValueChanged<VivoTab> onSelected;

  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(
      color: VivoColors.header,
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(VivoDimens.radiusPanel),
      ),
    ),
    child: SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: VivoDimens.sm),
        child: Row(
          children: <Widget>[
            for (final tab in VivoTab.values)
              Expanded(
                child: VivoNavItem(
                  tab: tab,
                  selected: tab == current,
                  // Toccare la scheda già aperta non deve far navigare di
                  // nuovo verso se stessa.
                  onTap: tab == current ? null : () => onSelected(tab),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

/// Una voce della barra di navigazione.
class VivoNavItem extends StatelessWidget {
  const VivoNavItem({
    required this.tab,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final VivoTab tab;

  final bool selected;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colore = VivoColors.onHeader.withValues(alpha: selected ? 1 : 0.6);

    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(VivoDimens.radiusField),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: VivoDimens.sm),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(tab.icon, size: 22, color: colore),
              const SizedBox(height: VivoDimens.xs),
              Text(
                tab.label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontSize: 11,
                  color: colore,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
