import '../../utils/dates.dart';

/// I cinque livelli d'umore del mood tracker, dal più basso al più alto.
enum Mood {
  triste(1, 'Triste'),
  pocoBene(2, 'Poco bene'),
  cosiCosi(3, 'Così Così'),
  bene(4, 'Bene'),
  felice(5, 'Felice');

  const Mood(this.value, this.label);

  final int value;

  final String label;

  /// Il livello corrispondente a [value].
  static Mood fromValue(int value) => Mood.values.firstWhere(
    (mood) => mood.value == value,
    orElse: () => throw ArgumentError.value(value, 'value', 'umore sconosciuto'),
  );
}

/// L'umore registrato dall'utente in un giorno.
///
/// Esiste al massimo una registrazione per giorno: toccare una faccina diversa
/// sostituisce quella precedente.
class MoodEntry {
  MoodEntry({this.id, required DateTime date, required this.mood, this.note})
    : date = dateOnly(date);

  /// Ricostruisce la registrazione da una riga di `mood_entries`.
  factory MoodEntry.fromMap(Map<String, Object?> map) => MoodEntry(
    id: map['id'] as int?,
    date: parseDateKey(map['date']! as String),
    mood: Mood.fromValue(map['value']! as int),
    note: map['note'] as String?,
  );

  final int? id;

  final DateTime date;

  final Mood mood;

  final String? note;

  /// La riga da scrivere in `mood_entries`.
  Map<String, Object?> toMap() => <String, Object?>{
    'id': id,
    'date': dateKey(date),
    'value': mood.value,
    'note': note,
  };

  /// Una copia con i soli campi indicati sostituiti.
  MoodEntry copyWith({int? id, DateTime? date, Mood? mood, String? note}) =>
      MoodEntry(
        id: id ?? this.id,
        date: date ?? this.date,
        mood: mood ?? this.mood,
        note: note ?? this.note,
      );

  @override
  bool operator ==(Object other) =>
      other is MoodEntry &&
      other.id == id &&
      other.date == date &&
      other.mood == mood &&
      other.note == note;

  @override
  int get hashCode => Object.hash(id, date, mood, note);

  @override
  String toString() => 'MoodEntry(${dateKey(date)}, ${mood.label})';
}
