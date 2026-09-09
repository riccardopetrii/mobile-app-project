import 'package:sqflite/sqflite.dart';

import '../../domain/models/user.dart';
import '../../utils/result.dart';
import '../services/database_service.dart';
import 'storage_exception.dart';

/// Accesso all'unico profilo salvato sul dispositivo.
abstract interface class UserRepository {
  /// Il profilo salvato, oppure `null` se non ne esiste ancora uno.
  Future<Result<User?>> currentUser();

  /// Vero se esiste già un profilo: la schermata di accesso lo usa per capire
  /// se proporre l'accesso o la registrazione.
  Future<Result<bool>> hasUser();

  /// Crea o aggiorna il profilo.
  Future<Result<User>> save(User user);

  /// Cancella il profilo, usato dall'eliminazione dell'account.
  Future<Result<void>> deleteAll();
}

/// Implementazione di [UserRepository] sul database locale.
class LocalUserRepository implements UserRepository {
  LocalUserRepository(this._database);

  static const String _table = 'users';

  final DatabaseService _database;

  @override
  Future<Result<User?>> currentUser() async {
    try {
      final db = await _database.database;
      final righe = await db.query(
        _table,
        where: 'id = ?',
        whereArgs: <Object>[User.singleId],
        limit: 1,
      );
      if (righe.isEmpty) return const Result<User?>.ok(null);
      return Result<User?>.ok(User.fromMap(righe.first));
    } on Object catch (error) {
      return Result<User?>.error(asStorageException(error));
    }
  }

  @override
  Future<Result<bool>> hasUser() async {
    final result = await currentUser();
    return result.fold(
      onOk: (user) => Result<bool>.ok(user != null),
      onError: Result<bool>.error,
    );
  }

  @override
  Future<Result<User>> save(User user) async {
    try {
      final db = await _database.database;
      // L'identificativo è fisso: il conflitto sostituisce l'unica riga.
      await db.insert(
        _table,
        user.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return Result<User>.ok(user);
    } on Object catch (error) {
      return Result<User>.error(asStorageException(error));
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
