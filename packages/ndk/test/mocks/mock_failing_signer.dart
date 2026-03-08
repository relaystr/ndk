import 'package:ndk/domain_layer/entities/nip_01_event.dart';
import 'package:ndk/domain_layer/entities/pending_signer_request.dart';
import 'package:ndk/domain_layer/entities/signer_request_rejected_exception.dart';
import 'package:ndk/domain_layer/repositories/event_signer.dart';
import 'package:rxdart/rxdart.dart';

/// A mock signer that throws [SignerRequestRejectedException] when signing.
/// Used to test error handling when signing fails.
class MockFailingSigner implements EventSigner {
  final String _publicKey;

  MockFailingSigner({required String publicKey}) : _publicKey = publicKey;

  @override
  Future<Nip01Event> sign(Nip01Event event) async {
    throw SignerRequestRejectedException(
      requestId: 'mock-request-id',
      originalMessage: 'User rejected the signing request',
    );
  }

  @override
  String getPublicKey() => _publicKey;

  @override
  Future<String?> decrypt(String msg, String destPubKey, {String? id}) async {
    throw SignerRequestRejectedException(
      requestId: id,
      originalMessage: 'User rejected the decrypt request',
    );
  }

  @override
  Future<String?> encrypt(String msg, String destPubKey, {String? id}) async {
    throw SignerRequestRejectedException(
      requestId: id,
      originalMessage: 'User rejected the encrypt request',
    );
  }

  @override
  bool canSign() => true;

  @override
  Future<String?> encryptNip44({
    required String plaintext,
    required String recipientPubKey,
  }) async {
    throw SignerRequestRejectedException(
      originalMessage: 'User rejected the NIP-44 encrypt request',
    );
  }

  @override
  Future<String?> decryptNip44({
    required String ciphertext,
    required String senderPubKey,
  }) async {
    throw SignerRequestRejectedException(
      originalMessage: 'User rejected the NIP-44 decrypt request',
    );
  }

  final _pendingRequestsController =
      BehaviorSubject<List<PendingSignerRequest>>.seeded([]);

  @override
  Stream<List<PendingSignerRequest>> get pendingRequestsStream =>
      _pendingRequestsController.stream;

  @override
  List<PendingSignerRequest> get pendingRequests => [];

  @override
  bool cancelRequest(String requestId) => false;

  @override
  Future<void> dispose() async {
    await _pendingRequestsController.close();
  }
}
