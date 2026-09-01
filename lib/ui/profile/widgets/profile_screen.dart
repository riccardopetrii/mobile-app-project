import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../domain/models/user.dart';
import '../../core/themes/colors.dart';
import '../../core/themes/dimens.dart';
import '../../core/ui/vivo_card.dart';
import '../../core/ui/vivo_scroll_fade.dart';
import '../../core/ui/vivo_text_field.dart';
import '../view_model/profile_view_model.dart';
import '../../core/ui/vivo_message.dart';

/// Il profilo, come in `wireframes/profilo.png`.
///
/// L'ospite non ha dati anagrafici da mostrare: al posto della card dei dati
/// personali trova l'invito a crearsi un profilo, e fra le impostazioni gli
/// resta la sola disconnessione.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    required this.viewModel,
    required this.onLoggedOut,
    super.key,
  });

  final ProfileViewModel viewModel;

  /// Chiamato quando la sessione si chiude, per disconnessione o per
  /// eliminazione dell'account.
  final VoidCallback onLoggedOut;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _nome = TextEditingController();
  final TextEditingController _cognome = TextEditingController();
  final TextEditingController _email = TextEditingController();

  DateTime? _dataNascita;
  String? _genere;

  /// L'ultimo profilo copiato nei campi.
  ///
  /// Il ViewModel avvisa a ogni cambiamento, anche mentre si scrive: senza
  /// questo confronto i campi verrebbero riscritti sotto le dita.
  User? _copiato;

  @override
  void initState() {
    super.initState();
    widget.viewModel.addListener(_alCambioStato);
    widget.viewModel.load.execute();
  }

  @override
  void dispose() {
    widget.viewModel.removeListener(_alCambioStato);
    _nome.dispose();
    _cognome.dispose();
    _email.dispose();
    super.dispose();
  }

  void _alCambioStato() {
    if (!mounted) return;
    final profilo = widget.viewModel.user;
    if (profilo != null && profilo != _copiato) {
      _copiato = profilo;
      _nome.text = profilo.nome ?? '';
      _cognome.text = profilo.cognome ?? '';
      _email.text = profilo.email ?? '';
      setState(() {
        _dataNascita = profilo.dataNascita;
        _genere = profilo.genere;
      });
    }
    _mostraMessaggi();
  }

  /// Porta in fondo allo schermo la conferma o l'errore appena arrivati.
  void _mostraMessaggi() {
    final errore = widget.viewModel.errorMessage;
    final conferma = widget.viewModel.statusMessage;
    if (errore == null && conferma == null) return;

    // Prima il profilo si disegnava da solo il proprio rosso, e da quando il
    // tema impone il testo scuro delle card quel fondo pieno era illeggibile.
    // Ora passa dallo stesso posto delle altre schermate.
    mostraMessaggio(
      context,
      errore ?? conferma!,
      tono: errore != null ? widget.viewModel.errorTone : MessageTone.notice,
    );
    widget.viewModel.clearMessages();
  }

  Future<void> _scegliData() async {
    final adesso = DateTime.now();
    final scelta = await showDatePicker(
      context: context,
      initialDate: _dataNascita ?? DateTime(adesso.year - 25),
      firstDate: DateTime(adesso.year - 120),
      lastDate: adesso,
      locale: const Locale('it'),
      helpText: 'Data di nascita',
      cancelText: 'Annulla',
      confirmText: 'Scegli',
    );
    if (scelta != null) setState(() => _dataNascita = scelta);
  }

  void _salva() => widget.viewModel.saveProfile.execute(
    ProfileData(
      nome: _nome.text,
      cognome: _cognome.text,
      email: _email.text,
      dataNascita: _dataNascita,
      genere: _genere,
    ),
  );

  Future<void> _scegliOrario() async {
    final promemoria = widget.viewModel.reminder;
    final scelto = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: promemoria.hour, minute: promemoria.minute),
      helpText: 'Orario del promemoria',
      cancelText: 'Annulla',
      confirmText: 'Scegli',
    );
    if (scelto == null) return;
    await widget.viewModel.setReminderTime.execute(
      ReminderTime(hour: scelto.hour, minute: scelto.minute),
    );
  }

  Future<void> _cambiaPassword() async {
    final cambio = await showDialog<PasswordChange>(
      context: context,
      builder: (_) => const _DialogoPassword(),
    );
    if (cambio == null) return;
    await widget.viewModel.changePassword.execute(cambio);
  }

  Future<void> _disconnetti() async {
    await widget.viewModel.logout.execute();
    if (widget.viewModel.logout.completed) widget.onLoggedOut();
  }

  Future<void> _eliminaAccount() async {
    final confermato = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Elimina account'),
        content: const Text(
          'Vengono cancellati dal telefono il tuo profilo, gli umori, le '
          'riflessioni e le richieste di aiuto. I dati non sono da nessun\'altra '
          'parte: non si possono recuperare.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: VivoColors.danger),
            child: const Text('Elimina tutto'),
          ),
        ],
      ),
    );
    if (confermato != true) return;

    await widget.viewModel.deleteAccount.execute();
    if (widget.viewModel.deleteAccount.completed) widget.onLoggedOut();
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
                avatarPath: widget.viewModel.user?.avatarPath,
                onChangeAvatar: widget.viewModel.changeAvatar.execute,
                // Un ospite non ha un profilo a cui attaccare un'immagine.
                puoCambiareImmagine: !widget.viewModel.isGuest,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  VivoDimens.lg,
                  VivoDimens.sm,
                  VivoDimens.lg,
                  VivoDimens.md,
                ),
                child: Column(
                  children: <Widget>[
                    if (widget.viewModel.isGuest)
                      const _CardOspite()
                    else
                      _CardDatiPersonali(
                        nome: _nome,
                        cognome: _cognome,
                        email: _email,
                        dataNascita: _dataNascita,
                        genere: _genere,
                        onPickDate: _scegliData,
                        onPickGender: (genere) =>
                            setState(() => _genere = genere),
                        onSave: _salva,
                      ),
                    const SizedBox(height: VivoDimens.md),
                    _CardImpostazioni(
                      viewModel: widget.viewModel,
                      onPickTime: _scegliOrario,
                      onChangePassword: _cambiaPassword,
                      onLogout: _disconnetti,
                    ),
                    const SizedBox(height: VivoDimens.md),
                    if (!widget.viewModel.isGuest)
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: _eliminaAccount,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: VivoColors.danger,
                            side: const BorderSide(color: VivoColors.danger),
                          ),
                          child: const Text('Elimina Account'),
                        ),
                      ),
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

