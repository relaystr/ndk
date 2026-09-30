import 'dart:async';
import 'dart:convert';

import 'package:ndk/domain_layer/usecases/nwc/requests/get_budget.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip04/nip04.dart';
import 'package:ndk/shared/nips/nip44/nip44.dart';

import 'consts/nwc_kind.dart';
import 'consts/transaction_type.dart';
import 'nwc_notification.dart';
import 'requests/get_balance.dart';
import 'requests/get_info.dart';
import 'requests/list_transactions.dart';
import 'requests/lookup_invoice.dart';
import 'requests/make_invoice.dart';
import 'requests/make_hold_invoice.dart'; // Add import for MakeHoldInvoiceRequest
import 'requests/cancel_hold_invoice.dart'; // Add import for CancelHoldInvoiceRequest
import 'requests/settle_hold_invoice.dart'; // Add import for SettleHoldInvoiceRequest
import 'requests/nwc_request.dart';
import 'requests/pay.dart';
import 'requests/pay_invoice.dart';
import 'requests/receive.dart';
import 'responses/nwc_response.dart';

/// Main entry point for the NWC (Nostr Wallet Connect - NIP47 ) usecase
///
/// ## Multiple Relay Support
///
/// NWC now supports multiple relays for improved reliability and redundancy.
///
/// ### URI Formats:
/// - Single relay: `nostr+walletconnect://pubkey?relay=wss://relay.com&secret=secret`
/// - Multiple relays: `nostr+walletconnect://pubkey?relays=wss://relay1.com,wss://relay2.com&secret=secret`
/// - Mixed format: `nostr+walletconnect://pubkey?relay=wss://relay1.com&relays=wss://relay2.com,wss://relay3.com&secret=secret`
///
/// When connecting to an NWC wallet with multiple relays, the client will:
/// - Query all relays for the wallet info (kind 13194)
/// - Subscribe to notifications and responses on all relays
/// - Broadcast requests to all relays for redundancy
///
/// This provides better reliability in case some relays are offline or unreachable.
class Nwc {
  static const kNWCProtocolPrefix = "nostr+walletconnect://";

  final Requests _requests;
  final Broadcast _broadcast;
  final LocalEventSignerFactory _eventSignerFactory;
  final Future<void> Function(String requestId, Duration timeout)?
  _waitForRequestSent;

  /// Creates the NWC client. [waitForRequestSent] waits for the response REQ
  /// to be sent on a connected transport. NDK supplies this hook automatically.
  Nwc({
    required Requests requests,
    required Broadcast broadcast,
    required LocalEventSignerFactory eventSignerFactory,
    Future<void> Function(String requestId, Duration timeout)?
    waitForRequestSent,
  }) : _requests = requests,
       _broadcast = broadcast,
       _eventSignerFactory = eventSignerFactory,
       _waitForRequestSent = waitForRequestSent;

  final Map<String, Completer<NwcResponse>> _inflighRequests = {};
  final Map<String, Timer> _inflighRequestTimers = {};

  final Set<NwcConnection> _connections = Set.identity();
  final Map<NwcConnection, int> _activeRequests = Map.identity();
  final Map<NwcConnection, int> _notificationSince = Map.identity();
  final Map<NwcConnection, Set<String>> _seenNotifications = Map.identity();
  Future<void> _subscriptionUpdates = Future.value();
  bool _backgrounded = false;

  /// Suspends idle wallet notifications without interrupting explicit RPCs.
  /// Public streams and connections remain usable. Callers should refresh
  /// balances after resuming: notifications received while suspended are skipped.
  Future<void> setBackgrounded(bool backgrounded) async {
    _backgrounded = backgrounded;
    await Future.wait(_connections.toList().map(_syncSubscription));
  }

