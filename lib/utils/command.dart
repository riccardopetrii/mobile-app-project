import 'package:flutter/foundation.dart';

import 'result.dart';

/// Azione asincrona senza argomenti eseguita da un ViewModel.
typedef CommandAction0<T> = Future<Result<T>> Function();

/// Azione asincrona con un argomento eseguita da un ViewModel.
typedef CommandAction1<T, A> = Future<Result<T>> Function(A argument);

/// Incapsula un'azione asincrona e il suo stato di avanzamento.
abstract class Command<T> extends ChangeNotifier {
  Command();

  bool _running = false;

  bool get running => _running;

  Result<T>? _result;

  Result<T>? get result => _result;

  bool get error => _result is Error<T>;

  bool get completed => _result is Ok<T>;

  /// Dimentica l'esito precedente, ad esempio dopo aver mostrato l'errore.
  void clearResult() {
    _result = null;
    notifyListeners();
  }

  /// Esegue [action] tenendo aggiornato lo stato del comando.
  Future<void> _execute(CommandAction0<T> action) async {
    if (_running) return;

    _running = true;
    _result = null;
    notifyListeners();

    try {
      _result = await action();
    } on Exception catch (exception) {
      _result = Result.error(exception);
    } finally {
      _running = false;
      notifyListeners();
    }
  }
}

/// Comando che esegue un'azione senza argomenti.
class Command0<T> extends Command<T> {
  Command0(this._action);

  final CommandAction0<T> _action;

  /// Esegue l'azione associata.
  Future<void> execute() => _execute(_action);
}

/// Comando che esegue un'azione con un argomento.
class Command1<T, A> extends Command<T> {
  Command1(this._action);

  final CommandAction1<T, A> _action;

  /// Esegue l'azione associata passandole [argument].
  Future<void> execute(A argument) => _execute(() => _action(argument));
}
