import 'package:flutter/material.dart';

import '../../../domain/models/help_request.dart';
import '../../core/themes/colors.dart';
import '../../core/themes/dimens.dart';

/// L'elenco delle sessioni di aiuto del giorno, aperto sopra al diario
/// oscurato.
class HelpRequestsSheet extends StatelessWidget {
  const HelpRequestsSheet({
    required this.requests,
    required this.dateLabel,
    required this.onClose,
    super.key,
  });

  final List<HelpRequest> requests;

  /// Il giorno a cui appartengono, come "Oggi, 12 Agosto 2026".
  ///
  /// Aperto a schermo intero l'elenco copre il calendario, e senza questa riga
  /// non si vedrebbe più di che giorno sono le sessioni.
  final String dateLabel;

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final testi = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(VivoDimens.lg),
        child: Material(
          color: VivoColors.card,
          borderRadius: BorderRadius.circular(VivoDimens.radiusCard),
          child: Padding(
            padding: const EdgeInsets.all(VivoDimens.md),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        'Richieste di aiuto',
                        style: testi.titleMedium,
                      ),
                    ),
                    IconButton(
                      onPressed: onClose,
                      tooltip: 'Chiudi',
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                Text(dateLabel, style: testi.bodySmall),
                const SizedBox(height: VivoDimens.sm),
                // L'elenco si accorcia quando lo spazio manca, invece di
                // spingere "Esci" oltre il bordo: è la stessa lezione
                // dell'area di testo della riflessione con il tastierino
                // delle emoji aperto.
                Flexible(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: VivoDimens.sm,
                    ),
                    decoration: BoxDecoration(
                      color: VivoColors.field,
                      borderRadius: BorderRadius.circular(
                        VivoDimens.radiusField,
                      ),
                      border: Border.all(color: VivoColors.line),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(
                        vertical: VivoDimens.sm,
                      ),
                      itemCount: requests.length,
                      separatorBuilder: (_, _) =>
                          const Divider(height: 1, color: VivoColors.line),
                      itemBuilder: (context, indice) =>
                          _Riga(number: indice + 1, request: requests[indice]),
                    ),
                  ),
                ),
                const SizedBox(height: VivoDimens.md),
                SizedBox(
                  width: double.infinity,
                  height: VivoDimens.buttonHeight,
                  child: FilledButton.icon(
                    onPressed: onClose,
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('Esci'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Una sessione dell'elenco.
class _Riga extends StatelessWidget {
  const _Riga({required this.number, required this.request});

  final int number;
  final HelpRequest request;

  @override
  Widget build(BuildContext context) {
    final testi = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: VivoDimens.sm),
      child: Row(
        children: <Widget>[
          SizedBox(width: 16, child: Text('$number', style: testi.labelSmall)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(request.time, style: testi.titleMedium),
                Text(
                  request.trigger?.label ?? 'Non indicato',
                  style: testi.bodySmall,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              RichText(
                text: TextSpan(
                  children: <InlineSpan>[
                    TextSpan(
                      text: '${request.intensity}',
                      style: testi.titleLarge,
                    ),
                    TextSpan(
                      text: '/${HelpRequest.maxIntensity}',
                      style: testi.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: VivoDimens.xs),
              SizedBox(
                width: 72,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: request.intensity / HelpRequest.maxIntensity,
                    minHeight: 8,
                    backgroundColor: VivoColors.line,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      VivoColors.header,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
