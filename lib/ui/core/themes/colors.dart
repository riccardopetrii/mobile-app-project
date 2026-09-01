import 'package:flutter/material.dart';

/// I colori dell'applicazione.
abstract final class VivoColors {
  /// Il teal delle intestazioni e della barra di navigazione.
  static const Color header = Color(0xFF174A46);

  /// Il testo e le icone sopra il teal.
  static const Color onHeader = Color(0xFFF4F1EA);

  /// La crema di fondo delle schermate.
  static const Color background = Color(0xFFEFEAE1);

  /// Il bianco caldo delle card.
  ///
  /// Resta caldo per stare bene accanto alla crema, ma abbastanza chiaro da
  /// distinguersene: fra i due colori serve un divario di luminosità, altrimenti
  /// le card si confondono con il fondo.
  static const Color card = Color(0xFFFFFDF9);

  /// Il rosa cipria: pulsante di aiuto, azioni principali, elementi scelti.
  static const Color accent = Color(0xFFD8A5C5);

  /// Il testo e le icone sopra il rosa.
  static const Color onAccent = Color(0xFF46203A);

  /// Il colore del testo sul fondo crema e sulle card.
  static const Color ink = Color(0xFF1D2422);

  /// Il testo secondario: sottotitoli, etichette, note.
  static const Color muted = Color(0xFF6E7B77);

  static const Color onCard = ink;

  static const Color onCardMuted = muted;

  /// Il riempimento dei campi di testo e dei riquadri interni alle card.
  static const Color field = Color(0xFFF3F0EA);

  /// Le linee sottili: bordi dei campi, separatori delle tabelle.
  static const Color line = Color(0x1F1D2422);

  /// Il rosso usato solo per le azioni distruttive, come eliminare l'account.
  static const Color danger = Color(0xFF9E4B3F);

  /// Il fondo del messaggio che compare quando l'applicazione non riesce a
  /// fare qualcosa.
  static const Color dangerSurface = Color(0xFFF0CFC8);

  /// Il testo sopra `dangerSurface`.
  static const Color onDangerSurface = Color(0xFF5E241C);
}
