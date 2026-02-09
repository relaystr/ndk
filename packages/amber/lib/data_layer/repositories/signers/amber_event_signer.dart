import 'dart:async';

import 'package:ndk/ndk.dart';
import 'package:rxdart/rxdart.dart';

import '../../data_sources/amber_flutter.dart';

/// Internal class to track a pending request with its completer
class _PendingRequestEntry {
  final Completer<dynamic> completer;
  final PendingSignerRequest request;
  _PendingRequestEntry(this.completer, this.request);
}

/// amber (external app) https://github.com/greenart7c3/Amber singer
class AmberEventSigner implements EventSigner {
  final AmberFlutterDS amberFlutterDS;

  final String publicKey;

  final _pendingRequests = <String, _PendingRequestEntry>{};
  final _pendingRequestsController =
      BehaviorSubject<List<PendingSignerRequest>>.seeded([]);

  int _requestCounter = 0;

  /// get a amber event signer
  AmberEventSigner({
    required this.publicKey,
    required this.amberFlutterDS,
  });

  String _generateRequestId() {
    return 'amber_${DateTime.now().millisecondsSinceEpoch}_${_requestCounter++}';
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
      signerPubkey: publicKey,
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
  Future<Nip01Event> sign(Nip01Event event) async {
    return _trackRequest(
      SignerMethod.signEvent,
      () async {
        final npub = publicKey.startsWith('npub')
            ? publicKey
            : Nip19.encodePubKey(publicKey);
        Map<dynamic, dynamic> map = await amberFlutterDS.amber.signEvent(
            currentUser: npub,
            eventJson: Nip01EventModel.fromEntity(event).toJsonString(),
            id: event.id);
        return event.copyWith(sig: map['signature']);
      },
      event: event,
    );
  }

  @override
  String getPublicKey() {
    return publicKey;
  }

  @override
  Future<String?> decrypt(String msg, String destPubKey, {String? id}) async {
    return _trackRequest(
      SignerMethod.nip04Decrypt,
      () async {
        final npub = publicKey.startsWith('npub')
            ? publicKey
            : Nip19.encodePubKey(publicKey);
        Map<dynamic, dynamic> map = await amberFlutterDS.amber.nip04Decrypt(
            ciphertext: msg, currentUser: npub, pubKey: destPubKey, id: id);
        return map['signature'];
      },
      ciphertext: msg,
      counterpartyPubkey: destPubKey,
    );
  }

  @override
  Future<String?> encrypt(String msg, String destPubKey, {String? id}) async {
    return _trackRequest(
      SignerMethod.nip04Encrypt,
      () async {
        final npub = publicKey.startsWith('npub')
            ? publicKey
            : Nip19.encodePubKey(publicKey);
        Map<dynamic, dynamic> map = await amberFlutterDS.amber.nip04Encrypt(
            plaintext: msg, currentUser: npub, pubKey: destPubKey, id: id);
        return map['signature'];
      },
      plaintext: msg,
      counterpartyPubkey: destPubKey,
    );
  }

  @override
  bool canSign() {
    return publicKey.isNotEmpty;
  }

  @override
  Future<String?> encryptNip44({
    required String plaintext,
    required String recipientPubKey,
  }) async {
    return _trackRequest(
      SignerMethod.nip44Encrypt,
      () async {
        final userPubkey = publicKey.startsWith('npub')
            ? publicKey
            : Nip19.encodePubKey(publicKey);
        final amberResult = await amberFlutterDS.amber.nip44Encrypt(
          plaintext: plaintext,
          currentUser: userPubkey,
          pubKey: recipientPubKey,
        );

        return amberResult['signature'];
      },
      plaintext: plaintext,
      counterpartyPubkey: recipientPubKey,
    );
  }

  @override
  Future<String?> decryptNip44({
    required String ciphertext,
    required String senderPubKey,
  }) async {
    return _trackRequest(
      SignerMethod.nip44Decrypt,
      () async {
        final userPubkey = publicKey.startsWith('npub')
            ? publicKey
            : Nip19.encodePubKey(publicKey);
        final amberResult = await amberFlutterDS.amber.nip44Decrypt(
          ciphertext: ciphertext,
          currentUser: userPubkey,
          pubKey: senderPubKey,
        );

        return amberResult['signature'];
      },
      ciphertext: ciphertext,
      counterpartyPubkey: senderPubKey,
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

  @override
  Future<void> dispose() async {
    await _pendingRequestsController.close();
  }
}
