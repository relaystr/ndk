import 'dart:async';

import 'package:ndk/ndk.dart';
import 'package:rxdart/rxdart.dart';

import '../../data_sources/nip55_signer.dart';

/// Internal class to track a pending request with its completer
class _PendingRequestEntry {
  final Completer<dynamic> completer;
  final PendingSignerRequest request;
  _PendingRequestEntry(this.completer, this.request);
}

/// Event signer backed by a NIP-55 external signer application.
///
/// NIP-55 is a protocol implemented by several external signer apps.
/// This signer delegates all cryptographic
/// operations to whichever compatible signer is installed via [Nip55Signer].
class Nip55EventSigner with ConcurrencyLimiterMixin implements EventSigner {
  final Nip55Signer nip55Signer;

  final String publicKey;

  final _pendingRequests = <String, _PendingRequestEntry>{};
  final _pendingRequestsController =
      BehaviorSubject<List<PendingSignerRequest>>.seeded([]);

  int _requestCounter = 0;

  @override
  final int maxConcurrentRequests;

  /// Default external-signer concurrency. Lower this if you target a flow that
  /// prompts the user via Android intents for every request.
  static const int defaultMaxConcurrentRequests = 100;

  /// get a NIP-55 external signer
  Nip55EventSigner({
    required this.publicKey,
    required this.nip55Signer,
    this.maxConcurrentRequests = defaultMaxConcurrentRequests,
  }) : assert(maxConcurrentRequests > 0, 'maxConcurrentRequests must be > 0');

  /// NIP-55 expects pubkeys in hex format ("All pubkeys in this NIP are in hex
  /// format"), so `current_user` is always sent as hex.
  String get _currentUser =>
      publicKey.startsWith('npub') ? Nip19.decode(publicKey) : publicKey;

  String _extractResult(Map<dynamic, dynamic> map) {
    final result = map['signature'] as String?;
    if (result == null || result.isEmpty) {
      throw Exception('Empty result from external signer');
    }
    return result;
  }

  String _generateRequestId() {
    return 'nip55_${DateTime.now().millisecondsSinceEpoch}_${_requestCounter++}';
  }

  void _notifyPendingRequestsChange() {
    _pendingRequestsController.add(
      _pendingRequests.values.map((e) => e.request).toList(),
    );
  }

  /// Wraps an async operation to track it as a pending request
  Future<T> _trackRequest<T>(
    SignerMethod method,
    Future<T> Function() operation, {
    Nip01Event? event,
    String? plaintext,
    String? ciphertext,
    String? counterpartyPubkey,
  }) {
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

    // Throttle the actual call to the signer; queued requests still appear in
    // `pendingRequests` so the UI sees the full backlog. If the request was
    // cancelled while queued, skip the signer call entirely.
    runThrottled(() async {
          if (!_pendingRequests.containsKey(requestId)) {
            throw SignerRequestCancelledException(requestId);
          }
          return await operation();
        })
        .then((result) {
          if (!completer.isCompleted) {
            completer.complete(result);
          }
        })
        .catchError((e) {
          if (!completer.isCompleted) {
            final error = SignerRequestRejectedException(requestId: requestId);
            completer.completeError(error);
          }
        })
        .whenComplete(() {
          _pendingRequests.remove(requestId);
          _notifyPendingRequestsChange();
        });

    return completer.future;
  }

  @override
  Future<Nip01Event> sign(Nip01Event event) async {
    return _trackRequest(SignerMethod.signEvent, () async {
      final map = await nip55Signer.signEvent(
        currentUser: _currentUser,
        eventJson: Nip01EventModel.fromEntity(event).toJsonString(),
        id: event.id,
      );
      return event.copyWith(sig: _extractResult(map));
    }, event: event);
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
        final map = await nip55Signer.nip04Decrypt(
          ciphertext: msg,
          currentUser: _currentUser,
          pubKey: destPubKey,
          id: id,
        );
        return _extractResult(map);
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
        final map = await nip55Signer.nip04Encrypt(
          plaintext: msg,
          currentUser: _currentUser,
          pubKey: destPubKey,
          id: id,
        );
        return _extractResult(map);
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
  bool get requiresInteractiveSigning => true;

  @override
  bool get requiresSignerNetwork => false;

  @override
  Iterable<String> get signerTransportRelayUrls => const <String>[];

  @override
  Future<String?> encryptNip44({
    required String plaintext,
    required String recipientPubKey,
  }) async {
    return _trackRequest(
      SignerMethod.nip44Encrypt,
      () async {
        final map = await nip55Signer.nip44Encrypt(
          plaintext: plaintext,
          currentUser: _currentUser,
          pubKey: recipientPubKey,
        );
        return _extractResult(map);
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
        final map = await nip55Signer.nip44Decrypt(
          ciphertext: ciphertext,
          currentUser: _currentUser,
          pubKey: senderPubKey,
        );
        return _extractResult(map);
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
    cancelAllQueued();
    await _pendingRequestsController.close();
  }
}
