import 'package:flutter/material.dart';

import '../themes/colors.dart';

/// Il tono di un messaggio mostrato in fondo alla schermata.
enum MessageTone {
  failure,

  notice,
}

/// Mostra un messaggio in fondo alla schermata, con il tono che gli compete.
void mostraMessaggio(
  BuildContext context,
  String testo, {
  MessageTone tono = MessageTone.notice,
}) {
  final messaggero = ScaffoldMessenger.maybeOf(context);
  if (messaggero == null) return;

  final tema = Theme.of(context).snackBarTheme;
  if (tono == MessageTone.notice) {
    messaggero
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(testo)));
    return;
  }

  final raggio = (tema.shape! as RoundedRectangleBorder).borderRadius;
  messaggero
    ..clearSnackBars()
    ..showSnackBar(
      SnackBar(
        // Il testo del tema è l'inchiostro delle card: sul rosso serve il suo.
        content: Text(
          testo,
          style: tema.contentTextStyle?.copyWith(
            color: VivoColors.onDangerSurface,
          ),
        ),
        backgroundColor: VivoColors.dangerSurface,
        // Anche il bordo segue il fondo: quello teal del tema stonerebbe.
        shape: RoundedRectangleBorder(
          borderRadius: raggio,
          side: BorderSide(color: VivoColors.danger.withValues(alpha: 0.45)),
        ),
      ),
    );
}
