import '../../utils/dates.dart';

/// La riflessione scritta dall'utente in un giorno.
///
/// Esiste al massimo una riflessione per giorno: la card del diario la
/// sovrascrive a ogni salvataggio e mostra l'orario dell'ultimo aggiornamento.
class DiaryEntry {
  DiaryEntry({
    this.id,
    required DateTime date,
    required this.reflection,
    required this.updatedAt,
  }) : date = dateOnly(date);

  /// Ricostruisce la riflessione da una riga di `diary_entries`.
  factory DiaryEntry.fromMap(Map<String, Object?> map) => DiaryEntry(
    id: map['id'] as int?,
    date: parseDateKey(map['date']! as String),
    reflection: map['reflection']! as String,
    updatedAt: DateTime.parse(map['updated_at']! as String),
  );

  final int? id;

  final DateTime date;

  final String reflection;

  final DateTime updatedAt;

  bool get isEmpty => reflection.trim().isEmpty;

  /// La riga da scrivere in `diary_entries`.
  Map<String, Object?> toMap() => <String, Object?>{
    'id': id,
    'date': dateKey(date),
    'reflection': reflection,
    'updated_at': updatedAt.toIso8601String(),
  };

  /// Una copia con i soli campi indicati sostituiti.
  DiaryEntry copyWith({
    int? id,
    DateTime? date,
    String? reflection,
    DateTime? updatedAt,
  }) => DiaryEntry(
    id: id ?? this.id,
    date: date ?? this.date,
    reflection: reflection ?? this.reflection,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  @override
  bool operator ==(Object other) =>
      other is DiaryEntry &&
      other.id == id &&
      other.date == date &&
      other.reflection == reflection &&
      other.updatedAt == updatedAt;

  @override
  int get hashCode => Object.hash(id, date, reflection, updatedAt);

  @override
  String toString() => 'DiaryEntry(${dateKey(date)})';
}
