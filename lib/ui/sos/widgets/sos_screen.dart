import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../domain/use_cases/sos_session_use_case.dart';
import '../view_model/breathing_view_model.dart';
import '../view_model/grounding_view_model.dart';
import '../view_model/questionnaire_view_model.dart';
import '../view_model/sos_flow_view_model.dart';
import '../view_model/stars_view_model.dart';
import 'breathing_screen.dart';
import 'grounding_screen.dart';
import 'questionnaire_screen.dart';
import 'stars_screen.dart';
import 'transition_screen.dart';

/// La sessione di aiuto dall'inizio alla fine.
class SosScreen extends StatefulWidget {
  const SosScreen({this.singleExercise, super.key});

  /// Se valorizzato, si apre solo quell'esercizio, senza questionario: è il
  /// caso delle attività consigliate della home.
  final SosStep? singleExercise;

  @override
  State<SosScreen> createState() => _SosScreenState();
}

class _SosScreenState extends State<SosScreen> {
  late final SosFlowViewModel _flow = widget.singleExercise == null
      ? SosFlowViewModel()
      : SosFlowViewModel.singleExercise(widget.singleExercise!);

  /// Il questionario nasce solo quando si arriva davvero in fondo.
  QuestionnaireViewModel? _questionario;
  BreathingViewModel? _respiro;
  StarsViewModel? _stelle;
  GroundingViewModel? _grounding;

  QuestionnaireViewModel get _questionarioCorrente =>
      _questionario ??= QuestionnaireViewModel(
        session: context.read<SosSessionUseCase>(),
      );

  @override
  void dispose() {
    _flow.dispose();
    _questionario?.dispose();
    _respiro?.dispose();
    _stelle?.dispose();
    _grounding?.dispose();
    super.dispose();
  }

  void _esci() => Navigator.of(context).pop();

  void _avanti() {
    _flow.next();
    if (_flow.stage == SosStage.done) _esci();
  }

  void _ricomincia() {
    setState(() {
      _respiro?.dispose();
      _stelle?.dispose();
      _grounding?.dispose();
      _respiro = null;
      _stelle = null;
      _grounding = null;
      _questionario?.dispose();
      _questionario = null;
      _flow.restart();
    });
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    onPopInvokedWithResult: (uscito, _) {
      if (!uscito) _confermaUscita();
    },
    child: ListenableBuilder(
      listenable: _flow,
      builder: (context, _) => switch (_flow.stage) {
        SosStage.transition => TransitionScreen(onDone: _avanti),
        SosStage.exercise => _esercizio(),
        SosStage.questionnaire => QuestionnaireScreen(
          viewModel: _questionarioCorrente,
          onSaved: _esci,
          onRestart: _ricomincia,
          onExit: _confermaUscita,
        ),
        SosStage.done => const SizedBox.shrink(),
      },
    ),
  );

  Widget _esercizio() => switch (_flow.step!) {
    SosStep.breathing => BreathingScreen(
      viewModel: _respiro ??= BreathingViewModel(),
      showsProgress: _flow.showsProgress,
      onNext: _avanti,
      onExit: _confermaUscita,
    ),
    SosStep.stars => StarsScreen(
      viewModel: _stelle ??= StarsViewModel(),
      showsProgress: _flow.showsProgress,
      onNext: _avanti,
      onExit: _confermaUscita,
    ),
    SosStep.grounding => GroundingScreen(
      viewModel: _grounding ??= GroundingViewModel(),
      showsProgress: _flow.showsProgress,
      onNext: _avanti,
      onExit: _confermaUscita,
    ),
  };

  /// Chiede conferma prima di abbandonare l'esercizio.
  Future<void> _confermaUscita() async {
    final singolo = _flow.isSingleExercise;
    final conferma = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          singolo ? "Vuoi uscire dall'esercizio?" : 'Vuoi interrompere?',
        ),
        content: Text(
          singolo
              ? 'Puoi ricominciarlo quando vuoi.'
              : 'Se esci adesso questa sessione non viene registrata nel '
                    'diario. Puoi sempre ricominciare quando vuoi.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Resto qui'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Esci'),
          ),
        ],
      ),
    );

    if (conferma == true && mounted) _esci();
  }
}
