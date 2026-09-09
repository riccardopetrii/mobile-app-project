import 'package:flutter/material.dart';

import '../../../domain/use_cases/sos_session_use_case.dart';
import '../../core/themes/colors.dart';
import '../../core/themes/dimens.dart';
import '../view_model/grounding_view_model.dart';
import 'sos_header.dart';

/// L'esercizio di grounding 5-4-3-2-1, come in `wireframes/task-3.png`.
///
/// I passi già percorsi restano sbiaditi sopra a quello corrente, e sotto
/// compaiono le righe accennate di quelli che verranno: si vede da dove si
/// arriva e quanto manca, senza numeri da contare.
class GroundingScreen extends StatelessWidget {
  /// La chiave del filo verticale che collega un passo al successivo.
  ///
  /// Serve ai test per contarli: l'ultimo passo non lo disegna.
  static const Key filoDellaTimeline = Key('filo-della-timeline');

  const GroundingScreen({
    required this.viewModel,
    required this.showsProgress,
    required this.onNext,
    required this.onExit,
    super.key,
  });

  final GroundingViewModel viewModel;

  final bool showsProgress;

  final VoidCallback onNext;

  final VoidCallback onExit;

  void _avanza() {
    if (viewModel.isLastStep) {
      onNext();
      return;
    }
    viewModel.next();
  }

