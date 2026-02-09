import 'dart:async';
import 'dart:js_interop';
import 'package:ndk/ndk.dart';
import 'package:rxdart/rxdart.dart';
import 'js_interop.dart' as js;

/// Internal class to track a pending request with its completer
class _PendingRequestEntry {
  final Completer<dynamic> completer;
  final PendingSignerRequest request;
  _PendingRequestEntry(this.completer, this.request);
}

class Nip07EventSigner implements EventSigner {
  String? cachedPublicKey;

  final _pendingRequests = <String, _PendingRequestEntry>{};
  final _pendingRequestsController =
      BehaviorSubject<List<PendingSignerRequest>>.seeded([]);

  int _requestCounter = 0;

  Nip07EventSigner({this.cachedPublicKey});

  String _generateRequestId() {
    return 'nip07_${DateTime.now().millisecondsSinceEpoch}_${_requestCounter++}';
  }

  void _notifyPendingRequestsChange() {
    _pendingRequestsController
        .add(_pendingRequests.values.map((e) => e.request).toList());
  }

  /// Wraps an async operation to track it as a pending request
  Future<T> _trackRequest<T>(
    SignerMethod method,
    Future<T> Function() operation, {
    Nip01Event? event,
    String? plaintext,
    String? ciphertext,
    String? counterpartyPubkey,
  }) async {
    final requestId = _generateRequestId();
    final completer = Completer<T>();
    final pendingRequest = PendingSignerRequest(
      id: requestId,
      method: method,
      createdAt: DateTime.now(),
      signerPubkey: cachedPublicKey ?? '',
      event: event,
      plaintext: plaintext,
      ciphertext: ciphertext,
      counterpartyPubkey: counterpartyPubkey,
    );

    _pendingRequests[requestId] = _PendingRequestEntry(
      completer as Completer<dynamic>,
      pendingRequest,
    );
    _notifyPendingRequestsChange();

    try {
      final result = await operation();
      if (!completer.isCompleted) {
        completer.complete(result);
      }
      return result;
    } catch (e) {
      if (!completer.isCompleted) {
        completer.completeError(e);
      }
      rethrow;
    } finally {
      _pendingRequests.remove(requestId);
      _notifyPendingRequestsChange();
    }
  }

  @override
  bool canSign() {
    return js.nostr != null;
  }

  @override
  Future<String?> decrypt(String msg, String destPubKey, {String? id}) async {
    if (js.nostr == null) {
      throw Exception('NIP-07 extension not available');
    }

    return _trackRequest(
      SignerMethod.nip04Decrypt,
      () async {
        final result = await js.nostr!.nip04!
            .decrypt(destPubKey.toJS, msg.toJS)
            .toDart;
        return result.toDart;
      },
      ciphertext: msg,
      counterpartyPubkey: destPubKey,
    );
  }

  @override
  Future<String?> decryptNip44({
    required String ciphertext,
    required String senderPubKey,
  }) async {
    if (js.nostr == null) {
      throw Exception('NIP-07 extension not available');
    }

    return _trackRequest(
      SignerMethod.nip44Decrypt,
      () async {
        final result = await js.nostr!.nip44!
            .decrypt(senderPubKey.toJS, ciphertext.toJS)
            .toDart;
        return result.toDart;
      },
      ciphertext: ciphertext,
      counterpartyPubkey: senderPubKey,
    );
  }

  @override
  Future<String?> encrypt(String msg, String destPubKey, {String? id}) async {
    if (js.nostr == null) {
      throw Exception('NIP-07 extension not available');
    }

    return _trackRequest(
      SignerMethod.nip04Encrypt,
      () async {
        final result = await js.nostr!.nip04!
            .encrypt(destPubKey.toJS, msg.toJS)
            .toDart;
        return result.toDart;
      },
      plaintext: msg,
      counterpartyPubkey: destPubKey,
    );
  }

  @override
  Future<String?> encryptNip44({
    required String plaintext,
    required String recipientPubKey,
  }) async {
    if (js.nostr == null) {
      throw Exception('NIP-07 extension not available');
    }

    return _trackRequest(
      SignerMethod.nip44Encrypt,
      () async {
        final result = await js.nostr!.nip44!
            .encrypt(recipientPubKey.toJS, plaintext.toJS)
            .toDart;
        return result.toDart;
      },
      plaintext: plaintext,
      counterpartyPubkey: recipientPubKey,
    );
  }

  @override
  String getPublicKey() {
    if (cachedPublicKey != null) return cachedPublicKey!;

    js.nostr!.getPublicKey().toDart.then((pubkey) {
      cachedPublicKey = pubkey.toDart;
    });

    throw Exception("Use getPublicKeyAsync with Nip07EventSigner");
  }

  Future<String> getPublicKeyAsync() async {
    return _trackRequest(
      SignerMethod.getPublicKey,
      () async {
        final pubkey = (await js.nostr!.getPublicKey().toDart).toDart;
        cachedPublicKey = pubkey;
        return pubkey;
      },
    );
  }

  @override
  Future<Nip01Event> sign(Nip01Event event) async {
    if (js.nostr == null) {
      throw Exception('NIP-07 extension not available');
    }

    return _trackRequest(
      SignerMethod.signEvent,
      () async {
        final jsEvent = js.NostrEvent()
          ..pubkey = event.pubKey
          ..created_at = event.createdAt
          ..kind = event.kind
          ..content = event.content
          ..tags = event.tags
              .map((tag) => tag.map((item) => item.toJS).toList().toJS)
              .toList()
              .toJS;

        // Sign the event using NIP-07
        final signedEvent = await js.nostr!.signEvent(jsEvent).toDart;

        return event.copyWith(id: signedEvent.id!, sig: signedEvent.sig!);
      },
      event: event,
    );
  }

  @override
  Stream<List<PendingSignerRequest>> get pendingRequestsStream =>
      _pendingRequestsController.stream;

  @override
  List<PendingSignerRequest> get pendingRequests =>
      _pendingRequests.values.map((e) => e.request).toList();

  @override
  bool cancelRequest(String requestId) {
    final entry = _pendingRequests.remove(requestId);
    if (entry != null) {
      entry.completer.completeError(SignerRequestCancelledException(requestId));
      _notifyPendingRequestsChange();
      return true;
    }
    return false;
  }

  void dispose() {
    _pendingRequestsController.close();
  }
}
