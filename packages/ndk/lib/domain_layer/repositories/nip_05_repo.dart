import '../entities/nip_05.dart';

/// repository to get the Nip05 object
abstract class Nip05Repository {
  ///  network request to get the Nip05 object
  Future<Nip05?> requestNip05(String nip05, String pubkey);
}
