import 'dart:async';
import 'dart:typed_data';

import '../../../domain_layer/entities/nip_01_event.dart';
import '../../../domain_layer/entities/pending_signer_request.dart';
import '../../../domain_layer/repositories/event_signer.dart';

/// Stub implementation of [QsKeypair] for platforms that don't support FFI (e.g., web).
class QsKeypair {
  final Uint8List publicKeyBytes;
  final Uint8List keypairBytes;
  final String publicKeyHex;

  QsKeypair({
    required this.publicKeyBytes,
    required this.keypairBytes,
    required this.publicKeyHex,
  });
}

/// Stub implementation of [QsRustEventSigner] for platforms that don't support FFI (e.g., web).
///
/// All operations throw [UnsupportedError] since Rust FFI is not available on web platforms.
class QsRustEventSigner implements EventSigner {
  final int level;

  QsRustEventSigner({required QsKeypair keypair, this.level = 2});

  static QsKeypair generateKeypair({int level = 2}) {
    throw UnsupportedError(
      'QsRustEventSigner is not available on this platform. '
      'FFI is not supported on web.',
    );
  }

  @override
  Future<Nip01Event> sign(Nip01Event event) {
    throw UnsupportedError(
      'QsRustEventSigner is not available on this platform. '
      'FFI is not supported on web.',
    );
  }

  @override
  String getPublicKey() {
    throw UnsupportedError(
      'QsRustEventSigner is not available on this platform. '
      'FFI is not supported on web.',
    );
  }

  @override
  bool canSign() => false;

  @override
  @Deprecated('Use nip44 decrypt instead. Deprecated by nostr spec. (nip04)')
  Future<String?> decrypt(String msg, String destPubKey, {String? id}) {
    throw UnsupportedError(
      'QsRustEventSigner is not available on this platform. '
      'FFI is not supported on web.',
    );
  }

  @override
  @Deprecated('Use nip44 encrypt instead. Deprecated by nostr spec. (nip04)')
  Future<String?> encrypt(String msg, String destPubKey, {String? id}) {
    throw UnsupportedError(
      'QsRustEventSigner is not available on this platform. '
      'FFI is not supported on web.',
    );
  }

  @override
  Future<String?> encryptNip44({
    required String plaintext,
    required String recipientPubKey,
  }) {
    throw UnsupportedError(
      'QsRustEventSigner is not available on this platform. '
      'FFI is not supported on web.',
    );
  }

  @override
  Future<String?> decryptNip44({
    required String ciphertext,
    required String senderPubKey,
  }) {
    throw UnsupportedError(
      'QsRustEventSigner is not available on this platform. '
      'FFI is not supported on web.',
    );
  }

  @override
  Stream<List<PendingSignerRequest>> get pendingRequestsStream =>
      const Stream.empty();

  @override
  List<PendingSignerRequest> get pendingRequests => [];

  @override
  bool cancelRequest(String requestId) => false;

  @override
  Future<void> dispose() async {}
}
