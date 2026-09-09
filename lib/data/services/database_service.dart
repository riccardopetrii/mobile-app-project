import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Apre e mantiene il database SQLite locale dell'applicazione.
class DatabaseService {
  DatabaseService({String? path}) : _path = path;

  static const String databaseName = 'vivo.db';

  static const int schemaVersion = 2;

  final String? _path;

  Database? _database;
  Future<Database>? _apertura;

  Future<Database> get database {
    final aperto = _database;
    if (aperto != null) return Future.value(aperto);
    return _apertura ??= _apri();
  }

  Future<Database> _apri() async {
    final percorso =
        _path ?? p.join(await getDatabasesPath(), databaseName);
    final database = await openDatabase(
      percorso,
      version: schemaVersion,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: (db, version) async {
        for (final istruzione in _creazioneTabelle) {
          await db.execute(istruzione);
        }
      },
    );
    _database = database;
    return database;
  }

  /// Chiude il database, se aperto.
  Future<void> close() async {
    await _database?.close();
    _database = null;
    _apertura = null;
  }

  static const List<String> _creazioneTabelle = <String>[
    '''
    CREATE TABLE users (
      id            INTEGER PRIMARY KEY,
      nome          TEXT,
      cognome       TEXT,
      email         TEXT,
      data_nascita  TEXT,
      genere        TEXT,
      avatar_path   TEXT,
      password_hash TEXT,
      password_salt TEXT,
      created_at    TEXT NOT NULL
    )
    ''',
    '''
    CREATE TABLE mood_entries (
      id     INTEGER PRIMARY KEY AUTOINCREMENT,
      date   TEXT NOT NULL UNIQUE,
      value  INTEGER NOT NULL,
      note   TEXT
    )
    ''',
    '''
    CREATE TABLE diary_entries (
      id          INTEGER PRIMARY KEY AUTOINCREMENT,
      date        TEXT NOT NULL UNIQUE,
      reflection  TEXT NOT NULL,
      updated_at  TEXT NOT NULL
    )
    ''',
    '''
    CREATE TABLE help_requests (
      id            INTEGER PRIMARY KEY AUTOINCREMENT,
      date          TEXT NOT NULL,
      time          TEXT NOT NULL,
      intensity     INTEGER NOT NULL,
      trigger       TEXT,
      outcome       TEXT,
      completed_at  TEXT NOT NULL
    )
    ''',
  ];
}
