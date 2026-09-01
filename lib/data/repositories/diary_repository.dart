import 'package:sqflite/sqflite.dart';

import '../../domain/models/diary_entry.dart';
import '../../utils/dates.dart';
import '../../utils/result.dart';
import '../services/database_service.dart';
import 'storage_exception.dart';

/// Accesso alle riflessioni del diario personale.
abstract interface class DiaryRepository {
  /// La riflessione di un giorno, oppure `null` se non ne esiste.
  Future<Result<DiaryEntry?>> entryOn(DateTime date);

  /// I giorni con una riflessione fra due date, per i puntini del calendario.
  Future<Result<List<DateTime>>> datesWithEntries(DateTime from, DateTime to);

  /// Salva la riflessione di un giorno.
  ///
  /// Un testo vuoto o composto solo da spazi cancella la riflessione: la card
  /// del diario non deve conservare righe senza contenuto.
  Future<Result<DiaryEntry?>> saveReflection(DateTime date, String reflection);

  /// Cancella tutte le riflessioni, usato dall'eliminazione dell'account.
  Future<Result<void>> deleteAll();
}

/// Implementazione di [DiaryRepository] sul database locale.
class LocalDiaryRepository implements DiaryRepository {
  LocalDiaryRepository(this._database);

  static const String _table = 'diary_entries';

  final DatabaseService _database;

  @override
  Future<Result<DiaryEntry?>> entryOn(DateTime date) async {
    try {
      final db = await _database.database;
      final righe = await db.query(
        _table,
        where: 'date = ?',
        whereArgs: <Object>[dateKey(date)],
        limit: 1,
      );
      if (righe.isEmpty) return const Result<DiaryEntry?>.ok(null);
      return Result<DiaryEntry?>.ok(DiaryEntry.fromMap(righe.first));
    } on Object catch (error) {
      return Result<DiaryEntry?>.error(asStorageException(error));
    }
  }

  @override
  Future<Result<List<DateTime>>> datesWithEntries(
    DateTime from,
    DateTime to,
  ) async {
    try {
      final db = await _database.database;
      final righe = await db.query(
        _table,
        columns: <String>['date'],
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
  Future<Result<DiaryEntry?>> saveReflection(
    DateTime date,
    String reflection,
  ) async {
    try {
      final db = await _database.database;
      if (reflection.trim().isEmpty) {
        await db.delete(
          _table,
          where: 'date = ?',
          whereArgs: <Object>[dateKey(date)],
        );
        return const Result<DiaryEntry?>.ok(null);
      }

      final entry = DiaryEntry(
        date: date,
        reflection: reflection,
        updatedAt: DateTime.now(),
      );
      final id = await db.insert(
        _table,
        entry.toMap()..remove('id'),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return Result<DiaryEntry?>.ok(entry.copyWith(id: id));
    } on Object catch (error) {
      return Result<DiaryEntry?>.error(asStorageException(error));
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
