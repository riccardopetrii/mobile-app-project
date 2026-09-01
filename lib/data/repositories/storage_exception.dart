/// L'eccezione con cui un repository riporta una riga del database che non
/// riesce a convertire in un modello.
class StorageException implements Exception {
  const StorageException(this.cause);

  final Object cause;

  @override
  String toString() => 'StorageException: $cause';
}

/// L'eccezione da mettere in un `Result.error` a partire da un errore
/// qualsiasi: le `Exception` passano intatte, tutto il resto viene avvolto.
Exception asStorageException(Object error) =>
    error is Exception ? error : StorageException(error);
