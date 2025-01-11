import 'dart:typed_data';

import '../../repositories/blossom.dart';

/// high level usecase to manage files on nostr
class Files {
  final BlossomRepository repository;

  Files(this.repository);
}
