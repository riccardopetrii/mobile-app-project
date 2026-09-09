import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../../../data/repositories/mood_repository.dart';
import '../../../data/repositories/settings_repository.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../domain/models/mood_entry.dart';
import '../../../domain/models/user.dart';
import '../../../domain/use_cases/weekly_progress_use_case.dart';
import '../../../utils/command.dart';
import '../../../utils/result.dart';
import '../../core/ui/vivo_message.dart';

/// Lo stato della home.
///
/// Raccoglie le tre cose che la schermata mostra: chi saluta e in che giorno,
/// l'umore di oggi e quante volte è servito il pulsante di aiuto nelle ultime
/// due settimane.
class HomeViewModel extends ChangeNotifier {
  HomeViewModel({
    required UserRepository users,
    required MoodRepository moods,
    required SettingsRepository settings,
    required WeeklyProgressUseCase progress,
    DateTime Function()? now,
  }) : _users = users,
       _moods = moods,
       _settings = settings,
       _progress = progress,
       _now = now ?? DateTime.now {
    load = Command0<void>(_load);
    saveMood = Command1<void, Mood>(_saveMood);
  }

  final UserRepository _users;
  final MoodRepository _moods;
  final SettingsRepository _settings;
  final WeeklyProgressUseCase _progress;
  final DateTime Function() _now;

  late final Command0<void> load;

  late final Command1<void, Mood> saveMood;

  /// Quello che si dice all'utente quando una parte della home non si legge.
  ///
  /// È lo stesso avviso del diario: all'utente non serve sapere quale riga del
  /// database non si è potuta convertire, gli serve sapere che quello che vede
  /// è incompleto e non è colpa sua.
  static const String _erroreDiLettura =
      'Impossibile caricare i dati. Riprova.';

  static const String _erroreDiSalvataggio = 'Impossibile salvare. Riprova.';

  String? _nome;
  bool _isGuest = false;
  String? _avatarPath;
  Mood? _todayMood;
  WeeklyProgress? _weeklyProgress;
  String? _errorMessage;

  /// Il saluto in cima alla schermata, con il nome se il profilo ce l'ha.
  String get greeting {
    final nome = _nome;
    if (nome != null && nome.isNotEmpty) return 'Ciao, $nome';
    // Chi entra come ospite non ha un nome, ma un saluto monco - «Ciao» e
    // basta - sembra un profilo che non si è caricato. «Ospite» dice invece
    // com'è entrato, e la stessa parola compare nella card del profilo.
    return _isGuest ? 'Ciao, Ospite' : 'Ciao';
  }

  String get formattedDate {
    final data = DateFormat('EEEE, d MMMM', 'it').format(_now());
    return data
        .split(' ')
        .map(
          (parola) => parola.isEmpty
              ? parola
              : parola[0].toUpperCase() + parola.substring(1),
        )
        .join(' ');
  }

  /// Il percorso dell'immagine del profilo, se ne è stata scelta una.
  ///
  /// L'avatar in cima alla home mostra la stessa immagine del profilo: è la
  /// stessa persona, e due figure diverse nelle due schermate confonderebbero.
  String? get avatarPath => _avatarPath;

  Mood? get todayMood => _todayMood;

  WeeklyProgress? get progress => _weeklyProgress;

  /// Il messaggio da mostrare quando qualcosa non si è potuto leggere o
  /// salvare, oppure `null` se l'ultima operazione è andata a buon fine.
  String? get errorMessage => _errorMessage;

  /// Il tono con cui va mostrato [errorMessage].
  ///
  /// Nella home ogni messaggio racconta un guasto: qui non ci sono moduli da
  /// compilare, quindi non ci sono istruzioni da dare all'utente.
  MessageTone get errorTone => MessageTone.failure;

  /// Carica le tre parti della schermata, senza fermarsi alla prima che non
  /// riesce.
  Future<Result<void>> _load() async {
    Exception? primoErrore;

    final profilo = await _users.currentUser();
    if (profilo case final Error<User?> errore) {
      primoErrore ??= errore.error;
    }
    _nome = profilo.valueOrNull?.nome;
    _avatarPath = profilo.valueOrNull?.avatarPath;

    final ospite = await _settings.isGuest();
    if (ospite case final Error<bool> errore) {
      primoErrore ??= errore.error;
    } else {
      _isGuest = ospite.valueOrNull ?? false;
    }

    final umore = await _moods.moodOn(_now());
    if (umore case final Error<MoodEntry?> errore) {
      primoErrore ??= errore.error;
    } else {
      _todayMood = umore.valueOrNull?.mood;
    }

    final progressi = await _progress.progressAt(_now());
    if (progressi case final Error<WeeklyProgress> errore) {
      primoErrore ??= errore.error;
      // Senza numeri la card mostra il trattino: sparendo, la home cambierebbe
      // forma e lascerebbe un buco senza spiegazione.
      _weeklyProgress = null;
    } else {
      _weeklyProgress = progressi.valueOrNull;
    }

    _errorMessage = primoErrore == null ? null : _erroreDiLettura;
    notifyListeners();
    return primoErrore == null
        ? const Result<void>.ok(null)
        : Result<void>.error(primoErrore);
  }

  Future<Result<void>> _saveMood(Mood mood) async {
    final salvato = await _moods.saveMood(_now(), mood);
    if (salvato case final Error<MoodEntry> errore) {
      // Senza avviso la faccina tornava semplicemente indietro, e sembrava che
      // il tocco non fosse stato registrato.
      _errorMessage = _erroreDiSalvataggio;
      notifyListeners();
      return Result<void>.error(errore.error);
    }

    _errorMessage = null;
    _todayMood = mood;
    notifyListeners();
    return const Result<void>.ok(null);
  }
}
