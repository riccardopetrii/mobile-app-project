import 'package:flutter/material.dart';

import '../../../domain/models/help_request.dart';
import '../../core/themes/colors.dart';
import '../../core/themes/dimens.dart';
import '../../core/ui/vivo_card.dart';
import '../../core/ui/vivo_header.dart';
import '../view_model/questionnaire_view_model.dart';
import '../../core/ui/vivo_message.dart';

/// Il questionario finale, come in `wireframes/questionario.png`.
class QuestionnaireScreen extends StatefulWidget {
  const QuestionnaireScreen({
    required this.viewModel,
    required this.onSaved,
    required this.onRestart,
    required this.onExit,
    super.key,
  });

  final QuestionnaireViewModel viewModel;

  final VoidCallback onSaved;

  final VoidCallback onRestart;

  final VoidCallback onExit;

  @override
  State<QuestionnaireScreen> createState() => _QuestionnaireScreenState();
}

class _QuestionnaireScreenState extends State<QuestionnaireScreen> {
  @override
  void initState() {
    super.initState();
    widget.viewModel.save.addListener(_alCambioStato);
  }

  @override
  void dispose() {
    widget.viewModel.save.removeListener(_alCambioStato);
    super.dispose();
  }

  void _alCambioStato() {
    if (!mounted) return;
    if (widget.viewModel.save.completed) {
      widget.onSaved();
      return;
    }
    final messaggio = widget.viewModel.errorMessage;
    if (widget.viewModel.save.error && messaggio != null) {
      mostraMessaggio(
        context,
        messaggio,
        tono: widget.viewModel.errorTone,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final testi = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        top: false,
        child: ListenableBuilder(
          listenable: widget.viewModel,
          builder: (context, _) {
            final vm = widget.viewModel;

            return Column(
              children: <Widget>[
                VivoHeader(
                  title: 'Questionario finale',
                  subtitle: 'Raccontami un po\' com\'è andata…',
                  trailing: VivoExitButton(onPressed: widget.onExit),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(VivoDimens.md),
                    child: Column(
                      children: <Widget>[
                        VivoCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              const VivoCardTitle(
                                title: 'Qual è stata l\'intensità '
                                    'dell\'attacco?',
                                subtitle: 'Usa lo slider per indicare il '
                                    'valore',
                              ),
                              const SizedBox(height: VivoDimens.sm),
                              Row(
                                children: <Widget>[
                                  const Icon(
                                    Icons.remove_rounded,
                                    size: 20,
                                    color: VivoColors.muted,
                                  ),
                                  Expanded(
                                    child: Slider(
                                      value: vm.intensity.toDouble(),
                                      min: HelpRequest.minIntensity.toDouble(),
                                      max: HelpRequest.maxIntensity.toDouble(),
                                      divisions:
                                          HelpRequest.maxIntensity -
                                          HelpRequest.minIntensity,
                                      label: '${vm.intensity}',
                                      onChanged: (valore) =>
                                          vm.setIntensity(valore.round()),
                                    ),
                                  ),
                                  const Icon(
                                    Icons.add_rounded,
                                    size: 20,
                                    color: VivoColors.muted,
                                  ),
                                ],
                              ),
                              Center(
                                child: Text(
                                  '${vm.intensity}/'
                                  '${HelpRequest.maxIntensity}',
                                  style: testi.titleMedium,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: VivoDimens.md),
                        VivoCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              const VivoCardTitle(
                                title: 'Qualcosa ti ha messo agitazione?',
                                subtitle: 'Premi una delle etichette presenti',
                              ),
                              const SizedBox(height: VivoDimens.md),
                              Wrap(
                                spacing: VivoDimens.sm,
                                runSpacing: VivoDimens.sm,
                                children: <Widget>[
                                  for (final trigger in HelpTrigger.values)
                                    _Etichetta(
                                      label: trigger.label,
                                      selected: vm.trigger == trigger,
                                      onTap: () => vm.selectTrigger(trigger),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: VivoDimens.md),
                        VivoCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              const VivoCardTitle(
                                title: 'Come ti senti adesso?',
                                subtitle: 'Premi l\'opzione che desideri',
                              ),
                              const SizedBox(height: VivoDimens.md),
                              // Centrate come il testo e il bottone che stanno
                              // sotto, che sono anche loro dentro un `Center`.
                              Center(
                                child: Wrap(
                                  spacing: VivoDimens.sm,
                                  runSpacing: VivoDimens.sm,
                                  children: <Widget>[
                                    for (final esito in HelpOutcome.values)
                                      _Etichetta(
                                        label: esito.label,
                                        selected: vm.outcome == esito,
                                        onTap: () => vm.selectOutcome(esito),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: VivoDimens.md),
                              Center(
                                child: Text(
                                  'Se invece desideri continuare…',
                                  style: testi.bodySmall,
                                ),
                              ),
                              const SizedBox(height: VivoDimens.sm),
                              Center(
                                child: _Etichetta(
                                  label: 'Avvia un\'altra sessione',
                                  selected: false,
                                  onTap: widget.onRestart,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    VivoDimens.lg,
                    VivoDimens.sm,
                    VivoDimens.lg,
                    VivoDimens.lg,
                  ),
                  child: FilledButton(
                    onPressed: vm.save.running ? null : vm.save.execute,
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text('Salva ed esci'),
                        SizedBox(width: VivoDimens.sm),
                        Icon(Icons.arrow_forward_rounded, size: 18),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Una delle etichette toccabili del questionario.
class _Etichetta extends StatelessWidget {
  const _Etichetta({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    child: Material(
      color: selected ? VivoColors.accent : VivoColors.field,
      shape: const StadiumBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: VivoDimens.md,
            vertical: VivoDimens.sm + 2,
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: selected ? VivoColors.onAccent : VivoColors.ink,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              fontSize: 14,
            ),
          ),
        ),
      ),
    ),
  );
}
