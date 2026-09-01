import 'package:flutter/material.dart';

import '../../../domain/models/mood_entry.dart';
import '../themes/colors.dart';
import '../themes/dimens.dart';
import 'mood_face.dart';

/// La fila di cinque faccine del mood tracker.
///
/// L'umore già registrato resta in evidenza, così riaprendo la home si vede
/// subito che cosa si è scelto quel giorno.
class MoodFacePicker extends StatelessWidget {
  const MoodFacePicker({required this.onSelected, this.selected, super.key});

  final Mood? selected;

  final ValueChanged<Mood> onSelected;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: <Widget>[
      for (final mood in Mood.values)
        Flexible(
          child: MoodFaceOption(
            mood: mood,
            selected: mood == selected,
            onTap: () => onSelected(mood),
          ),
        ),
    ],
  );
}

/// Una singola faccina selezionabile.
class MoodFaceOption extends StatelessWidget {
  const MoodFaceOption({
    required this.mood,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final Mood mood;

  final bool selected;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final testi = Theme.of(context).textTheme;
    final coloreTratto = selected ? VivoColors.onAccent : VivoColors.ink;

    return Semantics(
      label: 'Umore: ${mood.label}',
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(VivoDimens.radiusCard),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: VivoDimens.xs),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? VivoColors.accent : VivoColors.field,
                  shape: BoxShape.circle,
                ),
                child: MoodFace(mood: mood, color: coloreTratto, size: 32),
              ),
              const SizedBox(height: VivoDimens.xs),
              ExcludeSemantics(
                child: Text(
                  mood.label,
                  textAlign: TextAlign.center,
                  style: testi.labelMedium?.copyWith(
                    fontSize: 11,
                    color: selected ? VivoColors.ink : VivoColors.muted,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
