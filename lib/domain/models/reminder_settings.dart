/// Le impostazioni del promemoria giornaliero del diario.
///
/// Vivono in `shared_preferences`, non nel database: sono una preferenza, non
/// un contenuto creato dall'utente.
class ReminderSettings {
  ReminderSettings({
    required this.enabled,
    required this.hour,
    required this.minute,
  }) {
    if (hour < 0 || hour > 23) {
      throw ArgumentError.value(hour, 'hour', 'l\'ora deve stare fra 0 e 23');
    }
    if (minute < 0 || minute > 59) {
      throw ArgumentError.value(
        minute,
        'minute',
        'i minuti devono stare fra 0 e 59',
      );
    }
  }

  /// Il valore predefinito: promemoria spento, previsto per le 20:00.
  const ReminderSettings.initial() : enabled = false, hour = 20, minute = 0;

  /// Le impostazioni corrispondenti a un orario nel formato `HH:mm`.
  factory ReminderSettings.fromTime({
    required bool enabled,
    required String time,
  }) {
    final parti = time.split(':');
    return ReminderSettings(
      enabled: enabled,
      hour: int.parse(parti[0]),
      minute: int.parse(parti[1]),
    );
  }

  final bool enabled;

  final int hour;

  final int minute;

  String get formattedTime =>
      '${hour.toString().padLeft(2, '0')}:'
      '${minute.toString().padLeft(2, '0')}';

  /// Una copia con i soli campi indicati sostituiti.
  ReminderSettings copyWith({bool? enabled, int? hour, int? minute}) =>
      ReminderSettings(
        enabled: enabled ?? this.enabled,
        hour: hour ?? this.hour,
        minute: minute ?? this.minute,
      );

  @override
  bool operator ==(Object other) =>
      other is ReminderSettings &&
      other.enabled == enabled &&
      other.hour == hour &&
      other.minute == minute;

  @override
  int get hashCode => Object.hash(enabled, hour, minute);

  @override
  String toString() =>
      'ReminderSettings($formattedTime, ${enabled ? 'attivo' : 'spento'})';
}
