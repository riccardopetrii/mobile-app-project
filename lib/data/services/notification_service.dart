import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../domain/models/reminder_settings.dart';

/// Programma il promemoria giornaliero del diario.
///
/// È l'unico punto che parla con il sistema di notifiche: il resto
/// dell'applicazione conosce solo [ReminderSettings] e chiede a [syncWith] di
/// allineare il sistema a quelle impostazioni.
class NotificationService {
  NotificationService({
    FlutterLocalNotificationsPlugin? plugin,
    DateTime Function()? now,
    Future<String> Function()? timezoneName,
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin(),
       _now = now ?? DateTime.now,
       _timezoneName = timezoneName ?? _fusoDelTelefono;

  /// Il nome del fuso orario del telefono, nella forma `Europe/Rome`.
  static Future<String> _fusoDelTelefono() async =>
      (await FlutterTimezone.getLocalTimezone()).identifier;

  /// Identificativo del promemoria giornaliero: essendo unico, riprogrammarlo
  /// sostituisce sempre quello precedente.
  static const int dailyReminderId = 1;

  static const String _channelId = 'vivo_promemoria';
  static const String _channelName = 'Promemoria diario';
  static const String _channelDescription =
      'Ricorda di registrare umore e riflessione del giorno.';

  /// Il codice con cui il sistema dice che le sveglie esatte non sono
  /// concesse a questa applicazione.
  static const String _sveglieEsatteNegate = 'exact_alarms_not_permitted';

  final FlutterLocalNotificationsPlugin _plugin;
  final DateTime Function() _now;
  final Future<String> Function() _timezoneName;

  /// Prepara il sistema di notifiche e i fusi orari.
  ///
  /// Va chiamato una sola volta all'avvio, prima di programmare qualsiasi
  /// promemoria.
  Future<void> init() async {
    tz_data.initializeTimeZones();
    await _impostaFusoLocale();
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
  }

  /// Chiede il permesso di mostrare notifiche.
  ///
  /// Restituisce `false` se l'utente lo nega: in quel caso l'interruttore del
  /// profilo deve tornare su "spento".
  Future<bool> requestPermission() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      return await android?.requestNotificationsPermission() ?? false;
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final ios = _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      return await ios?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }
    return false;
  }

  /// Allinea il sistema alle impostazioni: programma il promemoria se è attivo,
  /// altrimenti cancella quello esistente.
  Future<bool> syncWith(ReminderSettings settings) async {
    if (!settings.enabled) {
      await cancelDailyReminder();
      return true;
    }
    return scheduleDailyReminder(settings);
  }

  /// Dice al pacchetto delle notifiche in che fuso orario vive il telefono.
  Future<void> _impostaFusoLocale() async {
    try {
      tz.setLocalLocation(tz.getLocation(await _timezoneName()));
    } on Object {
      return;
    }
  }

  /// Chiede il permesso di programmare sveglie esatte.
  Future<bool> requestExactAlarmPermission() async {
    if (defaultTargetPlatform != TargetPlatform.android) return true;
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    return await android?.requestExactAlarmsPermission() ?? false;
  }

  /// Programma il promemoria giornaliero all'orario indicato.
  Future<bool> scheduleDailyReminder(ReminderSettings settings) async {
    await cancelDailyReminder();
    try {
      await _programma(settings, AndroidScheduleMode.exactAllowWhileIdle);
      return true;
    } on PlatformException catch (errore) {
      if (errore.code != _sveglieEsatteNegate) rethrow;
      await _programma(settings, AndroidScheduleMode.inexactAllowWhileIdle);
      return false;
    }
  }

  Future<void> _programma(
    ReminderSettings settings,
    AndroidScheduleMode modo,
  ) => _plugin.zonedSchedule(
    id: dailyReminderId,
    scheduledDate: _nextInstance(settings.hour, settings.minute),
    notificationDetails: const NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
      ),
      iOS: DarwinNotificationDetails(),
    ),
    androidScheduleMode: modo,
    title: 'Come è andata oggi?',
    body: 'Prenditi un momento per registrare il tuo umore e i tuoi pensieri.',
    // Ripete la notifica ogni giorno alla stessa ora.
    matchDateTimeComponents: DateTimeComponents.time,
  );

  Future<void> cancelDailyReminder() => _plugin.cancel(id: dailyReminderId);

  /// La prima occorrenza dell'orario indicato a partire da adesso.
  ///
  /// Se l'ora di oggi è già passata il promemoria parte da domani, altrimenti
  /// suonerebbe subito.
  tz.TZDateTime _nextInstance(int hour, int minute) {
    final adesso = tz.TZDateTime.from(_now(), tz.local);
    var quando = tz.TZDateTime(
      tz.local,
      adesso.year,
      adesso.month,
      adesso.day,
      hour,
      minute,
    );
    if (!quando.isAfter(adesso)) {
      quando = quando.add(const Duration(days: 1));
    }
    return quando;
  }
}
