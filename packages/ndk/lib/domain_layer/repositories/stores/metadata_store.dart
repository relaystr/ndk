import '../../entities/metadata.dart';

/// A convenience view over the kind 0 events of the event store, not a
/// separate authoritative silo.
abstract interface class MetadataStore {
  @Deprecated(
    'Use saveEvent()/saveEvents() with kind 0 events; Metadata is now a convenience view over the generic event cache.',
  )
  Future<void> saveMetadata(Metadata metadata);
  @Deprecated(
    'Use saveEvent()/saveEvents() with kind 0 events; Metadata is now a convenience view over the generic event cache.',
  )
  Future<void> saveMetadatas(List<Metadata> metadatas);
  Future<Metadata?> loadMetadata(String pubKey);
  Future<List<Metadata?>> loadMetadatas(List<String> pubKeys);
  @Deprecated(
    'Use removeEvents(pubKeys: ..., kinds: [Metadata.kKind]); Metadata is now a convenience view over the generic event cache.',
  )
  Future<void> removeMetadata(String pubKey);
  Future<void> removeAllMetadatas();

  /// Search by name, nip05
  Future<Iterable<Metadata>> searchMetadatas(String search, int limit);
}
