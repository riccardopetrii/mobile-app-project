import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// L'impronta di una password, come viene conservata nel database.
class PasswordDigest {
  const PasswordDigest({required this.hash, required this.salt});

  final String hash;

  final String salt;

  @override
  bool operator ==(Object other) =>
      other is PasswordDigest && other.hash == hash && other.salt == salt;

  @override
  int get hashCode => Object.hash(hash, salt);

  @override
  String toString() => 'PasswordDigest(nascosta)';
}

/// Calcola e verifica le impronte delle password.
///
/// Il sale casuale serve perché due utenti con la stessa password non abbiano
/// la stessa impronta: senza, chi legge il database riconoscerebbe le password
/// più comuni confrontandole con un elenco già calcolato.
abstract final class PasswordHasher {
  static const int lunghezzaMinima = 8;

  static final Random _casuale = Random.secure();

  /// L'impronta di [password], con un sale nuovo a ogni chiamata.
  static PasswordDigest hash(String password, {String? salt}) {
    final sale = salt ?? _saleNuovo();
    final impronta = sha256.convert(utf8.encode('$sale$password'));
    return PasswordDigest(hash: impronta.toString(), salt: sale);
  }

  /// Vero se [password] corrisponde a [digest].
  ///
  /// Un profilo senza password ([digest] nullo) non riconosce nulla: capita
  /// all'ospite, che non ha credenziali da verificare.
  static bool matches(String password, PasswordDigest? digest) {
    if (digest == null) return false;
    return hash(password, salt: digest.salt).hash == digest.hash;
  }

  /// Il motivo per cui [password] non va bene come password nuova, oppure
  /// `null` se va bene.
  static String? validationError(String password) {
    if (password.isEmpty) return 'Scegli una password.';
    if (password.length < lunghezzaMinima) {
      return 'La password deve avere almeno $lunghezzaMinima caratteri.';
    }
    return null;
  }

  static String _saleNuovo() {
    final byte = List<int>.generate(16, (_) => _casuale.nextInt(256));
    return byte
        .map((valore) => valore.toRadixString(16).padLeft(2, '0'))
        .join();
  }
}
