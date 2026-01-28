import '../entities/nip_05.dart';

/// repository to get the Nip05 object
abstract class Nip05Repository {
  ///  network request to get the Nip05 object
  Future<Nip05?> requestNip05(String nip05, String pubkey);

  /// fetches NIP-05 data without validation
  /// returns pubkey and relays for the given nip05 identifier
  Future<Nip05?> fetchNip05(String nip05);
}
