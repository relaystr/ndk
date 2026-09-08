import 'package:ndk/domain_layer/entities/nip_01_event.dart';
import 'package:ndk/domain_layer/entities/pending_signer_request.dart';
import 'package:ndk/domain_layer/entities/signer_request_rejected_exception.dart';
import 'package:ndk/domain_layer/repositories/event_signer.dart';

/// A wrapper signer that declines every request, the way a bunker answers one
/// its owner rejected: it throws instead of returning an event.
class MockRefusingSigner implements EventSigner {
  final EventSigner _innerSigner;

  /// how many times something asked this signer to sign
  int signAttempts = 0;

  MockRefusingSigner({required EventSigner innerSigner})
      : _innerSigner = innerSigner;

  @override
  bool get requiresInteractiveSigning => true;

  @override
  bool get requiresSignerNetwork => _innerSigner.requiresSignerNetwork;

  @override
  Iterable<String> get signerTransportRelayUrls =>
      _innerSigner.signerTransportRelayUrls;

  @override
  Future<Nip01Event> sign(Nip01Event event) async {
    signAttempts++;
    throw SignerRequestRejectedException(
      requestId: 'refused-$signAttempts',
      originalMessage: 'user rejected',
    );
  }

  @override
  String getPublicKey() => _innerSigner.getPublicKey();

  @override
  bool canSign() => _innerSigner.canSign();

  @override
  Future<String?> decrypt(String msg, String destPubKey) =>
      _innerSigner.decrypt(msg, destPubKey);

  @override
  Future<String?> encrypt(String msg, String destPubKey) =>
      _innerSigner.encrypt(msg, destPubKey);

  @override
  Future<String?> encryptNip44({
    required String plaintext,
    required String recipientPubKey,
  }) =>
      _innerSigner.encryptNip44(
        plaintext: plaintext,
        recipientPubKey: recipientPubKey,
      );

  @override
  Future<String?> decryptNip44({
    required String ciphertext,
    required String senderPubKey,
  }) =>
      _innerSigner.decryptNip44(
        ciphertext: ciphertext,
        senderPubKey: senderPubKey,
      );

  @override
  Stream<List<PendingSignerRequest>> get pendingRequestsStream =>
      _innerSigner.pendingRequestsStream;

  @override
  List<PendingSignerRequest> get pendingRequests =>
      _innerSigner.pendingRequests;

  @override
  bool cancelRequest(String requestId) => _innerSigner.cancelRequest(requestId);

  @override
  Future<void> dispose() => _innerSigner.dispose();
}
