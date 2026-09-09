import 'package:flutter/material.dart';

import '../../core/themes/colors.dart';
import '../../core/themes/dimens.dart';
import '../../core/ui/vivo_card.dart';
import '../../core/ui/vivo_text_field.dart';
import '../view_model/register_view_model.dart';
import '../../core/ui/vivo_message.dart';

/// La creazione del profilo locale.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({
    required this.viewModel,
    required this.onRegistered,
    required this.onBackToLogin,
    super.key,
  });

  final RegisterViewModel viewModel;

  final VoidCallback onRegistered;

  final VoidCallback onBackToLogin;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _nome = TextEditingController();
  final TextEditingController _cognome = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _conferma = TextEditingController();
  bool _passwordNascosta = true;

  @override
  void initState() {
    super.initState();
    widget.viewModel.register.addListener(_alCambioStato);
  }

  @override
  void dispose() {
    widget.viewModel.register.removeListener(_alCambioStato);
    _nome.dispose();
    _cognome.dispose();
    _email.dispose();
    _password.dispose();
    _conferma.dispose();
    super.dispose();
  }

  void _alCambioStato() {
    if (!mounted) return;
    if (widget.viewModel.register.completed) {
      widget.onRegistered();
      return;
    }
    final messaggio = widget.viewModel.errorMessage;
    if (widget.viewModel.register.error && messaggio != null) {
      mostraMessaggio(
        context,
        messaggio,
        tono: widget.viewModel.errorTone,
      );
    }
  }

  void _invia() => widget.viewModel.register.execute(
    RegistrationData(
      nome: _nome.text,
      cognome: _cognome.text,
      email: _email.text,
      password: _password.text,
      confermaPassword: _conferma.text,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final testi = Theme.of(context).textTheme;

    return Scaffold(
      body: Column(
        children: <Widget>[
          Container(
            width: double.infinity,
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
                  VivoDimens.sm,
                  VivoDimens.sm,
                  VivoDimens.lg,
                  VivoDimens.xl,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    IconButton(
                      onPressed: widget.onBackToLogin,
                      icon: const Icon(Icons.arrow_back_rounded),
                      color: VivoColors.onHeader,
                      tooltip: 'Torna all\'accesso',
                    ),
                    const SizedBox(width: VivoDimens.xs),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const SizedBox(height: VivoDimens.sm),
                          Text(
                            'Crea il tuo profilo',
                            style: testi.headlineSmall?.copyWith(
                              color: VivoColors.onHeader,
                            ),
                          ),
                          const SizedBox(height: VivoDimens.xs / 2),
                          Text(
                            'Resta su questo telefono, solo per te',
                            style: testi.bodySmall?.copyWith(
                              color: VivoColors.onHeader.withValues(
                                alpha: 0.72,
                              ),
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
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(VivoDimens.lg),
              child: Column(
                children: <Widget>[
                  VivoCard(
                    padding: const EdgeInsets.all(VivoDimens.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        const VivoCardTitle(
                          title: 'I tuoi dati',
                          subtitle: 'Puoi cambiarli quando vuoi dal profilo',
                        ),
                        const SizedBox(height: VivoDimens.md),
                        VivoTextField(
                          label: 'Nome',
                          hint: 'Nome',
                          controller: _nome,
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: VivoDimens.md),
                        VivoTextField(
                          label: 'Cognome',
                          hint: 'Cognome',
                          controller: _cognome,
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: VivoDimens.md),
                        VivoTextField(
                          label: 'Email',
                          hint: 'Email',
                          controller: _email,
                          icon: Icons.mail_outline_rounded,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: VivoDimens.md),
                        VivoTextField(
                          label: 'Password',
                          hint: 'Almeno 8 caratteri',
                          controller: _password,
                          icon: Icons.lock_outline_rounded,
                          obscureText: _passwordNascosta,
                          textInputAction: TextInputAction.next,
                          suffix: IconButton(
                            onPressed: () => setState(
                              () => _passwordNascosta = !_passwordNascosta,
                            ),
                            icon: Icon(
                              _passwordNascosta
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              size: 20,
                              color: VivoColors.muted,
                            ),
                            tooltip: _passwordNascosta
                                ? 'Mostra la password'
                                : 'Nascondi la password',
                          ),
                        ),
                        const SizedBox(height: VivoDimens.md),
                        VivoTextField(
                          label: 'Conferma password',
                          hint: 'Riscrivi la password',
                          controller: _conferma,
                          icon: Icons.lock_outline_rounded,
                          obscureText: _passwordNascosta,
                          textInputAction: TextInputAction.done,
                        ),
                        const SizedBox(height: VivoDimens.lg),
                        Center(
                          child: ListenableBuilder(
                            listenable: widget.viewModel.register,
                            builder: (context, _) => FilledButton(
                              onPressed: widget.viewModel.register.running
                                  ? null
                                  : _invia,
                              child: const Text('Crea profilo'),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: VivoDimens.md),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      const Icon(
                        Icons.shield_outlined,
                        size: 14,
                        color: VivoColors.muted,
                      ),
                      const SizedBox(width: VivoDimens.xs + 2),
                      Flexible(
                        child: Text(
                          'Nessun dato esce da questo telefono.',
                          style: testi.bodySmall?.copyWith(fontSize: 11.5),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
