import '../../entities/nip_05.dart';

/// NIP-05 records are keyed by [Nip05.nip05], the canonical identifier
abstract interface class Nip05Store {
  Future<void> saveNip05(Nip05 nip05);
  Future<void> saveNip05s(List<Nip05> nip05s);
  Future<Nip05?> loadNip05(String identifier);
  Future<List<Nip05?>> loadNip05s(List<String> identifiers);
  Future<void> removeNip05(String identifier);
  Future<void> removeAllNip05s();
}