/// L'intestazione teal con l'immagine del profilo che sporge sotto il bordo.
class _Intestazione extends StatelessWidget {
  const _Intestazione({
    required this.avatarPath,
    required this.onChangeAvatar,
    required this.puoCambiareImmagine,
  });

  /// Diametro dell'immagine del profilo.
  ///
  /// Più piccolo del wireframe di una quindicina di pixel: con l'immagine a
  /// misura piena il bottone "Elimina Account" finiva sotto il bordo dello
  /// schermo, e un test misura che la schermata resti intera.
  static const double diametro = 96;

  final String? avatarPath;
  final VoidCallback onChangeAvatar;

  final bool puoCambiareImmagine;

  @override
  Widget build(BuildContext context) {
    final testi = Theme.of(context).textTheme;

    return Stack(
      alignment: Alignment.bottomCenter,
      clipBehavior: Clip.none,
      children: <Widget>[
        Container(
          width: double.infinity,
          // Come nella home: la metà inferiore dell'immagine deve restare
          // dentro allo Stack, perché quello che sporge oltre i bordi di un
          // widget viene disegnato ma non riceve i tocchi.
          margin: const EdgeInsets.only(bottom: diametro / 2),
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
                diametro / 2 + VivoDimens.sm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Il tuo profilo',
                    style: testi.headlineSmall?.copyWith(
                      color: VivoColors.onHeader,
                    ),
                  ),
                  const SizedBox(height: VivoDimens.xs / 2),
                  Text(
                    'Gestisci impostazioni account',
                    style: testi.bodySmall?.copyWith(
                      color: VivoColors.onHeader.withValues(alpha: 0.72),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        _Avatar(
          path: avatarPath,
          onChange: onChangeAvatar,
          abilitato: puoCambiareImmagine,
        ),
      ],
    );
  }
}

/// L'immagine circolare del profilo con il "+" che apre la galleria.
class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.path,
    required this.onChange,
    required this.abilitato,
  });

  final String? path;
  final VoidCallback onChange;

  /// Se falso il "+" si vede ma non risponde, e non spiega perché.
  ///
  /// Toglierlo del tutto cambierebbe la forma dell'intestazione fra un ospite
  /// e chi ha un profilo; spento, resta al suo posto senza promettere niente.
  final bool abilitato;

  @override
  Widget build(BuildContext context) {
    final file = path;

    return SizedBox(
      width: _Intestazione.diametro,
      height: _Intestazione.diametro,
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          Container(
            width: _Intestazione.diametro,
            height: _Intestazione.diametro,
            // Stesso tondo dell'avatar in cima alla home: è la stessa persona,
            // e due segnaposto di colore diverso la farebbero sembrare due
            // schermate di applicazioni diverse. Il filo di bordo color sfondo
            // stacca l'immagine dal teal dell'intestazione, che le passa
            // dietro per metà.
            decoration: BoxDecoration(
              color: VivoColors.onHeader,
              shape: BoxShape.circle,
              border: Border.all(color: VivoColors.background, width: 3),
              // L'immagine sta a cavallo del bordo dell'intestazione: la metà
              // superiore si stacca da sola sul teal, quella inferiore
              // finirebbe crema su crema. L'ombra la solleva dal fondo, ed è
              // tinta con il teal come quella delle card, perché il nero sulla
              // crema ingrigisce.
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: VivoColors.header.withValues(alpha: 0.18),
                  blurRadius: 16,
                  spreadRadius: -2,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            // Il ritaglio è un ClipOval vero, non il clipBehavior della
            // decorazione: con un bordo e un'ombra addosso quello non ritaglia
            // più, e sul telefono l'immagine restava il quadrato che era,
            // appoggiata sopra il tondo crema.
            child: ClipOval(
              child: file == null
                  ? const Icon(
                      Icons.person_rounded,
                      size: 64,
                      color: VivoColors.header,
                    )
                  : Image.file(
                      File(file),
                      fit: BoxFit.cover,
                      width: _Intestazione.diametro,
                      height: _Intestazione.diametro,
                      // Il file può essere sparito, per esempio dopo un
                      // ripristino del telefono: meglio la sagoma vuota di un
                      // riquadro rotto.
                      errorBuilder: (_, _, _) => const Icon(
                        Icons.person_rounded,
                        size: 64,
                        color: VivoColors.header,
                      ),
                    ),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 4,
            child: Semantics(
              button: true,
              enabled: abilitato,
              label: 'Cambia immagine del profilo',
              child: Material(
                color: abilitato ? VivoColors.accent : VivoColors.field,
                shape: const CircleBorder(),
                child: InkWell(
                  onTap: abilitato ? onChange : null,
                  customBorder: const CircleBorder(),
                  child: Padding(
                    padding: const EdgeInsets.all(VivoDimens.xs),
                    child: Icon(
                      Icons.add_rounded,
                      size: 20,
                      color: abilitato
                          ? VivoColors.onAccent
                          : VivoColors.muted,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// La card "I tuoi dati personali".
class _CardDatiPersonali extends StatelessWidget {
  const _CardDatiPersonali({
    required this.nome,
    required this.cognome,
    required this.email,
    required this.dataNascita,
    required this.genere,
    required this.onPickDate,
    required this.onPickGender,
    required this.onSave,
  });

  final TextEditingController nome;
  final TextEditingController cognome;
  final TextEditingController email;
  final DateTime? dataNascita;
  final String? genere;
  final VoidCallback onPickDate;
  final ValueChanged<String> onPickGender;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) => VivoCard(
    padding: const EdgeInsets.all(14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const VivoCardTitle(title: 'I tuoi dati personali'),
        const SizedBox(height: 6),
        VivoTextField(
          hint: 'Nome',
          controller: nome,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 6),
        VivoTextField(
          hint: 'Cognome',
          controller: cognome,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 6),
        VivoTextField(
          hint: 'Email',
          controller: email,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          suffix: IconButton(
            onPressed: email.clear,
            icon: const Icon(
              Icons.close_rounded,
              size: 20,
              color: VivoColors.muted,
            ),
            tooltip: 'Svuota il campo',
          ),
        ),
        const SizedBox(height: VivoDimens.sm),
        // Data e genere non si scrivono: si scelgono, quindi il campo resta in
        // sola lettura e il tocco apre il selettore.
        VivoTextField(
          hint: 'Data di Nascita',
          controller: TextEditingController(
            text: dataNascita == null
                ? ''
                : DateFormat('d MMMM y', 'it').format(dataNascita!),
          ),
          readOnly: true,
          onTap: onPickDate,
          suffix: const Icon(
            Icons.calendar_today_rounded,
            size: 18,
            color: VivoColors.muted,
          ),
        ),
        const SizedBox(height: VivoDimens.sm),
        _CampoGenere(genere: genere, onPick: onPickGender),
        const SizedBox(height: VivoDimens.sm),
        Center(
          child: FilledButton(onPressed: onSave, child: const Text('Salva')),
        ),
      ],
    ),
  );
}

/// La tendina del genere.
///
/// È un [PopupMenuButton] e non un `DropdownButton` per la stessa ragione del
/// diario: il secondo costruisce anche le voci chiuse, e in un test il valore
/// mostrato non si distinguerebbe da quelli nascosti.
class _CampoGenere extends StatelessWidget {
  const _CampoGenere({required this.genere, required this.onPick});

  final String? genere;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    final testi = Theme.of(context).textTheme;
    final scelto = genere;

    return PopupMenuButton<String>(
      onSelected: onPick,
      tooltip: 'Scegli il genere',
      itemBuilder: (_) => <PopupMenuEntry<String>>[
        for (final voce in ProfileViewModel.generi)
          PopupMenuItem<String>(value: voce, child: Text(voce)),
      ],
      child: Container(
        height: VivoDimens.buttonHeight,
        padding: const EdgeInsets.symmetric(horizontal: VivoDimens.md),
        decoration: BoxDecoration(
          color: VivoColors.field,
          borderRadius: BorderRadius.circular(VivoDimens.radiusField),
          border: Border.all(color: VivoColors.line),
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Text(
                scelto ?? 'Genere',
                style: scelto == null
                    ? testi.bodyMedium?.copyWith(color: VivoColors.muted)
                    : testi.bodyMedium,
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: VivoColors.muted,
            ),
          ],
        ),
      ),
    );
  }
}

/// La card "Impostazioni".
class _CardImpostazioni extends StatelessWidget {
  const _CardImpostazioni({
    required this.viewModel,
    required this.onPickTime,
    required this.onChangePassword,
    required this.onLogout,
  });

  /// I due bottoni stanno affiancati su mezza schermata ciascuno, e con il
  /// corpo pieno "Cambia password" andava a capo: un filo più piccolo, e
  /// uguale per entrambi, li tiene su una riga sola.
  static ButtonStyle _stileBottone(BuildContext context) =>
      OutlinedButton.styleFrom(
        textStyle: Theme.of(
          context,
        ).textTheme.labelLarge?.copyWith(fontSize: 13),
        padding: const EdgeInsets.symmetric(horizontal: VivoDimens.sm),
      );

  final ProfileViewModel viewModel;
  final VoidCallback onPickTime;
  final VoidCallback onChangePassword;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final testi = Theme.of(context).textTheme;

    return VivoCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const VivoCardTitle(title: 'Impostazioni'),
          const SizedBox(height: VivoDimens.sm),
          Row(
            children: <Widget>[
              Expanded(
                child: Text('Notifiche Promemoria', style: testi.bodyMedium),
              ),
              // L'orario compare solo a promemoria acceso: da spento non
              // avrebbe niente da descrivere.
              if (viewModel.reminder.enabled)
                TextButton(
                  onPressed: onPickTime,
                  child: Text(viewModel.reminder.formattedTime),
                ),
              Switch(
                value: viewModel.reminder.enabled,
                onChanged: viewModel.setReminderEnabled.execute,
              ),
            ],
          ),
          const SizedBox(height: VivoDimens.sm),
          Row(
            children: <Widget>[
              if (!viewModel.isGuest) ...<Widget>[
                Expanded(
                  child: OutlinedButton(
                    style: _stileBottone(context),
                    onPressed: onChangePassword,
                    child: const Text('Cambia password'),
                  ),
                ),
                const SizedBox(width: VivoDimens.sm),
              ],
              Expanded(
                child: OutlinedButton(
                  style: _stileBottone(context),
                  onPressed: onLogout,
                  child: const Text('Disconnetti'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Quello che vede l'ospite al posto dei dati personali.
class _CardOspite extends StatelessWidget {
  const _CardOspite();

  @override
  Widget build(BuildContext context) => VivoCard(
    padding: const EdgeInsets.all(VivoDimens.md),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const VivoCardTitle(
          title: 'Stai usando Vivo come ospite',
          subtitle: 'Non c\'è nessun profilo da compilare',
        ),
        const SizedBox(height: VivoDimens.sm),
        Text(
          'Umori, riflessioni e sessioni vengono salvati su questo telefono '
          'anche senza account, e li ritrovi se più avanti ne crei uno.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    ),
  );
}

/// Il dialogo che chiede la password attuale e quella nuova.
class _DialogoPassword extends StatefulWidget {
  const _DialogoPassword();

  @override
  State<_DialogoPassword> createState() => _DialogoPasswordState();
}

class _DialogoPasswordState extends State<_DialogoPassword> {
  final TextEditingController _attuale = TextEditingController();
  final TextEditingController _nuova = TextEditingController();
  final TextEditingController _conferma = TextEditingController();

  @override
  void dispose() {
    _attuale.dispose();
    _nuova.dispose();
    _conferma.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Cambia password'),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          VivoTextField(
            label: 'Password attuale',
            hint: 'Password attuale',
            controller: _attuale,
            obscureText: true,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: VivoDimens.sm),
          VivoTextField(
            label: 'Nuova password',
            hint: 'Almeno 8 caratteri',
            controller: _nuova,
            obscureText: true,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: VivoDimens.sm),
          VivoTextField(
            label: 'Conferma password',
            hint: 'Riscrivi la password',
            controller: _conferma,
            obscureText: true,
            textInputAction: TextInputAction.done,
          ),
        ],
      ),
    ),
    actions: <Widget>[
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Annulla'),
      ),
      TextButton(
        onPressed: () => Navigator.of(context).pop(
          PasswordChange(
            attuale: _attuale.text,
            nuova: _nuova.text,
            conferma: _conferma.text,
          ),
        ),
        child: const Text('Salva'),
      ),
    ],
  );
}