  /// Il tocco sulla schermata, che vale come "Avanti".
  ///
  /// Sull'ultimo passo non fa niente: lì il bottone dice "Fine" e porta al
  /// passo successivo della sessione, e uscire dall'esercizio deve restare una
  /// scelta voluta, non un tocco distratto.
  void _avanzaColTocco() {
    if (viewModel.isLastStep) return;
    viewModel.next();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      top: false,
      child: Column(
        children: <Widget>[
          SosHeader(
            step: SosStep.grounding,
            showsProgress: showsProgress,
            onExit: onExit,
          ),
          Expanded(
            // Tutta l'area dell'esercizio avanza al tocco: durante un attacco
            // di panico le mani tremano, e un bersaglio grande quanto la
            // schermata si prende meglio del bottone in fondo. È lo stesso
            // gesto della schermata di transizione.
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _avanzaColTocco,
              child: ListenableBuilder(
                listenable: viewModel,
                builder: (context, _) => SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    VivoDimens.lg,
                    VivoDimens.lg,
                    VivoDimens.lg,
                    VivoDimens.sm,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      for (final fatto in viewModel.completed)
                        _Passo(sense: fatto, faded: true, isLast: false),
                      _Passo(
                        sense: viewModel.current,
                        faded: false,
                        isLast: viewModel.isLastStep,
                      ),
                      const SizedBox(height: VivoDimens.md),
                      _RigheAccennate(
                        quanti:
                            GroundingSense.values.length -
                            viewModel.completed.length -
                            1,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          ListenableBuilder(
            listenable: viewModel,
            builder: (context, _) => SosBottomBar(
              label: viewModel.isLastStep ? 'Fine' : 'Avanti',
              onPressed: _avanza,
              infoTitle: 'Perché nominare cinque sensi',
              infoBody:
                  'Elencare quello che vedi, tocchi, senti, odori e gusti '
                  'riporta l\'attenzione al presente e al corpo, togliendola '
                  'ai pensieri che corrono. Non devi scrivere niente: basta '
                  'nominare le cose a mente e proseguire.',
            ),
          ),
        ],
      ),
    ),
  );
}

/// Un passo della timeline.
class _Passo extends StatelessWidget {
  const _Passo({
    required this.sense,
    required this.faded,
    required this.isLast,
  });

  final GroundingSense sense;
  final bool faded;

  /// Vero per l'ultimo senso dei cinque.
  ///
  /// Lì la timeline finisce: niente filo verso il basso, perché non incontra
  /// nessun passo successivo e resterebbe un moncone appeso, e pallino pieno e
  /// più grande, come il capolinea di una fermata.
  final bool isLast;

  /// Larghezza della colonnina che porta pallini e filo.
  ///
  /// È quella del pallino più grande, quello di capolinea: così tutti i
  /// pallini stanno sulla stessa verticale a prescindere dalla loro misura.
  static const double larghezzaAsse = 13;

  /// L'icona del senso, tinta come il pallino.
  ///
  /// Sono icone di Material, non emoji: quelle le disegna il font di sistema,
  /// sono a colori e cambiano da telefono a telefono.
  static const Map<GroundingSense, IconData> _icone =
      <GroundingSense, IconData>{
        GroundingSense.see: Icons.visibility_rounded,
        GroundingSense.touch: Icons.back_hand_rounded,
        GroundingSense.hear: Icons.hearing_rounded,
        GroundingSense.smell: Icons.air_rounded,
        GroundingSense.taste: Icons.restaurant_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final testi = Theme.of(context).textTheme;

    return Opacity(
      opacity: faded ? 0.42 : 1,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // La colonnina ha larghezza fissa e tiene pallino e filo al
            // centro: il pallino di capolinea è più grande degli altri, e con
            // la colonnina larga quanto il suo contenuto il suo centro finiva
            // due pixel a destra del filo che gli arriva sopra.
            SizedBox(
              width: larghezzaAsse,
              child: Column(
                children: <Widget>[
                  Container(
                    width: isLast ? 13 : 9,
                    height: isLast ? 13 : 9,
                    margin: EdgeInsets.only(top: isLast ? 6 : VivoDimens.sm),
                    decoration: BoxDecoration(
                      color: faded ? VivoColors.muted : VivoColors.header,
                      shape: BoxShape.circle,
                    ),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        key: GroundingScreen.filoDellaTimeline,
                        width: 1,
                        margin: const EdgeInsets.symmetric(
                          vertical: VivoDimens.xs,
                        ),
                        color: VivoColors.muted.withValues(alpha: 0.4),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: VivoDimens.md),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: VivoDimens.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Padding(
                          // L'icona sta sulla riga del titolo: il filo di spazio
                          // sopra la porta all'altezza delle lettere invece che
                          // del riquadro che le contiene.
                          padding: const EdgeInsets.only(top: 2),
                          child: Icon(
                            _icone[sense],
                            size: 18,
                            color: faded ? VivoColors.muted : VivoColors.header,
                          ),
                        ),
                        const SizedBox(width: VivoDimens.sm),
                        Expanded(
                          child: Text(sense.title, style: testi.titleMedium),
                        ),
                      ],
                    ),
                    const SizedBox(height: VivoDimens.xs),
                    Text(sense.guidance, style: testi.bodyMedium),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Le righe accennate dei passi che devono ancora arrivare.
class _RigheAccennate extends StatelessWidget {
  const _RigheAccennate({required this.quanti});

  final int quanti;

  @override
  Widget build(BuildContext context) {
    if (quanti <= 0) return const SizedBox.shrink();

    // Larghezze diverse, così somigliano a righe di testo non ancora leggibili.
    const larghezze = <double>[0.62, 0.92, 0.78, 0.86, 0.58, 0.88, 0.7];

    return ExcludeSemantics(
      child: Padding(
        // Le righe accennate partono dove parte il testo dei passi: la
        // colonnina dei pallini più lo stacco che la separa dal testo.
        padding: const EdgeInsets.only(
          left: _Passo.larghezzaAsse + VivoDimens.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            for (var passo = 0; passo < quanti; passo++)
              Padding(
                padding: const EdgeInsets.only(bottom: VivoDimens.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    for (var riga = 0; riga < 3; riga++)
                      FractionallySizedBox(
                        widthFactor: larghezze[(passo * 3 + riga) % 7],
                        child: Container(
                          height: 5,
                          margin: const EdgeInsets.only(bottom: VivoDimens.sm),
                          decoration: BoxDecoration(
                            color: VivoColors.ink.withValues(
                              alpha: passo == 0 ? 0.14 : 0.07,
                            ),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
