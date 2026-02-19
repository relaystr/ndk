import 'package:ndk/domain_layer/entities/nip_01_event.dart';
import 'package:ndk/domain_layer/entities/pending_signer_request.dart';
import 'package:ndk/domain_layer/repositories/event_signer.dart';

/// A wrapper signer that adds a delay to simulate slow signing
/// (like NIP-46, Amber, etc.) where user interaction is required.
class MockSlowSigner implements EventSigner {
  final EventSigner _innerSigner;
  final Duration _delay;

  MockSlowSigner({
    required EventSigner innerSigner,
    required Duration delay,
  })  : _innerSigner = innerSigner,
        _delay = delay;

  @override
  Future<Nip01Event> sign(Nip01Event event) async {
    await Future.delayed(_delay);
    return _innerSigner.sign(event);
  }

  @override
  String getPublicKey() => _innerSigner.getPublicKey();

  @override
  bool canSign() => _innerSigner.canSign();

  @override
  Future<String?> decrypt(String msg, String destPubKey, {String? id}) async {
    await Future.delayed(_delay);
    return _innerSigner.decrypt(msg, destPubKey, id: id);
  }

  @override
  Future<String?> encrypt(String msg, String destPubKey, {String? id}) async {
    await Future.delayed(_delay);
    return _innerSigner.encrypt(msg, destPubKey, id: id);
  }

  @override
  Future<String?> encryptNip44({
    required String plaintext,
    required String recipientPubKey,
  }) async {
    await Future.delayed(_delay);
    return _innerSigner.encryptNip44(
      plaintext: plaintext,
      recipientPubKey: recipientPubKey,
    );
  }

  @override
  Future<String?> decryptNip44({
    required String ciphertext,
    required String senderPubKey,
  }) async {
    await Future.delayed(_delay);
    return _innerSigner.decryptNip44(
      ciphertext: ciphertext,
      senderPubKey: senderPubKey,
    );
  }

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
