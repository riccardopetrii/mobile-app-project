import 'package:flutter/material.dart';

import '../../core/themes/colors.dart';
import '../../core/themes/dimens.dart';
import '../view_model/diary_view_model.dart';

/// Il calendario mensile in cima al diario.
///
/// Mostra il mese sfogliato con le tendine di mese e anno, le frecce ai lati e
/// la griglia dei giorni: un puntino sotto ai giorni con contenuti e il giorno
/// scelto evidenziato in teal.
class DiaryCalendar extends StatelessWidget {
  const DiaryCalendar({
    required this.viewModel,
    required this.onDaySelected,
    super.key,
  });

  final DiaryViewModel viewModel;

  final ValueChanged<DateTime> onDaySelected;

  @override
  Widget build(BuildContext context) {
    final giorni = viewModel.calendarDays;

    // Il calendario è un Material perché le sue caselle e le sue frecce sono
    // widget a inchiostro: senza, l'onda del tocco non avrebbe dove disegnarsi.
    return Material(
      color: VivoColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(VivoDimens.radiusCard),
        side: const BorderSide(color: VivoColors.line),
      ),
      child: Padding(
        padding: const EdgeInsets.all(VivoDimens.md),
        child: Column(
          children: <Widget>[
            _Intestazione(viewModel: viewModel),
            const SizedBox(height: VivoDimens.sm),
            Row(
              children: <Widget>[
                for (final etichetta in viewModel.weekdayLabels)
                  Expanded(
                    child: Center(
                      child: Text(
                        etichetta,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          letterSpacing: 0,
                          color: VivoColors.onCardMuted,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: VivoDimens.xs),
            for (var riga = 0; riga < giorni.length / 7; riga++)
              Row(
                children: <Widget>[
                  for (final giorno in giorni.skip(riga * 7).take(7))
                    Expanded(
                      child: _Giorno(
                        day: giorno,
                        selected: giorno.date == viewModel.selectedDate,
                        onTap: () => onDaySelected(giorno.date),
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// La riga con le frecce e le tendine di mese e anno.
class _Intestazione extends StatelessWidget {
  const _Intestazione({required this.viewModel});

  final DiaryViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final mese = viewModel.visibleMonth;

    return Row(
      children: <Widget>[
        IconButton(
          onPressed: viewModel.showPreviousMonth,
          tooltip: 'Mese precedente',
          icon: const Icon(Icons.chevron_left_rounded),
        ),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              _Tendina<int>(
                label: viewModel.monthLabels[mese.month - 1],
                value: mese.month,
                values: List<int>.generate(12, (indice) => indice + 1),
                labelOf: (numero) => viewModel.monthLabels[numero - 1],
                onSelected: (numero) =>
                    viewModel.showMonth(year: mese.year, month: numero),
              ),
              const SizedBox(width: VivoDimens.sm),
              _Tendina<int>(
                label: '${mese.year}',
                value: mese.year,
                values: viewModel.years,
                labelOf: (anno) => '$anno',
                onSelected: (anno) =>
                    viewModel.showMonth(year: anno, month: mese.month),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: viewModel.showNextMonth,
          tooltip: 'Mese successivo',
          icon: const Icon(Icons.chevron_right_rounded),
        ),
      ],
    );
  }
}

/// Una tendina di scelta, usata per il mese e per l'anno.
///
/// È un menu a comparsa invece di un `DropdownButton` perché quest'ultimo
/// costruisce tutte le voci anche da chiuso, e il valore mostrato non si
/// distinguerebbe da quelli nascosti.
class _Tendina<T> extends StatelessWidget {
  const _Tendina({
    required this.label,
    required this.value,
    required this.values,
    required this.labelOf,
    required this.onSelected,
  });

  final String label;
  final T value;
  final List<T> values;
  final String Function(T value) labelOf;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) => PopupMenuButton<T>(
    initialValue: value,
    onSelected: onSelected,
    tooltip: '',
    itemBuilder: (context) => <PopupMenuEntry<T>>[
      for (final voce in values)
        PopupMenuItem<T>(value: voce, child: Text(labelOf(voce))),
    ],
    child: Container(
      padding: const EdgeInsets.symmetric(
        horizontal: VivoDimens.md,
        vertical: VivoDimens.sm,
      ),
      decoration: BoxDecoration(
        color: VivoColors.field,
        borderRadius: BorderRadius.circular(VivoDimens.radiusField),
        border: Border.all(color: VivoColors.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          const Icon(Icons.arrow_drop_down_rounded, color: VivoColors.muted),
        ],
      ),
    ),
  );
}

/// Una casella del calendario.
class _Giorno extends StatelessWidget {
  const _Giorno({
    required this.day,
    required this.selected,
    required this.onTap,
  });

  final DiaryDay day;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final testi = Theme.of(context).textTheme;
    final colore = selected
        ? VivoColors.onHeader
        : day.isCurrentMonth
        ? VivoColors.onCard
        : VivoColors.onCardMuted.withValues(alpha: 0.45);

    return Semantics(
      button: true,
      selected: selected,
      label: '${day.date.day}',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(VivoDimens.radiusField),
        child: Padding(
          // Due pixel invece di quattro: fra la fine di una riga e l'inizio
          // della successiva restano dieci pixel invece di quattordici, e il
          // calendario cala di ventiquattro. Il tondo del giorno resta 34
          // perché è anche il bersaglio del dito, ed è la cosa che si tocca
          // più spesso nel diario.
          padding: EdgeInsets.symmetric(vertical: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? VivoColors.header : Colors.transparent,
                  borderRadius: BorderRadius.circular(VivoDimens.radiusField),
                ),
                child: ExcludeSemantics(
                  child: Text(
                    '${day.date.day}',
                    style: testi.bodyMedium?.copyWith(color: colore),
                  ),
                ),
              ),
              // Il puntino resta al suo posto anche quando è spento, così le
              // righe della griglia non cambiano altezza fra un mese e l'altro.
              Container(
                margin: const EdgeInsets.only(top: 2),
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: day.hasContent
                      ? (selected ? VivoColors.accent : VivoColors.header)
                      : Colors.transparent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
