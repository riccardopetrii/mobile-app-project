import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../../../data/repositories/diary_repository.dart';
import '../../../data/repositories/help_request_repository.dart';
import '../../../data/repositories/mood_repository.dart';
import '../../../data/repositories/storage_exception.dart';
import '../../../domain/models/diary_entry.dart';
import '../../../domain/models/help_request.dart';
import '../../../domain/models/mood_entry.dart';
import '../../../utils/command.dart';
import '../../../utils/dates.dart';
import '../../../utils/result.dart';
import '../../core/ui/vivo_message.dart';

/// Una casella del calendario del diario.
///
/// La griglia mostra anche la coda del mese precedente e la testa di quello
/// successivo, come nel wireframe: [isCurrentMonth] distingue le due cose.
class DiaryDay {
  const DiaryDay({
    required this.date,
    required this.isCurrentMonth,
    required this.hasContent,
    required this.isFuture,
  });

  final DateTime date;

  final bool isCurrentMonth;

  /// Vero se quel giorno ha un umore, una riflessione o una richiesta di
  /// aiuto: è il puntino sotto al numero.
  final bool hasContent;

  final bool isFuture;
}

/// Lo stato del diario: il mese sfogliato e il contenuto del giorno scelto.
class DiaryViewModel extends ChangeNotifier {
  DiaryViewModel({
    required MoodRepository moods,
    required DiaryRepository diary,
    required HelpRequestRepository requests,
    DateTime Function()? now,
  }) : _moods = moods,
       _diary = diary,
       _requests = requests,
       _now = now ?? DateTime.now {
    _selectedDate = dateOnly(_now());
    _visibleMonth = DateTime(_selectedDate.year, _selectedDate.month);
    load = Command0<void>(_load);
    saveReflection = Command1<void, String>(_saveReflection);
  }

  static const int _yearsBack = 5;

  static const String _erroreDiLettura =
      'Impossibile caricare i dati di questo giorno.';

  static const String _erroreDiSalvataggio =
      'Impossibile salvare la riflessione. Riprova.';

  static const List<String> _weekdayLabels = <String>[
    'Lu',
    'Ma',
    'Me',
    'Gi',
    'Ve',
    'Sa',
    'Do',
  ];

  final MoodRepository _moods;
  final DiaryRepository _diary;
  final HelpRequestRepository _requests;
  final DateTime Function() _now;

  late final Command0<void> load;

  late final Command1<void, String> saveReflection;

  late DateTime _selectedDate;
  late DateTime _visibleMonth;
  Set<String> _daysWithContent = <String>{};
  Mood? _mood;
  String? _errorMessage;
  List<HelpRequest> _requestsOfDay = <HelpRequest>[];
  DiaryEntry? _entry;

  /// Il numero di serie della scelta corrente.
  int _selezione = 0;

  DateTime get selectedDate => _selectedDate;

  /// Il messaggio da mostrare quando qualcosa non si è potuto leggere, oppure
  /// `null` se l'ultimo caricamento è andato a buon fine.
  String? get errorMessage => _errorMessage;

  /// Il tono con cui va mostrato [errorMessage].
  ///
  /// Nel diario ogni messaggio racconta un guasto: non ci sono moduli da
  /// compilare, quindi non ci sono istruzioni da dare all'utente.
  MessageTone get errorTone => MessageTone.failure;

  DateTime get visibleMonth => _visibleMonth;

  List<String> get weekdayLabels => _weekdayLabels;

  List<String> get monthLabels => List<String>.generate(
    12,
    (indice) => _capitalizza(
      DateFormat('MMM', 'it').format(DateTime(2000, indice + 1)),
    ),
  );

  List<int> get years {
    final corrente = _now().year;
    return List<int>.generate(
      _yearsBack + 1,
      (indice) => corrente - _yearsBack + indice,
    );
  }

  List<DiaryDay> get calendarDays {
    final oggi = dateOnly(_now());
    final primo = _visibleMonth;
    final inizio = primo.subtract(Duration(days: primo.weekday - 1));
    final ultimo = DateTime(primo.year, primo.month + 1, 0);
    final giorniCoperti = ultimo.difference(inizio).inDays + 1;
    final celle = (giorniCoperti / 7).ceil() * 7;

    return List<DiaryDay>.generate(celle, (indice) {
      final giorno = DateTime(inizio.year, inizio.month, inizio.day + indice);
      return DiaryDay(
        date: giorno,
        isCurrentMonth: giorno.month == primo.month && giorno.year == primo.year,
        hasContent: _daysWithContent.contains(dateKey(giorno)),
        isFuture: giorno.isAfter(oggi),
      );
    });
  }

  String get selectedDateLabel {
    final data = _capitalizzaParole(
      DateFormat('d MMMM yyyy', 'it').format(_selectedDate),
    );
    if (_selectedDate == dateOnly(_now())) return 'Oggi, $data';
    final giorno = _capitalizza(
      DateFormat('EEEE', 'it').format(_selectedDate),
    );
    return '$giorno, $data';
  }

  Mood? get mood => _mood;

  List<HelpRequest> get requestsOfDay => _requestsOfDay;

  String get reflection => _entry?.reflection ?? '';

  String? get lastSavedLabel {
    final entry = _entry;
    if (entry == null) return null;
    return 'salvato alle ${timeKey(entry.updatedAt)}';
  }