  Future<void> _syncSubscription(NwcConnection connection) {
    final operation = _subscriptionUpdates.then((_) async {
      if (!_connections.contains(connection)) return;
      final needed =
          !_backgrounded ||
          (!connection.useETagForEachRequest &&
              (_activeRequests[connection] ?? 0) > 0);
      if (needed) {
        if (connection.subscription == null) {
          await _subscribeToNotificationsAndResponses(connection);
        }
      } else if (connection.subscription != null) {
        final subscription = connection.subscription!;
        connection.subscription = null;
        await connection.cancelSubscriptionListener();
        await _requests.closeSubscription(subscription.requestId);
        // A later resume starts with fresh notifications rather than replaying
        // the wallet's entire relay history and triggering refresh RPC storms.
        _notificationSince[connection] = Nip01Event.secondsSinceEpoch();
      }
      if (_backgrounded && (_activeRequests[connection] ?? 0) == 0) {
        _notificationSince[connection] ??= Nip01Event.secondsSinceEpoch();
      }
    });
    _subscriptionUpdates = operation.catchError((Object _) {});
    return operation;
  }

  /// Connects to a given nostr+walletconnect:// uri,
  /// checking for 13194 event info,
  /// and optionally doing a `get_info` request (default false). When
  /// [requireGetInfoResponse] is true, missing authorization fails connection.
  /// It subscribes for notifications
  Future<NwcConnection> connect(
    String uri, {
    bool doGetInfoMethod = false,
    bool requireGetInfoResponse = false,
    bool useETagForEachRequest = false,
    bool ignoreCapabilitiesCheck = false,
    Function(String?)? onError,
    Duration? timeout,
  }) async {
    if (requireGetInfoResponse && !doGetInfoMethod) {
      throw ArgumentError('requireGetInfoResponse requires doGetInfoMethod');
    }
    final parsedUri = NostrWalletConnectUri.parseConnectionUri(uri);
    final relays = parsedUri.relays.map((r) => Uri.decodeFull(r)).toList();
    var filter = Filter(
      kinds: [NwcKind.INFO.value],
      authors: [parsedUri.walletPubkey],
    );

    Completer<NwcConnection> completer = Completer();

    List<Nip01Event> infoEvent = await _requests
        .query(
          name: "nwc-info",
          explicitRelays: relays,
          filters: [filter],
          timeout: timeout ?? Duration(seconds: 20 + relays.length * 5),
          timeoutCallback: () {
            onError?.call("timeout");
          },
          cacheRead: false,
          cacheWrite: false,
        )
        .future;
    if (infoEvent.isNotEmpty) {
      final event = infoEvent.first;
      final connection = NwcConnection(
        parsedUri,
        eventSignerFactory: _eventSignerFactory,
      );
      connection.useETagForEachRequest = useETagForEachRequest;
      connection.ignoreCapabilitiesCheck = ignoreCapabilitiesCheck;

      connection.permissions = event.content.split(" ").toSet();

      if (connection.permissions.length == 1) {
        connection.permissions = connection.permissions.first
            .split(",")
            .toSet();
      }

      List<String> versionTags = event.getTags('v');
      if (versionTags.isNotEmpty) {
        connection.supportedVersions = versionTags.first.split(" ");
      }
      List<String> encryptions = event.getTags('encryption');
      if (encryptions.isNotEmpty) {
        connection.supportedEncryptions = encryptions.first.split(" ");
      }
      connection.addSupportedExtensions(event.getTags('extensions'));

      _connections.add(connection);
      try {
        await _syncSubscription(connection);
      } catch (_) {
        await disconnect(connection);
        rethrow;
      }

      if (doGetInfoMethod) {
        try {
          if (ignoreCapabilitiesCheck ||
              connection.permissions.contains(NwcMethod.GET_INFO.name)) {
            await getInfo(connection, timeout: timeout);
          } else if (requireGetInfoResponse) {
            throw StateError('Wallet does not advertise get_info');
          }
        } catch (e) {
          onError?.call("timeout get_info");
          if (requireGetInfoResponse) {
            await disconnect(connection);
            rethrow;
          }
        }
      }
      Logger.log.i(() => "NWC ${connection.uri} connected");
      completer.complete(connection);
    } else {
      onError?.call("not found");
      if (requireGetInfoResponse) {
        throw StateError('NWC info event not found');
      }
      completer.complete(
        NwcConnection(parsedUri, eventSignerFactory: _eventSignerFactory),
      );
    }
    return completer.future;
  }

