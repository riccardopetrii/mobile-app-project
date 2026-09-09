import 'package:flutter/material.dart';

import '../../core/themes/colors.dart';
import '../../core/themes/dimens.dart';
import '../../core/ui/vivo_card.dart';
import '../../core/ui/vivo_text_field.dart';
import '../view_model/login_view_model.dart';
import '../../core/ui/vivo_message.dart';

/// La schermata di accesso, come in `wireframes/login.png`.
///
/// Sotto il marchio c'è la card con i campi, il bottone "Accedi" e l'accesso
/// come ospite; in fondo la barra teal con l'invito a registrarsi.
class LoginScreen extends StatefulWidget {
  const LoginScreen({
    required this.viewModel,
    required this.onLoggedIn,
    required this.onRegister,
    super.key,
  });

  final LoginViewModel viewModel;

  final VoidCallback onLoggedIn;

  final VoidCallback onRegister;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  bool _passwordNascosta = true;

  @override
  void initState() {
    super.initState();
    widget.viewModel.login.addListener(_alCambioStato);
    widget.viewModel.continueAsGuest.addListener(_alCambioStato);
  }

  @override
  void dispose() {
    widget.viewModel.login.removeListener(_alCambioStato);
    widget.viewModel.continueAsGuest.removeListener(_alCambioStato);
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _alCambioStato() {
    if (!mounted) return;
    if (widget.viewModel.login.completed ||
        widget.viewModel.continueAsGuest.completed) {
      widget.onLoggedIn();
      return;
    }
    final messaggio = widget.viewModel.errorMessage;
    if (widget.viewModel.login.error && messaggio != null) {
      mostraMessaggio(
        context,
        messaggio,
        tono: widget.viewModel.errorTone,
      );
    }
  }

  void _accedi() {
    widget.viewModel.login.execute(
      Credentials(email: _email.text, password: _password.text),
    );
  }

  void _mostraRecuperoPassword() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Password dimenticata?'),
        content: const Text(
          'I tuoi dati vivono solo su questo telefono, quindi non c\'è nessun '
          'account da recuperare. Puoi impostare una nuova password dal tuo '
          'profilo: le tue riflessioni restano dove sono.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Ho capito'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final testi = Theme.of(context).textTheme;

    return Scaffold(
      body: Column(
        children: <Widget>[
          _Marchio(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                VivoDimens.lg,
                VivoDimens.xl,
                VivoDimens.lg,
                VivoDimens.md,
              ),
              child: Column(
                children: <Widget>[
                  VivoCard(
                    padding: const EdgeInsets.all(VivoDimens.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        const VivoCardTitle(
                          title: 'Bentornato',
                          subtitle: 'Accedi al tuo account per continuare',
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
                          hint: 'Password',
                          controller: _password,
                          icon: Icons.lock_outline_rounded,
                          obscureText: _passwordNascosta,
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
                        const SizedBox(height: VivoDimens.lg),
                        Center(
                          child: ListenableBuilder(
                            listenable: widget.viewModel.login,
                            builder: (context, _) => FilledButton(
                              onPressed: widget.viewModel.login.running
                                  ? null
                                  : _accedi,
                              child: widget.viewModel.login.running
                                  ? const SizedBox.square(
                                      dimension: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: VivoColors.onAccent,
                                      ),
                                    )
                                  : const Text('Accedi'),
                            ),
                          ),
                        ),
                        const SizedBox(height: VivoDimens.md),
                        Text(
                          'oppure',
                          textAlign: TextAlign.center,
                          style: testi.bodySmall,
                        ),
                        const SizedBox(height: VivoDimens.sm),
                        Center(
                          child: OutlinedButton(
                            onPressed: widget.viewModel.continueAsGuest.execute,
                            child: const Text('Continua come ospite'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: VivoDimens.md),
                  TextButton(
                    onPressed: _mostraRecuperoPassword,
                    child: Text(
                      'Password dimenticata?',
                      style: testi.bodyMedium?.copyWith(
                        color: VivoColors.muted,
                      ),
                    ),
                  ),
                  const SizedBox(height: VivoDimens.sm),
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
                          'I tuoi dati e le tue riflessioni restano privati e '
                          'protetti.',
                          style: testi.bodySmall?.copyWith(fontSize: 11.5),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          _BarraRegistrazione(onRegister: widget.onRegister),
        ],
      ),
    );
  }
}

/// Il pannello teal con il nome dell'applicazione.
class _Marchio extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
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
        padding: const EdgeInsets.symmetric(vertical: 44),
        child: Text(
          'VIVO',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
            color: VivoColors.onHeader,
            fontSize: 38,
            fontWeight: FontWeight.w300,
            letterSpacing: 13,
          ),
        ),
      ),
    ),
  );
}

/// La barra in fondo con l'invito a creare un profilo.
class _BarraRegistrazione extends StatelessWidget {
  const _BarraRegistrazione({required this.onRegister});

  final VoidCallback onRegister;

  @override
  Widget build(BuildContext context) {
    final testi = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: VivoColors.header,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(VivoDimens.radiusPanel),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: VivoDimens.md,
            vertical: VivoDimens.lg,
          ),
          // Wrap invece di Row: su schermi stretti, o con il testo di sistema
          // ingrandito, la frase va a capo anziché sforare.
          child: Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              Text(
                'Non hai un account? ',
                style: testi.bodyMedium?.copyWith(
                  color: VivoColors.onHeader.withValues(alpha: 0.85),
                ),
              ),
              GestureDetector(
                onTap: onRegister,
                child: Text(
                  'Registrati',
                  style: testi.bodyMedium?.copyWith(
                    color: VivoColors.onHeader,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
