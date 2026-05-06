import 'package:ndk/ndk.dart';

/// Stub implementation for non-web platforms.
/// WebEventSigner is only available on web platforms.
class WebEventSigner implements EventSigner {
  WebEventSigner() {
    throw UnsupportedError(
      'WebEventSigner is only available on web platforms. '
      'Use Bip340EventSigner for native platforms.',
    );
  }

  @override
  Future<Nip01Event> sign(Nip01Event event) {
    throw UnsupportedError(
      'WebEventSigner is only available on web platforms.',
    );
  }

  @override
  String getPublicKey() {
    throw UnsupportedError(
      'WebEventSigner is only available on web platforms.',
    );
  }

  @override
  Future<String?> decrypt(String msg, String destPubKey, {String? id}) {
    throw UnsupportedError(
      'WebEventSigner is only available on web platforms.',
    );
  }

  @override
  Future<String?> encrypt(String msg, String destPubKey, {String? id}) {
    throw UnsupportedError(
      'WebEventSigner is only available on web platforms.',
    );
  }

  @override
  bool canSign() {
    throw UnsupportedError(
      'WebEventSigner is only available on web platforms.',
    );
  }

  @override
  Future<String?> encryptNip44({
    required String plaintext,
    required String recipientPubKey,
  }) {
    throw UnsupportedError(
      'WebEventSigner is only available on web platforms.',
    );
  }

  @override
  Future<String?> decryptNip44({
    required String ciphertext,
    required String senderPubKey,
  }) {
    throw UnsupportedError(
      'WebEventSigner is only available on web platforms.',
    );
  }

  @override
  Stream<List<PendingSignerRequest>> get pendingRequestsStream {
    throw UnsupportedError(
      'WebEventSigner is only available on web platforms.',
    );
  }

  @override
  List<PendingSignerRequest> get pendingRequests {
    throw UnsupportedError(
      'WebEventSigner is only available on web platforms.',
    );
  }

  @override
  bool cancelRequest(String requestId) {
    throw UnsupportedError(
      'WebEventSigner is only available on web platforms.',
    );
  }

  @override
  Future<void> dispose() async {
    throw UnsupportedError(
      'WebEventSigner is only available on web platforms.',
    );
  }
}
