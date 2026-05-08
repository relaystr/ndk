import 'dart:async';
import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

import '../../../domain_layer/entities/nip_01_event.dart';
import '../../../domain_layer/entities/pending_signer_request.dart';
import '../../../domain_layer/repositories/event_signer.dart';
import '../../../src/rust_lib.dart' as rust_lib;

/// Holds a Dilithium keypair (public key + full keypair bytes for signing).
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

/// An implementation of [EventSigner] that uses quantum-secure
/// CRYSTALS-Dilithium signatures via native Rust FFI.
class QsRustEventSigner implements EventSigner {
  /// The Dilithium security level (2, 3, or 5).
  final int level;

  late final QsKeypair _keypair;

  final StreamController<List<PendingSignerRequest>> _pendingController =
      StreamController<List<PendingSignerRequest>>.broadcast();

  /// Creates a [QsRustEventSigner] from an existing [QsKeypair].
  ///
  /// Use [QsRustEventSigner.generate] to create a new keypair first.
  QsRustEventSigner({
    required QsKeypair keypair,
    this.level = 2,
  }) : _keypair = keypair;

  /// Generates a new Dilithium keypair.
  /// Its only added here for testing purposes!
  ///
  /// [level] selects the security level: 2 (~AES-128), 3 (~AES-192), or 5 (~AES-256).
  ///
  /// Returns a [QsKeypair] that can be stored and later passed to the constructor.
  ///
  /// Throws [StateError] if key generation fails.
  ///
  /// Example:
  /// ```dart
  /// final keypair = QsRustEventSigner.generateKeypair(level: 2);
  /// final signer = QsRustEventSigner(keypair: keypair, level: 2);
  /// ```
  static QsKeypair generateKeypair({int level = 2}) {
    final outPk = calloc<rust_lib.QsBuffer>();
    final outSk = calloc<rust_lib.QsBuffer>();

    try {
      final result = rust_lib.qsGenerateKeypair(level, outPk, outSk);

      if (result != 1) {
        throw StateError(
            'Failed to generate Dilithium keypair at level $level');
      }

      final pkLen = outPk.ref.len;
      final publicKeyBytes =
          Uint8List.fromList(outPk.ref.data.asTypedList(pkLen));

      final skLen = outSk.ref.len;
      final keypairBytes =
          Uint8List.fromList(outSk.ref.data.asTypedList(skLen));

      rust_lib.qsFreeBuffer(outPk.ref);
      rust_lib.qsFreeBuffer(outSk.ref);

      return QsKeypair(
        publicKeyBytes: publicKeyBytes,
        keypairBytes: keypairBytes,
        publicKeyHex: _bytesToHex(publicKeyBytes),
      );
    } finally {
      calloc.free(outPk);
      calloc.free(outSk);
    }
  }

  @override
  Future<Nip01Event> sign(Nip01Event event) async {
    final msgBytes = _hexToBytes(event.id);
    if (msgBytes == null) {
      throw ArgumentError('Invalid event id hex: ${event.id}');
    }

    final skPtr = calloc<Uint8>(_keypair.keypairBytes.length);
    final msgPtr = calloc<Uint8>(msgBytes.length);
    final outSig = calloc<rust_lib.QsBuffer>();

    try {
      skPtr
          .asTypedList(_keypair.keypairBytes.length)
          .setAll(0, _keypair.keypairBytes);
      msgPtr.asTypedList(msgBytes.length).setAll(0, msgBytes);

      final result = rust_lib.qsSign(
        level,
        skPtr,
        _keypair.keypairBytes.length,
        msgPtr,
        msgBytes.length,
        outSig,
      );

      if (result != 1) {
        throw StateError('Failed to sign event with Dilithium');
      }

      final sigLen = outSig.ref.len;
      final sigBytes = Uint8List.fromList(outSig.ref.data.asTypedList(sigLen));
      final sigHex = _bytesToHex(sigBytes);

      rust_lib.qsFreeBuffer(outSig.ref);

      return Nip01Event(
        id: event.id,
        pubKey: _keypair.publicKeyHex,
        createdAt: event.createdAt,
        kind: event.kind,
        tags: event.tags,
        content: event.content,
        sig: sigHex,
      );
    } finally {
      calloc.free(skPtr);
      calloc.free(msgPtr);
      calloc.free(outSig);
    }
  }

  @override
  String getPublicKey() => _keypair.publicKeyHex;

  @override
  bool canSign() => true;

  @override
  @Deprecated('Use nip44 decrypt instead. Deprecated by nostr spec. (nip04)')
  Future<String?> decrypt(String msg, String destPubKey, {String? id}) {
    throw UnimplementedError(
        'NIP-04 decrypt is not supported by QsRustEventSigner');
  }

  @override
  @Deprecated('Use nip44 encrypt instead. Deprecated by nostr spec. (nip04)')
  Future<String?> encrypt(String msg, String destPubKey, {String? id}) {
    throw UnimplementedError(
        'NIP-04 encrypt is not supported by QsRustEventSigner');
  }

  @override
  Future<String?> encryptNip44({
    required String plaintext,
    required String recipientPubKey,
  }) {
    throw UnimplementedError(
        'NIP-44 encrypt is not supported by QsRustEventSigner');
  }

  @override
  Future<String?> decryptNip44({
    required String ciphertext,
    required String senderPubKey,
  }) {
    throw UnimplementedError(
        'NIP-44 decrypt is not supported by QsRustEventSigner');
  }

  @override
  Stream<List<PendingSignerRequest>> get pendingRequestsStream =>
      _pendingController.stream;

  @override
  List<PendingSignerRequest> get pendingRequests => [];

  @override
  bool cancelRequest(String requestId) => false;

  @override
  Future<void> dispose() async {
    await _pendingController.close();
  }

  /// The keypair used by this signer (for storage/serialization).
  QsKeypair get keypair => _keypair;

  // ── Helpers ────────────────────────────────────────────────────────

  static Uint8List? _hexToBytes(String hex) {
    if (hex.length % 2 != 0) return null;
    try {
      final bytes = Uint8List(hex.length ~/ 2);
      for (var i = 0; i < hex.length; i += 2) {
        bytes[i ~/ 2] = int.parse(hex.substring(i, i + 2), radix: 16);
      }
      return bytes;
    } catch (_) {
      return null;
    }
  }

  static String _bytesToHex(Uint8List bytes) {
    final sb = StringBuffer();
    for (final b in bytes) {
      sb.write(b.toRadixString(16).padLeft(2, '0'));
    }
    return sb.toString();
  }
}
