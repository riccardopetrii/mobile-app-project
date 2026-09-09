import 'package:sqflite/sqflite.dart';

import '../../domain/models/mood_entry.dart';
import '../../utils/dates.dart';
import '../../utils/result.dart';
import '../services/database_service.dart';
import 'storage_exception.dart';

/// Accesso alle registrazioni d'umore del mood tracker.
abstract interface class MoodRepository {
  /// L'umore registrato in un giorno, oppure `null` se non ne esiste.
  Future<Result<MoodEntry?>> moodOn(DateTime date);

  /// Gli umori registrati fra due date, estremi inclusi, in ordine di data.
  Future<Result<List<MoodEntry>>> moodsBetween(DateTime from, DateTime to);

  /// Registra l'umore di un giorno, sostituendo quello già presente.
  Future<Result<MoodEntry>> saveMood(DateTime date, Mood mood, {String? note});

  /// Cancella tutte le registrazioni, usato dall'eliminazione dell'account.
  Future<Result<void>> deleteAll();
}

/// Implementazione di [MoodRepository] sul database locale.
class LocalMoodRepository implements MoodRepository {
  LocalMoodRepository(this._database);

  static const String _table = 'mood_entries';

  final DatabaseService _database;

  @override
  Future<Result<MoodEntry?>> moodOn(DateTime date) async {
    try {
      final db = await _database.database;
      final righe = await db.query(
        _table,
        where: 'date = ?',
        whereArgs: <Object>[dateKey(date)],
        limit: 1,
      );
      if (righe.isEmpty) return const Result<MoodEntry?>.ok(null);
      return Result<MoodEntry?>.ok(MoodEntry.fromMap(righe.first));
    } on Object catch (error) {
      return Result<MoodEntry?>.error(asStorageException(error));
    }
  }

  @override
  Future<Result<List<MoodEntry>>> moodsBetween(
    DateTime from,
    DateTime to,
  ) async {
    try {
      final db = await _database.database;
      final righe = await db.query(
        _table,
        where: 'date BETWEEN ? AND ?',
        whereArgs: <Object>[dateKey(from), dateKey(to)],
        orderBy: 'date ASC',
      );
      return Result<List<MoodEntry>>.ok(
        righe.map(MoodEntry.fromMap).toList(growable: false),
      );
    } on Object catch (error) {
      return Result<List<MoodEntry>>.error(asStorageException(error));
    }
  }

  @override
  Future<Result<MoodEntry>> saveMood(
    DateTime date,
    Mood mood, {
    String? note,
  }) async {
    try {
      final db = await _database.database;
      final entry = MoodEntry(date: date, mood: mood, note: note);
      final map = entry.toMap()..remove('id');
      // La colonna `date` è unica: il conflitto sostituisce la riga del giorno.
      final id = await db.insert(
        _table,
        map,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return Result<MoodEntry>.ok(entry.copyWith(id: id));
    } on Object catch (error) {
      return Result<MoodEntry>.error(asStorageException(error));
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
