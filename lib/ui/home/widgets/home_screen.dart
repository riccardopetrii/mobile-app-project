import 'dart:io';

import 'package:flutter/material.dart';

import '../../../domain/use_cases/weekly_progress_use_case.dart';
import '../../core/themes/colors.dart';
import '../../core/themes/dimens.dart';
import '../../core/ui/mood_face_picker.dart';
import '../../core/ui/vivo_card.dart';
import '../../core/ui/vivo_scroll_fade.dart';
import '../view_model/home_view_model.dart';
import '../../core/ui/vivo_message.dart';

/// I due esercizi proposti nella sezione "Attività Consigliate".
enum HomeActivity {
  breathing('Respirazione guidata', 'Esercizio · 3 min', Icons.air_rounded),
  grounding('Grounding 5-4-3-2-1', 'Esercizio · 5 min', Icons.anchor_rounded);

  const HomeActivity(this.title, this.subtitle, this.icon);

  final String title;

  final String subtitle;

  final IconData icon;
}

/// La home, come in `wireframes/homepage.png`.
class HomeScreen extends StatefulWidget {
  const HomeScreen({
    required this.viewModel,
    required this.onHelpRequested,
    required this.onProfileRequested,
    required this.onActivityRequested,
    super.key,
  });

  final HomeViewModel viewModel;

  final VoidCallback onHelpRequested;

  final VoidCallback onProfileRequested;

  /// Chiamato da una delle attività consigliate.
  final void Function(String activity) onActivityRequested;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _ultimoAvviso;

  @override
  void initState() {
    super.initState();
    widget.viewModel.addListener(_alCambioStato);
    widget.viewModel.load.execute();
  }

  @override
  void dispose() {
    widget.viewModel.removeListener(_alCambioStato);
    super.dispose();
  }