  Future<void> _subscribeToNotificationsAndResponses(
    NwcConnection connection,
  ) async {
    final previousSince = _notificationSince[connection];
    final notificationSince = previousSince == null
        ? null
        : Nip01Event.secondsSinceEpoch();
    // Allow modest wallet clock skew while bounding response history on resume.
    final relaySince = notificationSince == null
        ? null
        : notificationSince - 300;
    connection.subscription = _requests.subscription(
      name: "nwc-sub-${connection.useETagForEachRequest ? "notifs-only" : ""}",
      explicitRelays: connection.uri.relays
          .map((r) => Uri.decodeFull(r))
          .toList(),
      filters: [
        Filter(
          kinds: [
            connection.isLegacyNotifications()
                ? NwcKind.LEGACY_NOTIFICATION.value
                : NwcKind.NOTIFICATION.value,
            if (!connection.useETagForEachRequest) NwcKind.RESPONSE.value,
          ],
          authors: [connection.uri.walletPubkey],
          pTags: [connection.signer.getPublicKey()],
          since: relaySince,
        ),
      ],
      cacheRead: false,
      cacheWrite: false,
    );
    connection.listen((event) async {
      if (event.kind == NwcKind.RESPONSE.value &&
          !_inflighRequests.containsKey(event.getEId())) {
        return;
      }
      if (event.kind != NwcKind.RESPONSE.value &&
          (_backgrounded ||
              (notificationSince != null &&
                  event.createdAt < notificationSince))) {
        return;
      }
      if (event.kind != NwcKind.RESPONSE.value) {
        final seen = _seenNotifications.putIfAbsent(connection, () => {});
        if (!seen.add(event.id)) return;
        if (seen.length > 256) seen.remove(seen.first);
      }
      if (event.kind == NwcKind.LEGACY_NOTIFICATION.value) {
        await _onLegacyNotification(event, connection);
      } else if (event.kind == NwcKind.RESPONSE.value) {
        await _onResponse(event, connection);
      } else if (event.kind == NwcKind.NOTIFICATION.value) {
        await _onNotification(event, connection);
      }
      // else ignore
    });
  }

  Future<void> _onResponse(Nip01Event event, NwcConnection connection) async {
    if (event.content != '') {
      var decrypted = Nip04.decrypt(
        connection.uri.secret,
        connection.uri.walletPubkey,
        event.content,
      );
      if (decrypted == '') {
        decrypted = await Nip44.decryptMessage(
          event.content,
          connection.uri.secret,
          connection.uri.walletPubkey,
        );
      }
      Map<String, dynamic> data;
      data = json.decode(decrypted);
      NwcResponse? response;
      // Some wallets (e.g. rizful) reply to failures with a non-spec
      // `result_type: "error"` and `result: null`; surface the error instead
      // of dropping the reply and letting the request time out.
      if (data['error'] != null || data['result'] == null) {
        response = NwcResponse(resultType: data['result_type'] ?? 'error');
      } else if (data.containsKey("result")) {
        if (data['result_type'] == NwcMethod.GET_INFO.name) {
          response = GetInfoResponse.deserialize(data);
        } else if (data['result_type'] == NwcMethod.GET_BALANCE.name) {
          response = GetBalanceResponse.deserialize(data);
        } else if (data['result_type'] == NwcMethod.GET_BUDGET.name) {
          response = GetBudgetResponse.deserialize(data);
        } else if (data['result_type'] == NwcMethod.MAKE_INVOICE.name ||
            data['result_type'] == NwcMethod.MAKE_HOLD_INVOICE.name) {
          response = MakeInvoiceResponse.deserialize(data);
        } else if (data['result_type'] == NwcMethod.PAY_INVOICE.name) {
          response = PayInvoiceResponse.deserialize(data);
        } else if (data['result_type'] == NwcMethod.PAY.name) {
          response = PayResponse.deserialize(data);
        } else if (data['result_type'] == NwcMethod.RECEIVE.name) {
          response = ReceiveResponse.deserialize(data);
        } else if (data['result_type'] == NwcMethod.LIST_TRANSACTIONS.name) {
          response = ListTransactionsResponse.deserialize(data);
        } else if (data['result_type'] == NwcMethod.LOOKUP_INVOICE.name) {
          response = LookupInvoiceResponse.deserialize(data);
        } else if (data['result_type'] == NwcMethod.CANCEL_HOLD_INVOICE.name ||
            data['result_type'] == NwcMethod.SETTLE_HOLD_INVOICE.name) {
          response = NwcResponse(
            resultType: data['result_type'],
          ); // Generic response
        }
      } else {
        response = NwcResponse(resultType: data['result_type']);
      }
      if (response != null) {
        Logger.log.i(() => "nwc response $data");
        response.deserializeError(data);
        if (connection.responseStream.isClosed) return;
        connection.responseStream.add(response);
        var eId = event.getEId();
        if (eId != null) {
          Timer? timer = _inflighRequestTimers[eId];
          if (timer != null) {
            timer.cancel();
          }
          Completer<NwcResponse>? completer = _inflighRequests[eId];
          if (completer != null) {
            completer.complete(response);
            _inflighRequests.remove(eId);
          }
        }
      }
    }
  }

