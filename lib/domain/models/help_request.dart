import '../../utils/dates.dart';

/// Le cause che l'utente può indicare nel questionario finale.
enum HelpTrigger {
  lavoro('Lavoro'),
  scuola('Scuola'),
  salute('Salute'),
  caldo('Caldo'),
  affollamento('Affollamento'),
  altro('Altro');

  const HelpTrigger(this.label);

  final String label;

  /// Il trigger corrispondente al valore salvato, oppure `null` se assente.
  static HelpTrigger? fromStorage(Object? value) {
    if (value == null) return null;
    return HelpTrigger.values.firstWhere(
      (trigger) => trigger.label == value,
      orElse: () =>
          throw ArgumentError.value(value, 'value', 'trigger sconosciuto'),
    );
  }
}

/// Come si sente l'utente al termine della sessione.
enum HelpOutcome {
  meglio('meglio', 'Mi sento meglio'),
  cosiCosi('cosi_cosi', 'Ancora così così');

  const HelpOutcome(this.storageValue, this.label);

  final String storageValue;

  final String label;

  /// L'esito corrispondente al valore salvato.
  static HelpOutcome fromStorage(String value) => HelpOutcome.values.firstWhere(
    (outcome) => outcome.storageValue == value,
    orElse: () => throw ArgumentError.value(value, 'value', 'esito sconosciuto'),
  );
}

/// Una sessione di aiuto conclusa, con quanto raccolto dal questionario finale.
///
/// È la riga della tabella "Richieste di aiuto" nel diario e l'unità contata
/// dalla card dei progressi in home.
class HelpRequest {
  HelpRequest({
    this.id,
    required this.completedAt,
    required this.intensity,
    this.trigger,
    required this.outcome,
  }) {
    if (intensity < minIntensity || intensity > maxIntensity) {
      throw ArgumentError.value(
        intensity,
        'intensity',
        'l\'intensità deve essere compresa fra '
            '$minIntensity e $maxIntensity',
      );
    }
  }

  /// Ricostruisce la richiesta da una riga di `help_requests`.
  factory HelpRequest.fromMap(Map<String, Object?> map) => HelpRequest(
    id: map['id'] as int?,
    completedAt: DateTime.parse(map['completed_at']! as String),
    intensity: map['intensity']! as int,
    trigger: HelpTrigger.fromStorage(map['trigger']),
    outcome: HelpOutcome.fromStorage(map['outcome']! as String),
  );

  static const int minIntensity = 0;

  static const int maxIntensity = 10;

  final int? id;

  final DateTime completedAt;

  final int intensity;

  final HelpTrigger? trigger;

  final HelpOutcome outcome;

  DateTime get date => dateOnly(completedAt);

  String get time => timeKey(completedAt);

  /// La riga da scrivere in `help_requests`.
  Map<String, Object?> toMap() => <String, Object?>{
    'id': id,
    'date': dateKey(completedAt),
    'time': time,
    'intensity': intensity,
    'trigger': trigger?.label,
    'outcome': outcome.storageValue,
    'completed_at': completedAt.toIso8601String(),
  };

  /// Una copia con i soli campi indicati sostituiti.
  HelpRequest copyWith({
    int? id,
    DateTime? completedAt,
    int? intensity,
    HelpTrigger? trigger,
    HelpOutcome? outcome,
  }) => HelpRequest(
    id: id ?? this.id,
    completedAt: completedAt ?? this.completedAt,
    intensity: intensity ?? this.intensity,
    trigger: trigger ?? this.trigger,
    outcome: outcome ?? this.outcome,
  );

  @override
  bool operator ==(Object other) =>
      other is HelpRequest &&
      other.id == id &&
      other.completedAt == completedAt &&
      other.intensity == intensity &&
      other.trigger == trigger &&
      other.outcome == outcome;

  @override
  int get hashCode => Object.hash(id, completedAt, intensity, trigger, outcome);

  @override
  String toString() => 'HelpRequest(${dateKey(completedAt)} $time, $intensity)';
}
