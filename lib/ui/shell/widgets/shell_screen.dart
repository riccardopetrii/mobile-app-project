import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../domain/use_cases/weekly_progress_use_case.dart';
import '../../core/ui/vivo_bottom_nav.dart';
import '../../../domain/use_cases/sos_session_use_case.dart';
import '../../diary/view_model/diary_view_model.dart';
import '../../diary/widgets/diary_screen.dart';
import '../../home/view_model/home_view_model.dart';
import '../../home/widgets/home_screen.dart';
import '../../profile/view_model/profile_view_model.dart';
import '../../profile/widgets/profile_screen.dart';
import '../../sos/widgets/sos_screen.dart';
import '../../../routing/routes.dart';

/// Il contenitore delle tre schede principali.
///
/// Tiene la barra di navigazione ferma in fondo e cambia soltanto il contenuto
/// sopra, così passare fra Home, Diario e Profilo non fa ricostruire la barra.
class ShellScreen extends StatefulWidget {
  const ShellScreen({this.initialTab = VivoTab.home, super.key});

  final VivoTab initialTab;

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  late VivoTab _corrente = widget.initialTab;
  late final HomeViewModel _home = HomeViewModel(
    users: context.read(),
    moods: context.read(),
    settings: context.read(),
    progress: WeeklyProgressUseCase(context.read()),
  );
  late final DiaryViewModel _diary = DiaryViewModel(
    moods: context.read(),
    diary: context.read(),
    requests: context.read(),
  );
  late final ProfileViewModel _profile = ProfileViewModel(
    users: context.read(),
    settings: context.read(),
    notifications: context.read(),
    avatar: context.read(),
    deleteAccount: context.read(),
  );

  @override
  void dispose() {
    _home.dispose();
    _diary.dispose();
    _profile.dispose();
    super.dispose();
  }

  void _apri(VivoTab tab) {
    setState(() => _corrente = tab);
    // L'umore si registra dalla home e le sessioni finiscono nel diario:
    // riaprendo la scheda si rilegge quello che è cambiato altrove.
    if (tab == VivoTab.diario) _diary.load.execute();
    // Nome e immagine del profilo compaiono anche in cima alla home: tornando
    // sulla home vanno riletti, o resterebbero quelli di prima della modifica.
    if (tab == VivoTab.home) _home.load.execute();
    // I dati anagrafici si cambiano solo da qui, ma l'immagine del profilo
    // compare anche nella home: riaprendo la scheda si rilegge il profilo.
    if (tab == VivoTab.profilo) _profile.load.execute();
  }

  /// Apre la sessione di aiuto completa e, al ritorno, riaggiorna la home:
  /// il conteggio dei progressi è appena cambiato.
  Future<void> _avviaSessione() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const SosScreen()),
    );
    await _home.load.execute();
    // La sessione appena conclusa compare fra le richieste di aiuto del giorno.
    await _diary.load.execute();
  }

  /// Apre un solo esercizio dalle attività consigliate.
  Future<void> _avviaEsercizio(String attivita) async {
    final esercizio = switch (attivita) {
      'breathing' => SosStep.breathing,
      'grounding' => SosStep.grounding,
      _ => null,
    };
    if (esercizio == null) return;

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SosScreen(singleExercise: esercizio),
      ),
    );
  }

  /// Riporta all'accesso dopo la disconnessione o l'eliminazione dell'account,
  /// senza lasciare le tre schede raggiungibili tornando indietro.
  void _tornaAllAccesso() => Navigator.of(
    context,
  ).pushNamedAndRemoveUntil(Routes.login, (_) => false);

  @override
  Widget build(BuildContext context) => Scaffold(
    body: IndexedStack(
      index: VivoTab.values.indexOf(_corrente),
      children: <Widget>[
        HomeScreen(
          viewModel: _home,
          onHelpRequested: _avviaSessione,
          onProfileRequested: () => _apri(VivoTab.profilo),
          onActivityRequested: _avviaEsercizio,
        ),
        DiaryScreen(viewModel: _diary),
        ProfileScreen(viewModel: _profile, onLoggedOut: _tornaAllAccesso),
      ],
    ),
    bottomNavigationBar: VivoBottomNav(
      current: _corrente,
      onSelected: _apri,
    ),
  );
}
