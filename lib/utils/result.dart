/// Esito di un'operazione che può fallire.
///
/// I repository restituiscono un [Result] invece di lanciare eccezioni, così il
/// percorso d'errore è visibile nella firma dei metodi e chi chiama è costretto
/// a gestirlo.
sealed class Result<T> {
  const Result();

  /// Operazione riuscita, con il valore prodotto.
  const factory Result.ok(T value) = Ok<T>;

  /// Operazione fallita, con l'eccezione che l'ha interrotta.
  const factory Result.error(Exception error) = Error<T>;

  bool get isOk => this is Ok<T>;

  T? get valueOrNull => switch (this) {
    Ok<T>(:final value) => value,
    Error<T>() => null,
  };

  /// Riduce i due casi a un unico valore, applicando il ramo corrispondente.
  R fold<R>({
    required R Function(T value) onOk,
    required R Function(Exception error) onError,
  }) => switch (this) {
    Ok<T>(:final value) => onOk(value),
    Error<T>(:final error) => onError(error),
  };
}

/// Il caso di successo di [Result].
final class Ok<T> extends Result<T> {
  const Ok(this.value);

  final T value;

  @override
  String toString() => 'Result<$T>.ok($value)';
}

/// Il caso di errore di [Result].
final class Error<T> extends Result<T> {
  const Error(this.error);

  final Exception error;

  @override
  String toString() => 'Result<$T>.error($error)';
}
