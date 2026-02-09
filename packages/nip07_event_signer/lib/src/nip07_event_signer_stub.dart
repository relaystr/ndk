import 'package:ndk/ndk.dart';
import 'package:rxdart/rxdart.dart';

class Nip07EventSigner implements EventSigner {
  String? cachedPublicKey;

  final _pendingRequestsController =
      BehaviorSubject<List<PendingSignerRequest>>.seeded([]);

  Nip07EventSigner({this.cachedPublicKey});

  @override
  bool canSign() {
    return false;
  }

  @override
  Future<String?> decrypt(String msg, String destPubKey, {String? id}) async {
    throw UnsupportedError('NIP-07 is not available on this platform');
  }

  @override
  Future<String?> decryptNip44({
    required String ciphertext,
    required String senderPubKey,
  }) async {
    throw UnsupportedError('NIP-07 is not available on this platform');
  }

  @override
  Future<String?> encrypt(String msg, String destPubKey, {String? id}) async {
    throw UnsupportedError('NIP-07 is not available on this platform');
  }

  @override
  Future<String?> encryptNip44({
    required String plaintext,
    required String recipientPubKey,
  }) async {
    throw UnsupportedError('NIP-07 is not available on this platform');
  }

  @override
  String getPublicKey() {
    throw UnsupportedError('NIP-07 is not available on this platform');
  }

  Future<String> getPublicKeyAsync() {
    throw UnsupportedError('NIP-07 is not available on this platform');
  }

  @override
  Future<Nip01Event> sign(Nip01Event event) async {
    throw UnsupportedError('NIP-07 is not available on this platform');
  }

  // Stub implementation - always returns empty since NIP-07 is not available
  @override
  Stream<List<PendingSignerRequest>> get pendingRequestsStream =>
      _pendingRequestsController.stream;

  @override
  List<PendingSignerRequest> get pendingRequests => [];

  @override
  bool cancelRequest(String requestId) => false;
}