  /// Mostra il messaggio del ViewModel quando una parte della home non si è
  /// potuta leggere o salvare: senza, la schermata si apre incompleta e chi la
  /// guarda non sa perché.
  void _alCambioStato() {
    if (!mounted) return;
    final avviso = widget.viewModel.errorMessage;
    if (avviso == null) {
      _ultimoAvviso = null;
      return;
    }
    if (avviso == _ultimoAvviso) return;
    _ultimoAvviso = avviso;
    mostraMessaggio(context, avviso, tono: widget.viewModel.errorTone);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) => VivoScrollFade(
        child: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              _Intestazione(
                greeting: widget.viewModel.greeting,
                date: widget.viewModel.formattedDate,
                avatarPath: widget.viewModel.avatarPath,
                onHelp: widget.onHelpRequested,
                onProfile: widget.onProfileRequested,
              ),
              Padding(
                // In cima serve almeno lo stacco pieno fra sezioni: il
                // pulsante di aiuto ha un'ombra che scende sotto il cerchio, e
                // la card del mood tracker le viene disegnata sopra. Con meno
                // spazio l'ombra finisce tagliata di netto dal bordo della
                // card.
                padding: const EdgeInsets.fromLTRB(
                  VivoDimens.lg,
                  VivoDimens.md,
                  VivoDimens.lg,
                  // In fondo ci vuole un respiro: senza, l'ultima card sta
                  // appoggiata alla barra di navigazione e la schermata sembra
                  // finire tagliata anche quando ci sta tutta.
                  14,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    VivoCard(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const VivoEyebrow('Mood tracker'),
                          // L'occhiello e il titolo sono la stessa cosa detta in
                          // due misure: stanno stretti apposta.
                          const SizedBox(height: VivoDimens.xs),
                          Text(
                            'Come ti senti oggi?',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: VivoDimens.xs),
                          MoodFacePicker(
                            selected: widget.viewModel.todayMood,
                            onSelected: widget.viewModel.saveMood.execute,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: VivoDimens.md),
                    Text(
                      'Attività Consigliate',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    // Il titolo appartiene alle due card che stanno sotto: lo
                    // stacco è quello di un'etichetta, non quello fra sezioni.
                    const SizedBox(height: VivoDimens.sm),
                    // IntrinsicHeight dà alla riga un'altezza finita, così le due
                    // card restano alte uguali anche se un titolo va a capo.
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          for (final attivita
                              in HomeActivity.values) ...<Widget>[
                            Expanded(
                              child: _CardAttivita(
                                activity: attivita,
                                onTap: () =>
                                    widget.onActivityRequested(attivita.name),
                              ),
                            ),
                            if (attivita != HomeActivity.values.last)
                              const SizedBox(width: VivoDimens.md),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: VivoDimens.md),
                    _CardProgressi(progress: widget.viewModel.progress),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// L'intestazione teal con il saluto, l'avatar e il pulsante di aiuto che
/// sporge sul bordo inferiore.
class _Intestazione extends StatelessWidget {
  const _Intestazione({
    required this.greeting,
    required this.date,
    required this.avatarPath,
    required this.onHelp,
    required this.onProfile,
  });

  final String greeting;
  final String date;
  final String? avatarPath;
  final VoidCallback onHelp;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) {
    final testi = Theme.of(context).textTheme;

    return Stack(
      alignment: Alignment.bottomCenter,
      clipBehavior: Clip.none,
      children: <Widget>[
        Container(
          width: double.infinity,
          // Il margine lascia posto alla metà inferiore del pulsante, che deve
          // restare dentro allo Stack: quello che sporge fuori dai bordi di un
          // widget viene disegnato ma non riceve i tocchi.
          margin: const EdgeInsets.only(bottom: VivoDimens.sosButtonSize / 2),
          decoration: const BoxDecoration(
            color: VivoColors.header,
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(VivoDimens.radiusPanel),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              // Lo spazio in fondo tiene il testo sopra il pulsante di aiuto,
              // che sporge per metà oltre il bordo dell'intestazione.
              padding: const EdgeInsets.fromLTRB(
                VivoDimens.lg,
                VivoDimens.md,
                VivoDimens.lg,
                VivoDimens.sosButtonSize / 2 + VivoDimens.sm,
              ),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          greeting,
                          style: testi.headlineSmall?.copyWith(
                            color: VivoColors.onHeader,
                          ),
                        ),
                        const SizedBox(height: VivoDimens.xs / 2),
                        Text(
                          date,
                          style: testi.bodySmall?.copyWith(
                            color: VivoColors.onHeader.withValues(alpha: 0.72),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: VivoDimens.md),
                  Semantics(
                    button: true,
                    label: 'Vai al profilo',
                    child: InkWell(
                      onTap: onProfile,
                      customBorder: const CircleBorder(),
                      child: _Avatar(path: avatarPath),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        _PulsanteAiuto(onTap: onHelp),
      ],
    );
  }
}

/// Il pulsante rotondo "Ho bisogno di aiuto".
///
/// È l'elemento più importante della schermata: unico in tinta d'accento, e
/// abbastanza grande da centrarlo anche con le mani che tremano.
class _PulsanteAiuto extends StatelessWidget {
  const _PulsanteAiuto({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'Ho bisogno di aiuto',
    child: Material(
      color: VivoColors.accent,
      shape: const CircleBorder(),
      elevation: 6,
      shadowColor: VivoColors.header.withValues(alpha: 0.4),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: VivoDimens.sosButtonSize,
          height: VivoDimens.sosButtonSize,
          child: ExcludeSemantics(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Icon(
                  Icons.favorite_border_rounded,
                  color: VivoColors.onAccent,
                  size: 30,
                ),
                const SizedBox(height: VivoDimens.xs),
                Text(
                  'Ho bisogno\ndi aiuto',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: VivoColors.onAccent,
                    fontSize: 14,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

/// Una delle due card delle attività consigliate.
class _CardAttivita extends StatelessWidget {
  const _CardAttivita({required this.activity, required this.onTap});

  final HomeActivity activity;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final testi = Theme.of(context).textTheme;

    return VivoCard(
      padding: const EdgeInsets.all(12),
      onTap: onTap,
      semanticLabel: '${activity.title}, ${activity.subtitle}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: VivoColors.field,
              shape: BoxShape.circle,
            ),
            child: Icon(activity.icon, size: 20, color: VivoColors.header),
          ),
          // L'icona e il titolo sono la stessa cosa: il vuoto fra loro era
          // quello che separa due blocchi diversi.
          const SizedBox(height: VivoDimens.sm),
          Text(
            activity.title,
            style: testi.titleMedium?.copyWith(fontSize: 15),
          ),
          const SizedBox(height: VivoDimens.xs / 2),
          Text(
            activity.subtitle,
            style: testi.bodySmall?.copyWith(fontSize: 12),
          ),
        ],
      ),
    );
  }
}

/// La card "I tuoi progressi".
class _CardProgressi extends StatelessWidget {
  const _CardProgressi({required this.progress});

  final WeeklyProgress? progress;

  @override
  Widget build(BuildContext context) {
    final testi = Theme.of(context).textTheme;
    final dati = progress;

    // Senza numeri la card resta al suo posto con un trattino: sparendo, la
    // home cambiava forma sotto gli occhi e lasciava un buco fra le attività
    // consigliate e la barra di navigazione, senza dire perché.
    final variazione = dati?.changePercent;

    return VivoCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('I tuoi progressi', style: testi.titleMedium),
                const SizedBox(height: VivoDimens.xs / 2),
                Text(
                  'Utilizzo del pulsante di aiuto',
                  style: testi.bodySmall?.copyWith(fontSize: 12),
                ),
                const SizedBox(height: VivoDimens.sm),
                Text(
                  dati == null ? '—' : '${dati.currentWeek}',
                  style: testi.displaySmall,
                ),
                const SizedBox(height: VivoDimens.xs / 2),
                Text(
                  'Click questa settimana',
                  style: testi.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  dati == null
                      ? 'Dati non disponibili'
                      : 'Settimana precedente: ${dati.previousWeek} click',
                  style: testi.bodySmall?.copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
          if (dati != null && variazione != null) ...<Widget>[
            const SizedBox(width: VivoDimens.sm),
            SizedBox(
              width: 116,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  // La percentuale si rimpicciolisce invece di sforare quando
                  // il numero è lungo o il testo di sistema è ingrandito.
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          // Il segno meno tipografico, non il trattino.
                          '${variazione < 0 ? '−' : '+'}'
                          '${variazione.abs()}%',
                          style: testi.headlineSmall?.copyWith(
                            fontSize: 30,
                            color: VivoColors.header,
                          ),
                        ),
                        Icon(
                          dati.isImproving
                              ? Icons.arrow_downward_rounded
                              : Icons.arrow_upward_rounded,
                          size: 20,
                          color: VivoColors.header,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: VivoDimens.xs),
                  Text(
                    dati.isImproving
                        ? 'Riduzione rispetto alla settimana scorsa'
                        : 'Aumento rispetto alla settimana scorsa',
                    textAlign: TextAlign.end,
                    style: testi.bodySmall?.copyWith(fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// L'immagine del profilo in cima alla home.
class _Avatar extends StatelessWidget {
  const _Avatar({required this.path});

  static const double lato = 48;

  final String? path;

  @override
  Widget build(BuildContext context) {
    final file = path;

    return Container(
      width: lato,
      height: lato,
      decoration: const BoxDecoration(
        color: VivoColors.onHeader,
        shape: BoxShape.circle,
      ),
      // Il ritaglio è un ClipOval vero, come nel profilo: il clipBehavior
      // della decorazione smette di ritagliare appena la decorazione porta un
      // bordo o un'ombra, e l'avatar deve restare tondo in tutte e due le
      // schermate.
      child: ClipOval(
        child: file == null
            ? const Icon(Icons.person_rounded, color: VivoColors.header)
            : Image.file(
                File(file),
                fit: BoxFit.cover,
                width: lato,
                height: lato,
                errorBuilder: (_, _, _) =>
                    const Icon(Icons.person_rounded, color: VivoColors.header),
              ),
      ),
    );
  }
}