  Future<void> _onLegacyNotification(
    Nip01Event event,
    NwcConnection connection,
  ) async {
    if (event.content != "") {
      var decrypted = Nip04.decrypt(
        connection.uri.secret,
        connection.uri.walletPubkey,
        event.content,
      );
      Map<String, dynamic> data;
      data = json.decode(decrypted);
      if (data.containsKey("notification_type") &&
          data['notification'] != null) {
        NwcNotification notification = NwcNotification.fromMap(
          data["notification_type"],
          data['notification'],
        );
        if (!_backgrounded && !connection.notificationStream.isClosed) {
          connection.notificationStream.add(notification);
        }
      } else if (data.containsKey("error")) {
        // TODO: Define what to do when data has an error
      }
    }
  }

  Future<void> _onNotification(
    Nip01Event event,
    NwcConnection connection,
  ) async {
    if (event.content != "") {
      final decrypted = await Nip44.decryptMessage(
        event.content,
        connection.uri.secret,
        connection.uri.walletPubkey,
      );
      Map<String, dynamic> data;
      data = json.decode(decrypted);
      if (data.containsKey("notification_type") &&
          data['notification'] != null) {
        NwcNotification notification = NwcNotification.fromMap(
          data["notification_type"],
          data['notification'],
        );
        if (!_backgrounded && !connection.notificationStream.isClosed) {
          connection.notificationStream.add(notification);
        }
      } else if (data.containsKey("error")) {
        // TODO: Define what to do when data has an error
      }
    }
  }

