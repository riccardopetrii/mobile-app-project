import '../../utils/dates.dart';
import '../../utils/password.dart';

/// Il profilo locale dell'utente.
///
/// L'applicazione è mono-utente e senza server: esiste una sola riga nella
/// tabella `users`, con identificativo fisso. Tutti i campi anagrafici sono
/// facoltativi, perché chi entra come ospite non li compila.
class User {
  User({
    this.nome,
    this.cognome,
    this.email,
    this.dataNascita,
    this.genere,
    this.avatarPath,
    this.password,
    required this.createdAt,
  });

  /// Ricostruisce il profilo da una riga di `users`.
  factory User.fromMap(Map<String, Object?> map) => User(
    nome: map['nome'] as String?,
    cognome: map['cognome'] as String?,
    email: map['email'] as String?,
    dataNascita: switch (map['data_nascita']) {
      final String data => parseDateKey(data),
      _ => null,
    },
    genere: map['genere'] as String?,
    avatarPath: map['avatar_path'] as String?,
    password: switch ((map['password_hash'], map['password_salt'])) {
      (final String hash, final String salt) => PasswordDigest(
        hash: hash,
        salt: salt,
      ),
      _ => null,
    },
    createdAt: DateTime.parse(map['created_at']! as String),
  );

  static const int singleId = 1;

  int get id => singleId;

  final String? nome;

  final String? cognome;

  final String? email;

  final DateTime? dataNascita;

  final String? genere;

  final String? avatarPath;

  /// L'impronta della password scelta all'iscrizione.
  ///
  /// È nulla per i profili creati prima che l'accesso chiedesse una password,
  /// e per l'ospite, che non ne ha una.
  final PasswordDigest? password;

  final DateTime createdAt;

  String get nomeCompleto => <String?>[
    nome,
    cognome,
  ].whereType<String>().where((parte) => parte.trim().isNotEmpty).join(' ');

  /// La riga da scrivere in `users`.
  Map<String, Object?> toMap() => <String, Object?>{
    'id': id,
    'nome': nome,
    'cognome': cognome,
    'email': email,
    'data_nascita': switch (dataNascita) {
      final DateTime data => dateKey(data),
      null => null,
    },
    'genere': genere,
    'avatar_path': avatarPath,
    'password_hash': password?.hash,
    'password_salt': password?.salt,
    'created_at': createdAt.toIso8601String(),
  };

  /// Una copia con i soli campi indicati sostituiti.
  User copyWith({
    String? nome,
    String? cognome,
    String? email,
    DateTime? dataNascita,
    String? genere,
    String? avatarPath,
    PasswordDigest? password,
    DateTime? createdAt,
  }) => User(
    nome: nome ?? this.nome,
    cognome: cognome ?? this.cognome,
    email: email ?? this.email,
    dataNascita: dataNascita ?? this.dataNascita,
    genere: genere ?? this.genere,
    avatarPath: avatarPath ?? this.avatarPath,
    password: password ?? this.password,
    createdAt: createdAt ?? this.createdAt,
  );

  @override
  bool operator ==(Object other) =>
      other is User &&
      other.nome == nome &&
      other.cognome == cognome &&
      other.email == email &&
      other.dataNascita == dataNascita &&
      other.genere == genere &&
      other.avatarPath == avatarPath &&
      other.password == password &&
      other.createdAt == createdAt;

  @override
  int get hashCode => Object.hash(
    nome,
    cognome,
    email,
    dataNascita,
    genere,
    avatarPath,
    password,
    createdAt,
  );

  @override
  String toString() => 'User($nomeCompleto)';
}
