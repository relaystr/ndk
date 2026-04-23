import 'package:rxdart/rxdart.dart';

import '../../../domain_layer/entities/nip_01_event.dart';
import '../../../domain_layer/entities/pending_signer_request.dart';
import '../../../shared/nips/nip01/helpers.dart';
import '../../../shared/nips/nip04/nip04.dart';
import '../../../shared/nips/nip01/bip340.dart';
import '../../../domain_layer/repositories/event_signer.dart';
import '../../../domain_layer/repositories/nip44_cryptography.dart';
import '../cryptography/default_nip44_cryptography.dart';

/// Pure Dart Event Signer
class Bip340EventSigner implements EventSigner {
  /// hex private key
  String? privateKey;

  /// hex public key
  String publicKey;

  final Nip44Cryptography _nip44Cryptography;

  /// Get a new event signer with the given keys
  Bip340EventSigner({
    required this.privateKey,
    required this.publicKey,
    Nip44Cryptography? nip44Cryptography,
  }) : _nip44Cryptography =
            nip44Cryptography ?? const DefaultNip44Cryptography();

  @override
  Future<Nip01Event> sign(Nip01Event event) async {
    if (Helpers.isNotBlank(privateKey)) {
      return event.copyWith(sig: Bip340.sign(event.id, privateKey!));
    }
    throw Exception('Private key is required for signing');
  }

  @override
  String getPublicKey() {
    return publicKey;
  }

  @override
  Future<String?> decrypt(String msg, String destPubKey, {String? id}) async {
    return Nip04.decrypt(privateKey!, destPubKey, msg);
  }

  @override
  Future<String?> encrypt(String msg, String destPubKey, {String? id}) async {
    return Nip04.encrypt(privateKey!, destPubKey, msg);
  }

  @override
  bool canSign() {
    return Helpers.isNotBlank(privateKey);
  }

  @override
  Future<String?> encryptNip44({
    required String plaintext,
    required String recipientPubKey,
  }) {
    return _nip44Cryptography.encrypt(
      plaintext: plaintext,
      privateKey: privateKey!,
      publicKey: recipientPubKey,
    );
  }

  @override
  Future<String?> decryptNip44({
    required String ciphertext,
    required String senderPubKey,
  }) {
    return _nip44Cryptography.decrypt(
      ciphertext: ciphertext,
      privateKey: privateKey!,
      publicKey: senderPubKey,
    );
  }

  // Local signer - no pending requests (operations are instant)
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
