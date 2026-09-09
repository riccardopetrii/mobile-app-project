import '../../domain/models/help_request.dart';
import '../../utils/dates.dart';
import '../../utils/result.dart';
import '../services/database_service.dart';
import 'storage_exception.dart';

/// Accesso alle sessioni di aiuto concluse.
abstract interface class HelpRequestRepository {
  /// Le sessioni concluse in un giorno, in ordine di orario.
  Future<Result<List<HelpRequest>>> requestsOn(DateTime date);

  /// Quante sessioni sono state concluse fra due date, estremi inclusi.
  Future<Result<int>> countBetween(DateTime from, DateTime to);

  /// I giorni con almeno una sessione, per i puntini del calendario.
  Future<Result<List<DateTime>>> datesWithRequests(DateTime from, DateTime to);

  /// Salva una sessione conclusa, restituendola con l'identificativo assegnato.
  Future<Result<HelpRequest>> add(HelpRequest request);

  /// Cancella tutte le sessioni, usato dall'eliminazione dell'account.
  Future<Result<void>> deleteAll();
}

/// Implementazione di [HelpRequestRepository] sul database locale.
class LocalHelpRequestRepository implements HelpRequestRepository {
  LocalHelpRequestRepository(this._database);

  static const String _table = 'help_requests';

  final DatabaseService _database;

  @override
  Future<Result<List<HelpRequest>>> requestsOn(DateTime date) async {
    try {
      final db = await _database.database;
      final righe = await db.query(
        _table,
        where: 'date = ?',
        whereArgs: <Object>[dateKey(date)],
        orderBy: 'time ASC, id ASC',
      );
      return Result<List<HelpRequest>>.ok(
        righe.map(HelpRequest.fromMap).toList(growable: false),
      );
    } on Object catch (error) {
      return Result<List<HelpRequest>>.error(asStorageException(error));
    }
  }

  @override
  Future<Result<int>> countBetween(DateTime from, DateTime to) async {
    try {
      final db = await _database.database;
      final righe = await db.rawQuery(
        'SELECT COUNT(*) AS totale FROM $_table WHERE date BETWEEN ? AND ?',
        <Object>[dateKey(from), dateKey(to)],
      );
      return Result<int>.ok(righe.first['totale']! as int);
    } on Object catch (error) {
      return Result<int>.error(asStorageException(error));
    }
  }

  @override
  Future<Result<List<DateTime>>> datesWithRequests(
    DateTime from,
    DateTime to,
  ) async {
    try {
      final db = await _database.database;
      final righe = await db.query(
        _table,
        columns: <String>['date'],
        distinct: true,
        where: 'date BETWEEN ? AND ?',
        whereArgs: <Object>[dateKey(from), dateKey(to)],
        orderBy: 'date ASC',
      );
      return Result<List<DateTime>>.ok(
        righe
            .map((riga) => parseDateKey(riga['date']! as String))
            .toList(growable: false),
      );
    } on Object catch (error) {
      return Result<List<DateTime>>.error(asStorageException(error));
    }
  }

  @override
  Future<Result<HelpRequest>> add(HelpRequest request) async {
    try {
      final db = await _database.database;
      final id = await db.insert(_table, request.toMap()..remove('id'));
      return Result<HelpRequest>.ok(request.copyWith(id: id));
    } on Object catch (error) {
      return Result<HelpRequest>.error(asStorageException(error));
    }
  }

  @override
  Future<Result<void>> deleteAll() async {
    try {
      final db = await _database.database;
      await db.delete(_table);
      return const Result<void>.ok(null);
    } on Object catch (error) {
      return Result<void>.error(asStorageException(error));
    }
  }
}
