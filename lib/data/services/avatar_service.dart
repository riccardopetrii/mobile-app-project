import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Sceglie l'immagine del profilo e la mette al sicuro.
abstract interface class AvatarService {
  /// Apre la galleria e restituisce il percorso della copia salvata, oppure
  /// `null` se l'utente chiude la galleria senza scegliere.
  Future<String?> pickFromGallery();
}

/// Implementazione di [AvatarService] sulla galleria del telefono.
class LocalAvatarService implements AvatarService {
  LocalAvatarService({
    ImagePicker? picker,
    Future<Directory> Function()? directory,
  }) : _picker = picker ?? ImagePicker(),
       _directory = directory ?? getApplicationDocumentsDirectory;

  /// Lato massimo dell'immagine salvata.
  ///
  /// L'avatar si vede in un cerchio di poco più di cento pixel: conservare la
  /// fotografia a piena risoluzione occuperebbe qualche megabyte per niente.
  static const double _latoMassimo = 512;

  /// Inizio del nome dei file salvati dentro la cartella dell'applicazione.
  static const String _prefisso = 'avatar-';

  final ImagePicker _picker;

  /// Da dove si prende la cartella privata dell'applicazione. Nei test è una
  /// cartella temporanea, così non serve il telefono.
  final Future<Directory> Function() _directory;

  @override
  Future<String?> pickFromGallery() async {
    final scelta = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: _latoMassimo,
      maxHeight: _latoMassimo,
    );
    if (scelta == null) return null;

    final cartella = await _directory();
    final destinazione = p.join(
      cartella.path,
      '$_prefisso${DateTime.now().millisecondsSinceEpoch}.jpg',
    );

    await File(scelta.path).copy(destinazione);

    // Le immagini scelte prima non servono più: senza toglierle si
    // accumulerebbero nella cartella privata una per ogni cambio.
    for (final vecchia in cartella.listSync().whereType<File>()) {
      if (vecchia.path == destinazione) continue;
      if (p.basename(vecchia.path).startsWith(_prefisso)) vecchia.deleteSync();
    }

    return destinazione;
  }
}