  bool get canEditReflection => !_selectedDate.isAfter(dateOnly(_now()));

  /// Sceglie un giorno del calendario e ne carica il contenuto.
  Future<void> selectDay(DateTime date) async {
    final mia = ++_selezione;
    _selectedDate = dateOnly(date);
    final esito = await _eseguito(_loadSelectedDay);
    // Un tocco più recente ha già preso il posto di questo: la sua risposta è
    // vecchia e non deve riscrivere né il contenuto né il messaggio.
    if (mia != _selezione) return;
    _errorMessage = esito is Error<void> ? _erroreDiLettura : null;
    notifyListeners();
  }

  Future<void> showPreviousMonth() =>
      showMonth(year: _visibleMonth.year, month: _visibleMonth.month - 1);

  Future<void> showNextMonth() =>
      showMonth(year: _visibleMonth.year, month: _visibleMonth.month + 1);

  /// Mostra il mese scelto dalle tendine, senza cambiare il giorno scelto.
  Future<void> showMonth({required int year, required int month}) async {
    _visibleMonth = DateTime(year, month);
    await _protetto(_loadMonth);
    notifyListeners();
  }

  Future<Result<void>> _load() async {
    final mese = await _protetto(_loadMonth);
    if (mese case final Error<void> errore) {
      notifyListeners();
      return Result<void>.error(errore.error);
    }

    final giorno = await _protetto(_loadSelectedDay);
    notifyListeners();
    return giorno;
  }

  Future<Result<void>> _saveReflection(String testo) async {
    if (!canEditReflection) return const Result<void>.ok(null);

    final salvata = await _diary.saveReflection(_selectedDate, testo);
    if (salvata case final Error<DiaryEntry?> errore) {
      // Senza messaggio la riflessione spariva in silenzio e sembrava salvata.
      _errorMessage = _erroreDiSalvataggio;
      notifyListeners();
      return Result<void>.error(errore.error);
    }

    _entry = salvata.valueOrNull;
    // Il puntino del giorno si accende o si spegne insieme alla riflessione.
    await _protetto(_loadMonth);
    notifyListeners();
    return const Result<void>.ok(null);
  }

  /// Esegue un caricamento senza lasciare che un guasto interrompa il lavoro
  /// di chi ha chiamato.
  Future<Result<void>> _protetto(
    Future<Result<void>> Function() caricamento,
  ) async {
    final esito = await _eseguito(caricamento);
    _errorMessage = esito is Error<void> ? _erroreDiLettura : null;
    return esito;
  }

  /// Esegue un caricamento riportando il guasto come `Result.error`, senza
  /// toccare il messaggio mostrato all'utente.
  Future<Result<void>> _eseguito(
    Future<Result<void>> Function() caricamento,
  ) async {
    try {
      return await caricamento();
    } on Object catch (error) {
      return Result<void>.error(asStorageException(error));
    }
  }

  /// Rilegge i giorni con contenuti dell'intera griglia visualizzata.
  Future<Result<void>> _loadMonth() async {
    final primo = _visibleMonth;
    final inizio = primo.subtract(Duration(days: primo.weekday - 1));
    final ultimo = DateTime(primo.year, primo.month + 1, 0);
    final fine = ultimo.add(Duration(days: 7 - ultimo.weekday));

    final umori = await _moods.moodsBetween(inizio, fine);
    if (umori case final Error<List<MoodEntry>> errore) {
      return Result<void>.error(errore.error);
    }

    final riflessioni = await _diary.datesWithEntries(inizio, fine);
    if (riflessioni case final Error<List<DateTime>> errore) {
      return Result<void>.error(errore.error);
    }

    final sessioni = await _requests.datesWithRequests(inizio, fine);
    if (sessioni case final Error<List<DateTime>> errore) {
      return Result<void>.error(errore.error);
    }

    _daysWithContent = <String>{
      ...umori.valueOrNull!.map((umore) => dateKey(umore.date)),
      ...riflessioni.valueOrNull!.map(dateKey),
      ...sessioni.valueOrNull!.map(dateKey),
    };
    return const Result<void>.ok(null);
  }

  /// Rilegge umore, sessioni e riflessione del giorno scelto.
  Future<Result<void>> _loadSelectedDay() async {
    final giorno = _selectedDate;
    final mia = _selezione;

    final umore = await _moods.moodOn(giorno);
    if (umore case final Error<MoodEntry?> errore) {
      return Result<void>.error(errore.error);
    }

    final sessioni = await _requests.requestsOn(giorno);
    if (sessioni case final Error<List<HelpRequest>> errore) {
      return Result<void>.error(errore.error);
    }

    final riflessione = await _diary.entryOn(giorno);
    if (riflessione case final Error<DiaryEntry?> errore) {
      return Result<void>.error(errore.error);
    }

    if (mia != _selezione) return const Result<void>.ok(null);
    _mood = umore.valueOrNull?.mood;
    _requestsOfDay = sessioni.valueOrNull!;
    _entry = riflessione.valueOrNull;

    return const Result<void>.ok(null);
  }

  String _capitalizza(String parola) => parola.isEmpty
      ? parola
      : parola[0].toUpperCase() + parola.substring(1);

  String _capitalizzaParole(String frase) =>
      frase.split(' ').map(_capitalizza).join(' ');
}
