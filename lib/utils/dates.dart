/// Funzioni per convertire le date nel formato usato dal database.
///
/// Nel database le date sono stringhe `YYYY-MM-DD` e gli orari stringhe `HH:mm`:
/// sono ordinabili come testo e leggibili senza conversioni, il che semplifica
/// le query per giorno e per settimana.
library;

/// La data nel formato `YYYY-MM-DD`, senza l'orario.
String dateKey(DateTime date) {
  final mese = date.month.toString().padLeft(2, '0');
  final giorno = date.day.toString().padLeft(2, '0');
  return '${date.year}-$mese-$giorno';
}

/// La data corrispondente a una chiave `YYYY-MM-DD`, con orario a mezzanotte.
DateTime parseDateKey(String key) {
  final parti = key.split('-');
  return DateTime(
    int.parse(parti[0]),
    int.parse(parti[1]),
    int.parse(parti[2]),
  );
}

/// L'orario nel formato `HH:mm` a ventiquattro ore.
String timeKey(DateTime time) {
  final ore = time.hour.toString().padLeft(2, '0');
  final minuti = time.minute.toString().padLeft(2, '0');
  return '$ore:$minuti';
}

/// La stessa data con l'orario azzerato.
DateTime dateOnly(DateTime date) =>
    DateTime(date.year, date.month, date.day);

/// Il lunedì della settimana a cui appartiene [date], con l'orario azzerato.
///
/// La settimana va da lunedì a domenica, come nel calendario italiano.
DateTime startOfWeek(DateTime date) =>
    dateOnly(date).subtract(Duration(days: date.weekday - DateTime.monday));
