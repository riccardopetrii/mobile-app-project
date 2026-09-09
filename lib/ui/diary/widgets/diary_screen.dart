import 'package:flutter/material.dart';

import '../../../domain/models/help_request.dart';
import '../../../domain/models/mood_entry.dart';
import '../../core/themes/colors.dart';
import '../../core/themes/dimens.dart';
import '../../core/ui/mood_face.dart';
import '../../core/ui/vivo_card.dart';
import '../../core/ui/vivo_header.dart';
import '../../core/ui/vivo_scroll_fade.dart';
import '../view_model/diary_view_model.dart';
import 'diary_calendar.dart';
import 'help_requests_sheet.dart';
import 'reflection_sheet.dart';
import '../../core/ui/vivo_message.dart';

/// La scheda "Diario": calendario, umore, sessioni e riflessione del giorno.
class DiaryScreen extends StatefulWidget {
  const DiaryScreen({required this.viewModel, super.key});

  final DiaryViewModel viewModel;

  @override
  State<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends State<DiaryScreen> {
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

  /// Mostra il messaggio del ViewModel quando una parte del giorno non si è
  /// potuta leggere: senza, il diario si aprirebbe a metà senza spiegare
  /// perché la card resta vuota.
  void _alCambioStato() {
    if (!mounted) return;
    final avviso = widget.viewModel.errorMessage;
    if (avviso == null) {
      _ultimoAvviso = null;
      return;
    }
    // Lo stesso avviso non si ripete a ogni ridisegno.
    if (avviso == _ultimoAvviso) return;
    _ultimoAvviso = avviso;
    mostraMessaggio(context, avviso, tono: widget.viewModel.errorTone);
  }

  /// Apre un foglio sopra tutta l'applicazione, con il diario oscurato sotto.
  Future<void> _mostraFoglio(WidgetBuilder contenuto) =>
      showGeneralDialog<void>(
        context: context,
        barrierDismissible: true,
        barrierLabel: 'Chiudi',
        barrierColor: VivoColors.ink.withValues(alpha: 0.55),
        // Il foglio compariva di colpo quando stava nel corpo della
        // schermata: resta così anche adesso che è una rotta.
        transitionDuration: Duration.zero,
        pageBuilder: (context, _, _) => Padding(
          // Con la tastiera aperta il foglio si centra nello spazio che
          // resta, come faceva quando il corpo della schermata si accorciava
          // da solo.
          padding: MediaQuery.viewInsetsOf(context),
          child: contenuto(context),
        ),
      );

  /// La riflessione si apre solo dove si può scrivere: un giorno che deve
  /// ancora arrivare non si annota.
  void _apriRiflessione() {
    if (!widget.viewModel.canEditReflection) return;
    _mostraFoglio(
      (fogliContext) => ReflectionSheet(
        initialText: widget.viewModel.reflection,
        onSave: (testo) => _salvaRiflessione(fogliContext, testo),
        onClose: () => Navigator.of(fogliContext).pop(),
      ),
    );
  }

  /// L'elenco esteso si apre solo se quel giorno ha davvero delle sessioni.
  void _apriRichieste() {
    if (widget.viewModel.requestsOfDay.isEmpty) return;
    _mostraFoglio(
      (fogliContext) => HelpRequestsSheet(
        requests: widget.viewModel.requestsOfDay,
        dateLabel: widget.viewModel.selectedDateLabel,
        onClose: () => Navigator.of(fogliContext).pop(),
      ),
    );
  }

  Future<void> _salvaRiflessione(
    BuildContext fogliContext,
    String testo,
  ) async {
    await widget.viewModel.saveReflection.execute(testo);
    if (fogliContext.mounted) Navigator.of(fogliContext).pop();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.viewModel,
    builder: (context, _) {
      final viewModel = widget.viewModel;

      return Column(
        children: <Widget>[
          const VivoHeader(
            title: 'Il tuo diario personale',
            subtitle: 'Uno spazio sicuro per i tuoi pensieri',
          ),
          Expanded(
            child: VivoScrollFade(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  VivoDimens.lg,
                  VivoDimens.md,
                  VivoDimens.lg,
                  VivoDimens.xl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    DiaryCalendar(
                      viewModel: viewModel,
                      onDaySelected: viewModel.selectDay,
                    ),
                    const SizedBox(height: VivoDimens.md),
                    Text(
                      viewModel.selectedDateLabel,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: VivoDimens.sm),
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          _CardMood(mood: viewModel.mood),
                          const SizedBox(width: VivoDimens.md),
                          Expanded(
                            child: _CardRichieste(
                              requests: viewModel.requestsOfDay,
                              onTap: _apriRichieste,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: VivoDimens.md),
                    _CardRiflessione(
                      reflection: viewModel.reflection,
                      lastSavedLabel: viewModel.lastSavedLabel,
                      editable: viewModel.canEditReflection,
                      onTap: _apriRiflessione,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
}

/// La card quadrata con la faccina del giorno scelto.
class _CardMood extends StatelessWidget {
  const _CardMood({required this.mood});

  final Mood? mood;

  @override
  Widget build(BuildContext context) {
    final testi = Theme.of(context).textTheme;
    final umore = mood;

    return SizedBox(
      // Resta 116 e non si stringe: sotto i 116 "Non registrato", l'etichetta
      // dei giorni senza umore, va a capo su due righe e la coppia di card
      // cresce di diciotto pixel invece di calare. Stringere il Mood costava
      // altezza, non la guadagnava.
      width: 116,
      child: VivoCard(
        padding: const EdgeInsets.all(VivoDimens.sm),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text('Mood', style: testi.titleMedium),
            const SizedBox(height: VivoDimens.sm),
            if (umore == null)
              const Icon(
                Icons.remove_circle_outline_rounded,
                size: 40,
                color: VivoColors.muted,
              )
            else
              MoodFace(mood: umore, color: VivoColors.header, size: 40),
            const SizedBox(height: VivoDimens.xs),
            // Una riga sola, sempre. "Non registrato" è l'etichetta più
            // lunga e ne occupa 98 dei 100 pixel utili: se andasse a capo, la
            // card del Mood crescerebbe di diciotto pixel e con lei quella
            // delle richieste, che le sta affiancata. Passando da un giorno
            // senza umore a uno con l'umore la coppia salterebbe.
            Text(
              umore?.label ?? 'Non registrato',
              textAlign: TextAlign.center,
              maxLines: 1,
              style: testi.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

/// L'elenco compatto delle sessioni del giorno.
class _CardRichieste extends StatelessWidget {
  const _CardRichieste({required this.requests, required this.onTap});

  /// Oltre questo numero di sessioni la card smette di allungarsi.
  ///
  /// Non è un vezzo: una card che cresce con le sessioni spinge la riflessione
  /// sotto il bordo dello schermo, e chi ha avuto una giornata pesante è
  /// proprio quello a cui la riflessione serve di più.
  static const int _quanteVisibili = 3;

  final List<HelpRequest> requests;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final testi = Theme.of(context).textTheme;
    final visibili = requests.take(_quanteVisibili).toList();
    final nascoste = requests.length - visibili.length;

    return VivoCard(
      // Ai lati lo stesso margine delle altre card: con otto pixel il titolo
      // sfiorava il bordo. Sopra e sotto qualcosa in meno, perché qui il
      // contenuto sono righe corte e non un paragrafo.
      padding: const EdgeInsets.fromLTRB(VivoDimens.md, 12, VivoDimens.md, 12),
      onTap: requests.isEmpty ? null : onTap,
      semanticLabel: 'Richieste di aiuto',
      child: Stack(
        children: <Widget>[
          // Il giorno più pieno, disegnato invisibile sotto quello vero.
          Visibility(
            visible: false,
            maintainSize: true,
            maintainAnimation: true,
            maintainState: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // Le scritte del fantasma sono vuote: un testo senza lettere è
                // alto come uno pieno, perché l'altezza gliela dà il carattere
                // e non il contenuto, e così nell'albero non compaiono parole
                // doppie che confonderebbero chi legge la schermata e i test.
                Text('', style: testi.titleMedium),
                const SizedBox(height: VivoDimens.sm),
                for (var riga = 0; riga < _quanteVisibili; riga++)
                  Padding(
                    padding: EdgeInsets.only(
                      bottom: riga < _quanteVisibili - 1 ? VivoDimens.sm : 0,
                    ),
                    child: const _RigaSessione.fantasma(),
                  ),
                const _AltreSessioni(),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Richieste di aiuto', style: testi.titleMedium),
              const SizedBox(height: VivoDimens.sm),
              if (requests.isEmpty)
                Text('Nessuna richiesta di aiuto', style: testi.bodySmall)
              else
                for (final (indice, richiesta) in visibili.indexed)
                  Padding(
                    padding: EdgeInsets.only(
                      bottom: indice < visibili.length - 1 ? VivoDimens.sm : 0,
                    ),
                    child: _RigaSessione(
                      numero: indice + 1,
                      request: richiesta,
                    ),
                  ),
              if (nascoste > 0) const _AltreSessioni(),
            ],
          ),
        ],
      ),
    );
  }
}

/// Una sessione dell'elenco compatto.
class _RigaSessione extends StatelessWidget {
  const _RigaSessione({required this.numero, required this.request});

  /// La riga senza sessione dentro, usata soltanto per tenere lo spazio.
  ///
  /// Le sue scritte sono vuote: restano alte come quelle vere, ma non
  /// aggiungono all'albero un orario e un'intensità che nessuno deve leggere.
  const _RigaSessione.fantasma() : numero = 0, request = null;

  final int numero;

  final HelpRequest? request;

  @override
  Widget build(BuildContext context) {
    final testi = Theme.of(context).textTheme;
    final sessione = request;
    final quota =
        (sessione?.intensity ?? HelpRequest.minIntensity) /
        HelpRequest.maxIntensity;
    final ora = sessione?.time ?? '';
    final intensita = sessione == null ? '' : '${sessione.intensity}';

    return Row(
      children: <Widget>[
        Container(
          width: 18,
          height: 18,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: VivoColors.field,
            shape: BoxShape.circle,
          ),
          child: Text(
            sessione == null ? '' : '$numero',
            style: testi.labelSmall?.copyWith(letterSpacing: 0),
          ),
        ),
        const SizedBox(width: VivoDimens.sm),
        // Anche qui l'interlinea del corpo di testo è aria che non serve: la
        // riga è alta quanto l'elemento più alto, e senza questo taglio a
        // decidere sarebbe l'orario invece del tondino.
        Text(ora, style: testi.bodyMedium?.copyWith(height: 1.15)),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: VivoDimens.sm,
            vertical: 1,
          ),
          decoration: BoxDecoration(
            // La pastiglia si fa più carica quanto più l'intensità è alta:
            // scorrendo l'elenco la giornata si legge prima dei numeri.
            color: VivoColors.header.withValues(alpha: 0.12 + quota * 0.5),
            borderRadius: BorderRadius.circular(VivoDimens.radiusField),
          ),
          child: Text(
            intensita,
            // L'interlinea di bodySmall serve ai paragrafi; qui dentro, su una
            // cifra sola, sono soltanto pixel di altezza in più.
            style: testi.bodySmall?.copyWith(
              color: VivoColors.ink,
              height: 1.1,
            ),
          ),
        ),
      ],
    );
  }
}

/// I tre puntini che dicono "ce ne sono altre".
///
/// Sono disegnati invece che scritti: il carattere "···" porta con sé
/// l'interlinea della sua riga di testo, una ventina di pixel per tre punti,
/// e in una card che deve restare bassa sono pixel sprecati.
class _AltreSessioni extends StatelessWidget {
  const _AltreSessioni();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: VivoDimens.sm),
    child: Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (var punto = 0; punto < 3; punto++)
            Container(
              width: 4,
              height: 4,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: const BoxDecoration(
                color: VivoColors.muted,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    ),
  );
}

/// La card con la riflessione del giorno, in sola lettura.
class _CardRiflessione extends StatelessWidget {
  const _CardRiflessione({
    required this.reflection,
    required this.lastSavedLabel,
    required this.editable,
    required this.onTap,
  });

  final String reflection;
  final String? lastSavedLabel;
  final bool editable;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final testi = Theme.of(context).textTheme;

    return VivoCard(
      onTap: editable ? onTap : null,
      semanticLabel: 'La tua riflessione',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text('La tua riflessione', style: testi.titleMedium),
              ),
              if (lastSavedLabel != null)
                Text(lastSavedLabel!, style: testi.bodySmall),
            ],
          ),
          const SizedBox(height: VivoDimens.sm),
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 96),
            padding: const EdgeInsets.all(VivoDimens.sm),
            decoration: BoxDecoration(
              color: VivoColors.field,
              borderRadius: BorderRadius.circular(VivoDimens.radiusField),
              border: Border.all(color: VivoColors.line),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: Text(
                    reflection.isEmpty
                        ? 'Inserisci qui la tua riflessione...'
                        : reflection,
                    style: testi.bodyMedium?.copyWith(
                      color: reflection.isEmpty
                          ? VivoColors.onCardMuted
                          : VivoColors.onCard,
                    ),
                  ),
                ),
                if (editable)
                  const Icon(
                    Icons.edit_outlined,
                    size: 18,
                    color: VivoColors.muted,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