  Future<T> _executeRequest<T extends NwcResponse>(
    NwcConnection connection,
    NwcRequest request, {
    Duration? timeout,
  }) async {
    if (!connection.ignoreCapabilitiesCheck &&
        !connection.permissions.contains(request.method.name)) {
      throw Exception("${request.method.name} method not in permissions");
    }
    var json = request.toMap();
    var content = jsonEncode(json);
    var encrypted = Nip04.encrypt(
      connection.uri.secret,
      connection.uri.walletPubkey,
      content,
    );

    Nip01Event event = Nip01Event(
      pubKey: connection.signer.getPublicKey(),
      kind: NwcKind.REQUEST.value,
      tags: [
        ["p", connection.uri.walletPubkey],
      ],
      content: encrypted,
    );

    if (connection.responseStream.isClosed) {
      throw StateError('NWC connection is closed');
    }
    _connections.add(connection);
    _activeRequests[connection] = (_activeRequests[connection] ?? 0) + 1;
    final completer = Completer<NwcResponse>();
    _inflighRequests[event.id] = completer;
    // A relay can report an error before broadcast bookkeeping completes.
    // Attach a handler immediately; the awaited future still reports it below.
    unawaited(completer.future.then<void>((_) {}, onError: (Object _) {}));
    NdkResponse? dedicatedResponse;
    StreamSubscription<Nip01Event>? dedicatedListener;
    try {
      await _syncSubscription(connection);
      if (connection.useETagForEachRequest) {
        dedicatedResponse = _requests.subscription(
          name: "nwc-response-",
          explicitRelays: connection.uri.relays
              .map((r) => Uri.decodeFull(r))
              .toList(),
          filters: [
            Filter(
              kinds: [NwcKind.RESPONSE.value],
              authors: [connection.uri.walletPubkey],
              pTags: [connection.signer.getPublicKey()],
              eTags: [event.id],
            ),
          ],
          cacheRead: false,
          cacheWrite: false,
        );
        dedicatedListener = dedicatedResponse.stream.listen(
          (responseEvent) async => _onResponse(responseEvent, connection),
          onError: (Object error) {
            if (!completer.isCompleted) completer.completeError(error);
          },
        );
      }
      final budget = timeout ?? const Duration(seconds: 5);
      await _waitForRequestSent?.call(
        (dedicatedResponse ?? connection.subscription!).requestId,
        budget,
      );
      // Connection setup has its own bounded wait. Preserve the full reply
      // budget once publication starts, especially on cold mobile connections.
      _inflighRequestTimers[event.id] = Timer(budget, () {
        if (!completer.isCompleted) {
          completer.completeError(
            "Timed out while executing NWC request ${request.method.name}",
          );
        }
      });
      final bResponse = _broadcast.broadcast(
        nostrEvent: event,
        specificRelays: connection.uri.relays
            .map((r) => Uri.decodeFull(r))
            .toList(),
        customSigner: connection.signer,
        // Requests expire with their caller; durable delivery must never keep
        // wallet relays alive or resend an RPC after its response deadline.
        retryDelivery: false,
        saveToCache: false,
      );
      // A valid wallet reply proves delivery; slow ACK bookkeeping must not
      // keep a background connection alive or turn that reply into a timeout.
      // Future.any also consumes errors arriving after a reply has won.
      final response = await Future.any([
        completer.future,
        bResponse.broadcastDoneFuture.then((_) => completer.future),
      ]);
      if (response is T) return response;
      throw Exception(
        "error ${response.resultType} code: ${response.errorCode} ${response.errorMessage}",
      );
    } finally {
      _inflighRequests.remove(event.id);
      _inflighRequestTimers.remove(event.id)?.cancel();
      final remaining = (_activeRequests[connection] ?? 1) - 1;
      if (remaining == 0) {
        _activeRequests.remove(connection);
      } else {
        _activeRequests[connection] = remaining;
      }
      try {
        await dedicatedListener?.cancel();
        if (dedicatedResponse != null) {
          await _requests.closeSubscription(dedicatedResponse.requestId);
        }
      } catch (_) {
        // Optional listener cleanup must not replace the RPC result or error.
      } finally {
        try {
          await _syncSubscription(connection);
        } catch (_) {}
      }
    }
  }

  /// Does a `get_info` request for returning node detailed info
  Future<GetInfoResponse> getInfo(
    NwcConnection connection, {
    Duration? timeout,
  }) async {
    final info = await _executeRequest<GetInfoResponse>(
      connection,
      GetInfoRequest(),
      timeout: timeout,
    );
    connection.info = info;
    connection.supportedExtensions.addAll(info.extensions);
    return info;
  }

  /// Does a `get_balance` request
  Future<GetBalanceResponse> getBalance(
    NwcConnection connection, {
    Duration? timeout,
  }) async {
    return _executeRequest<GetBalanceResponse>(
      connection,
      GetBalanceRequest(),
      timeout: timeout,
    );
  }

  /// Does a `get_balance` request
  Future<GetBudgetResponse> getBudget(NwcConnection connection) async {
    return _executeRequest<GetBudgetResponse>(connection, GetBudgetRequest());
  }

  /// Does a `make_invoice` request
  Future<MakeInvoiceResponse> makeInvoice(
    NwcConnection connection, {
    required int amountSats,
    String? description,
    String? descriptionHash,
    int? expiry,
  }) async {
    return _executeRequest<MakeInvoiceResponse>(
      connection,
      MakeInvoiceRequest(
        amountMsat: amountSats * 1000,
        description: description,
        descriptionHash: descriptionHash,
        expiry: expiry,
      ),
    );
  }

