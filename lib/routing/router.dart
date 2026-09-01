import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../ui/auth/view_model/login_view_model.dart';
import '../ui/auth/view_model/register_view_model.dart';
import '../ui/auth/widgets/login_screen.dart';
import '../ui/auth/widgets/register_screen.dart';
import '../ui/core/ui/vivo_bottom_nav.dart';
import '../ui/shell/widgets/shell_screen.dart';
import 'routes.dart';

/// Costruisce le schermate a partire dal nome della rotta.
///
/// I ViewModel nascono qui, ricevendo i repository dal grafo delle dipendenze:
/// le schermate non vanno a cercarseli da sole e restano provabili con
/// implementazioni finte.
Route<void>? onGenerateRoute(RouteSettings settings) => switch (settings.name) {
  Routes.login => _rotta(
    settings,
    (context) => LoginScreen(
      viewModel: LoginViewModel(
        users: context.read(),
        settings: context.read(),
      ),
      onLoggedIn: () => Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(Routes.home, (_) => false),
      onRegister: () => Navigator.of(context).pushNamed(Routes.register),
    ),
  ),

  Routes.register => _rotta(
    settings,
    (context) => RegisterScreen(
      viewModel: RegisterViewModel(
        users: context.read(),
        settings: context.read(),
      ),
      onRegistered: () => Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(Routes.home, (_) => false),
      onBackToLogin: () => Navigator.of(context).pop(),
    ),
  ),

  Routes.home => _rotta(settings, (_) => const ShellScreen()),
  Routes.diary => _rotta(
    settings,
    (_) => const ShellScreen(initialTab: VivoTab.diario),
  ),
  Routes.profile => _rotta(
    settings,
    (_) => const ShellScreen(initialTab: VivoTab.profilo),
  ),

  _ => null,
};

MaterialPageRoute<void> _rotta(
  RouteSettings settings,
  WidgetBuilder builder,
) => MaterialPageRoute<void>(settings: settings, builder: builder);
