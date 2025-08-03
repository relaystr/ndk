import 'package:ndk/shared/nips/nip01/helpers.dart';

enum BunkerRequestMethods {
  connect,
  getPublicKey,
  signEvent,
  nip04Encrypt,
  nip04Decrypt,
  nip44Encrypt,
  nip44Decrypt,
  ping,
}

Map<BunkerRequestMethods, String> methodToString = {
  BunkerRequestMethods.connect: "connect",
  BunkerRequestMethods.getPublicKey: "get_public_key",
  BunkerRequestMethods.signEvent: "sign_event",
  BunkerRequestMethods.nip04Encrypt: "nip04_encrypt",
  BunkerRequestMethods.nip04Decrypt: "nip04_decrypt",
  BunkerRequestMethods.nip44Encrypt: "nip44_encrypt",
  BunkerRequestMethods.nip44Decrypt: "nip44_decrypt",
  BunkerRequestMethods.ping: "ping",
};

class BunkerRequest {
  final String id;
  final BunkerRequestMethods method;
  final List<String> params;

  BunkerRequest({required this.method, String? id, List<String>? params})
    : id = id ?? Helpers.getRandomString(16),
      params = params ?? [];

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'method': methodToString[method],
      'params': params,
    };
  }
}