  /// Does a `make_hold_invoice` request
  Future<MakeInvoiceResponse> makeHoldInvoice(
    NwcConnection connection, {
    required int amountSats,
    String? description,
    String? descriptionHash,
    int? expiry,
    required String paymentHash,
    Duration? timeout,
  }) async {
    return _executeRequest<MakeInvoiceResponse>(
      connection,
      MakeHoldInvoiceRequest(
        amountMsat: amountSats * 1000,
        description: description,
        descriptionHash: descriptionHash,
        expiry: expiry,
        paymentHash: paymentHash,
      ),
      timeout: timeout,
    );
  }

  /// Does a `cancel_hold_invoice` request
  Future<NwcResponse> cancelHoldInvoice(
    NwcConnection connection, {
    required String paymentHash,
  }) async {
    return _executeRequest<NwcResponse>(
      connection,
      CancelHoldInvoiceRequest(paymentHash: paymentHash),
    );
  }

  /// Does a `settle_hold_invoice` request
  Future<NwcResponse> settleHoldInvoice(
    NwcConnection connection, {
    required String preimage,
  }) async {
    return _executeRequest<NwcResponse>(
      connection,
      SettleHoldInvoiceRequest(preimage: preimage),
    );
  }

  /// Does a `pay_invoice` request
  Future<PayInvoiceResponse> payInvoice(
    NwcConnection connection, {
    required String invoice,
    int? maxFeeMsat,
    Duration? timeout,
  }) async {
    return _executeRequest<PayInvoiceResponse>(
      connection,
      PayInvoiceRequest(invoice: invoice, maxFeeMsat: maxFeeMsat),
      timeout: timeout,
    );
  }

  /// Pays a Lightning instruction from a BIP-321 URI using NWC-321.
  Future<PayResponse> pay(
    NwcConnection connection, {
    required String payment,
    int? amountMsat,
    int? maxFeeMsat,
    String? payerNote,
    Map<String, dynamic>? metadata,
    Duration? timeout,
  }) async {
    return _executeRequest<PayResponse>(
      connection,
      PayRequest(
        payment: payment,
        amountMsat: amountMsat,
        maxFeeMsat: maxFeeMsat,
        payerNote: payerNote,
        metadata: metadata,
      ),
      timeout: timeout,
    );
  }

  /// Creates a BIP-321 URI containing a Lightning receive instruction.
  Future<ReceiveResponse> receive(
    NwcConnection connection, {
    int? amountMsat,
    String? description,
    Map<String, dynamic>? metadata,
    Duration? timeout,
  }) async {
    return _executeRequest<ReceiveResponse>(
      connection,
      ReceiveRequest(
        amountMsat: amountMsat,
        description: description,
        metadata: metadata,
      ),
      timeout: timeout,
    );
  }

  /// Does a `lookup_invoice` request
  Future<LookupInvoiceResponse> lookupInvoice(
    NwcConnection connection, {
    String? paymentHash,
    String? invoice,
  }) async {
    return _executeRequest<LookupInvoiceResponse>(
      connection,
      LookupInvoiceRequest(paymentHash: paymentHash, invoice: invoice),
    );
  }

  /// Does a `list_transactions` request
  Future<ListTransactionsResponse> listTransactions(
    NwcConnection connection, {
    int? from,
    int? until,
    int? limit,
    int? offset,
    required bool unpaid,
    TransactionType? type,
  }) async {
    return _executeRequest<ListTransactionsResponse>(
      connection,
      ListTransactionsRequest(
        from: from,
        until: until,
        limit: limit,
        offset: offset,
        unpaid: unpaid,
        type: type,
      ),
    );
  }

  /// Disconnects everything related to this connection,
  /// i.e.: closes response & notification subscription and streams
  Future<void> disconnect(NwcConnection connection) async {
    _connections.remove(connection);
    await _subscriptionUpdates;
    _notificationSince.remove(connection);
    _seenNotifications.remove(connection);
    if (connection.subscription != null) {
      Logger.log.d(() => "closing nwc subscription $connection....");
      await _requests.closeSubscription(connection.subscription!.requestId);
    }
    Logger.log.d(() => "closing nwc streams $connection....");
    await connection.close();
    _connections.remove(connection);
  }

  /// Disconnects all NWC connections
  Future<void> disconnectAll() async {
    await Future.wait(_connections.toList().map(disconnect));
  }
}
