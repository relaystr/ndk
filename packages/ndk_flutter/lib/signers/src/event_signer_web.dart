import 'dart:async';
import 'dart:js_interop';

import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/helpers.dart';
import 'package:rxdart/rxdart.dart';
import 'package:web/web.dart' as web;

import '../../verifiers/src/js_interop.dart';
import 'nostr_sign_js.dart';

/// Web alias of [NdkEventSigner]: fast [WebEventSigner] via JS interop.
typedef NdkEventSigner = WebEventSigner;

/// Web factory: produces [WebEventSigner] instances using @noble/curves.
class NdkEventSignerFactory implements LocalEventSignerFactory {
  const NdkEventSignerFactory();

  @override
  EventSigner create({String? privateKey, String? publicKey}) {
    final derivedPublicKey =
        publicKey ?? (privateKey != null ? derivePublicKey(privateKey) : null);

    if (derivedPublicKey == null) {
      throw ArgumentError('Either publicKey or privateKey must be provided');
    }

    return WebEventSigner(privateKey: privateKey, publicKey: derivedPublicKey);
  }

  @override
  String derivePublicKey(String privateKey) {
    WebEventSigner._injectJS();
    return WebEventSigner._requireNostrCrypto()
        .getPublicKey(privateKey.toJS)
        .toDart;
  }

  @override
  (String, String) generateKeyPair() {
    final privateKey = Helpers.getSecureRandomHex(32);
    return (privateKey, derivePublicKey(privateKey));
  }

  @override
  EventSigner createWithNewKeyPair() {
    final (privateKey, publicKey) = generateKeyPair();
    return create(privateKey: privateKey, publicKey: publicKey);
  }
}

/// Web implementation of EventSigner using @noble/curves and Web Crypto API
/// via JS interop for fast BIP-340 signing, NIP-04 and NIP-44 encryption.
class WebEventSigner implements EventSigner {
  /// hex private key
  String? privateKey;

  /// hex public key
  String publicKey;

  final Completer<bool> _isInitialized = Completer<bool>();
  static bool _jsInjected = false;

  /// Get a new web event signer with the given keys
  WebEventSigner({required this.privateKey, required this.publicKey}) {
    _init();
  }

  @override
  bool get requiresInteractiveSigning => false;

  @override
  bool get requiresSignerNetwork => false;

  @override
  Iterable<String> get signerTransportRelayUrls => const <String>[];

  Future<void> _init() async {
    if (!_jsInjected) {
      _injectJS();
      _jsInjected = true;
    }
    _isInitialized.complete(true);
  }

  static void _injectJS() {
    // Check if already loaded (e.g., via index.html or WebEventVerifier)
    if (nostrCrypto != null) {
      return;
    }

    final script =
        web.document.createElement('script') as web.HTMLScriptElement;
    script.type = 'text/javascript';
    script.text = nostrCryptoJs;
    web.document.head?.appendChild(script);
  }

  static NostrCrypto _requireNostrCrypto() =>
      nostrCrypto ??
      (throw Exception(
        'NostrCrypto not available. JS injection may have failed.',
      ));

  Future<NostrCrypto> _getCrypto() async {
    await _isInitialized.future;
    return _requireNostrCrypto();
  }

  @override
  Future<Nip01Event> sign(Nip01Event event) async {
    if (privateKey == null || privateKey!.isEmpty) {
      throw Exception('Private key is required for signing');
    }

    final crypto = await _getCrypto();
    final signature = await crypto
        .signEvent(privateKey!.toJS, event.id.toJS)
        .toDart;

    return event.copyWith(sig: signature.toDart);
  }

  @override
  String getPublicKey() {
    return publicKey;
  }

  @override
  Future<String?> decrypt(String msg, String destPubKey) async {
    if (privateKey == null || privateKey!.isEmpty) {
      throw Exception('Private key is required for decryption');
    }
    final crypto = await _getCrypto();
    final result = await crypto
        .nip04Decrypt(privateKey!.toJS, destPubKey.toJS, msg.toJS)
        .toDart;
    return result.toDart;
  }

  @override
  Future<String?> encrypt(String msg, String destPubKey) async {
    if (privateKey == null || privateKey!.isEmpty) {
      throw Exception('Private key is required for encryption');
    }
    final crypto = await _getCrypto();
    final result = await crypto
        .nip04Encrypt(privateKey!.toJS, destPubKey.toJS, msg.toJS)
        .toDart;
    return result.toDart;
  }

  @override
  bool canSign() {
    return privateKey != null && privateKey!.isNotEmpty;
  }

  @override
  Future<String?> encryptNip44({
    required String plaintext,
    required String recipientPubKey,
  }) async {
    if (privateKey == null || privateKey!.isEmpty) {
      throw Exception('Private key is required for encryption');
    }
    final crypto = await _getCrypto();
    final result = await crypto
        .nip44Encrypt(privateKey!.toJS, recipientPubKey.toJS, plaintext.toJS)
        .toDart;
    return result.toDart;
  }

  @override
  Future<String?> decryptNip44({
    required String ciphertext,
    required String senderPubKey,
  }) async {
    if (privateKey == null || privateKey!.isEmpty) {
      throw Exception('Private key is required for decryption');
    }
    final crypto = await _getCrypto();
    final result = await crypto
        .nip44Decrypt(privateKey!.toJS, senderPubKey.toJS, ciphertext.toJS)
        .toDart;
    return result.toDart;
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
