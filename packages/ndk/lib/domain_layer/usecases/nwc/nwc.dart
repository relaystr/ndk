import 'dart:async';
import 'dart:convert';

import 'package:ndk/domain_layer/usecases/nwc/requests/get_budget.dart';
import 'package:ndk/domain_layer/usecases/nwc/responses/get_budget_response.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip04/nip04.dart';
import 'package:ndk/shared/nips/nip44/nip44.dart';

import 'consts/nwc_kind.dart';
import 'consts/nwc_method.dart';
import 'consts/transaction_type.dart';
import 'nostr_wallet_connect_uri.dart';
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
import 'requests/pay_invoice.dart';
import 'responses/nwc_response.dart';

/// Main entry point for the NWC (Nostr Wallet Connect - NIP47 ) usecase
class Nwc {
  static const kNWCProtocolPrefix = "nostr+walletconnect://";

  final Requests _requests;
  final Broadcast _broadcast;

  /// main constructor
  Nwc({
    required Requests requests,
    required Broadcast broadcast,
  })  : _requests = requests,
        _broadcast = broadcast;

  final Map<String, Completer<NwcResponse>> _inflighRequests = {};
  final Map<String, Timer> _inflighRequestTimers = {};

  final Set<NwcConnection> _connections = {};

  /// Connects to a given nostr+walletconnect:// uri,
  /// checking for 13194 event info,
  /// and optionally doing a `get_info` request (default false).
  /// It subscribes for notifications
  Future<NwcConnection> connect(String uri,
      {bool doGetInfoMethod = false,
      bool useETagForEachRequest = false,
      bool ignoreCapabilitiesCheck = false,
      Function(String?)? onError}) async {
    var parsedUri = NostrWalletConnectUri.parseConnectionUri(uri);
    var relay = Uri.decodeFull(parsedUri.relay);
    var filter =
        Filter(kinds: [NwcKind.INFO.value], authors: [parsedUri.walletPubkey]);

    Completer<NwcConnection> completer = Completer();

    List<Nip01Event> infoEvent = await _requests
        .query(
            name: "nwc-info",
            explicitRelays: [relay],
            filters: [filter],
            timeout: Duration(seconds: 5),
            timeoutCallback: () {
              onError?.call("timeout");
            },
            cacheRead: false,
            cacheWrite: false)
        .future;
    if (infoEvent.isNotEmpty) {
      Nip01Event event = infoEvent.first;
      if (event.kind == NwcKind.INFO.value && event.content != "") {
        final connection = NwcConnection(parsedUri);
        connection.useETagForEachRequest = useETagForEachRequest;
        connection.ignoreCapabilitiesCheck = ignoreCapabilitiesCheck;

        connection.permissions = event.content.split(" ").toSet();

        if (connection.permissions.length == 1) {
          connection.permissions =
              connection.permissions.first.split(",").toSet();
        }

        List<String> versionTags = event.getTags('v');
        if (versionTags.isNotEmpty) {
          connection.supportedVersions = versionTags.first.split(" ");
        }

        await _subscribeToNotificationsAndResponses(connection);

        if (doGetInfoMethod &&
            ignoreCapabilitiesCheck ||
            connection.permissions.contains(NwcMethod.GET_INFO.name)) {
          try {
            await getInfo(connection).then((info) {
              connection.info = info;
            });
          } catch (e) {
            onError?.call("timeout get_info");
          }
        }
        Logger.log.i("NWC ${connection.uri} connected");
        _connections.add(connection);
        completer.complete(connection);
      }
    } else {
      onError?.call("not found");
      completer.complete(NwcConnection(parsedUri));
    }
    return completer.future;
  }

  Future<void> _subscribeToNotificationsAndResponses(
      NwcConnection connection) async {
    List<int> kindsToSubscribe = [
      connection.isLegacyNotifications()
          ? NwcKind.LEGACY_NOTIFICATION.value
          : NwcKind.NOTIFICATION.value,
    ];
    // Only subscribe to NwcKind.RESPONSE if not using tagged subscriptions per request
    if (!connection.useETagForEachRequest) {
      kindsToSubscribe.add(NwcKind.RESPONSE.value);
    }

    connection.subscription = _requests.subscription(
        name:
            "nwc-sub-${connection.useETagForEachRequest ? "notifs-only" : ""}",
        explicitRelays: [connection.uri.relay],
        filters: [
          Filter(
            kinds: kindsToSubscribe,
            authors: [connection.uri.walletPubkey],
            pTags: [connection.signer.getPublicKey()],
          )
        ],
        cacheRead: false,
        cacheWrite: false);
    connection.listen((event) async {
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
          connection.uri.secret, connection.uri.walletPubkey, event.content);
      if (decrypted=='') {
        decrypted = await Nip44.decryptMessage(
          event.content,
          connection.uri.secret,
          connection.uri.walletPubkey,
        );
      }
      Map<String, dynamic> data;
      data = json.decode(decrypted);
      NwcResponse? response;
      if (data.containsKey("result")) {
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
        } else if (data['result_type'] == NwcMethod.LIST_TRANSACTIONS.name) {
          response = ListTransactionsResponse.deserialize(data);
        } else if (data['result_type'] == NwcMethod.LOOKUP_INVOICE.name) {
          response = LookupInvoiceResponse.deserialize(data);
        } else if (data['result_type'] == NwcMethod.CANCEL_HOLD_INVOICE.name ||
            data['result_type'] == NwcMethod.SETTLE_HOLD_INVOICE.name) {
          response =
              NwcResponse(resultType: data['result_type']); // Generic response
        }
      } else {
        response = NwcResponse(resultType: data['result_type']);
      }
      if (response != null) {
        Logger.log.i("nwc response $data");
        response.deserializeError(data);
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
      Nip01Event event, NwcConnection connection) async {
    if (event.content != "") {
      var decrypted = Nip04.decrypt(
          connection.uri.secret, connection.uri.walletPubkey, event.content);
      Map<String, dynamic> data;
      data = json.decode(decrypted);
      if (data.containsKey("notification_type") &&
          data['notification'] != null) {
        NwcNotification notification =
            NwcNotification.fromMap(data["notification_type"],data['notification']);
        connection.notificationStream.add(notification);
      } else if (data.containsKey("error")) {
        // TODO: Define what to do when data has an error
      }
    }
  }

  Future<void> _onNotification(
      Nip01Event event, NwcConnection connection) async {
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
        NwcNotification notification =
            NwcNotification.fromMap(data["notification_type"],data['notification']);
        connection.notificationStream.add(notification);
      } else if (data.containsKey("error")) {
        // TODO: Define what to do when data has an error
      }
    }
  }

  Future<T> _executeRequest<T extends NwcResponse>(
      NwcConnection connection, NwcRequest request,
      {Duration? timeout}) async {
    if (!connection.ignoreCapabilitiesCheck &&
        !connection.permissions.contains(request.method.name)) {
      throw Exception("${request.method.name} method not in permissions");
    }
    var json = request.toMap();
    var content = jsonEncode(json);
    var encrypted = Nip04.encrypt(
        connection.uri.secret, connection.uri.walletPubkey, content);

    Nip01Event event = Nip01Event(
        pubKey: connection.signer.getPublicKey(),
        kind: NwcKind.REQUEST.value,
        tags: [
          ["p", connection.uri.walletPubkey]
        ],
        content: encrypted);

    Completer<NwcResponse> completer = Completer();
    _inflighRequests[event.id] = completer;

    NdkResponse? dedicatedResponse;

    if (connection.useETagForEachRequest) {
      final responseFilter = Filter(
        kinds: [NwcKind.RESPONSE.value],
        authors: [connection.uri.walletPubkey],
        pTags: [connection.signer.getPublicKey()],
        eTags: [event.id], // Tagged with the request event's ID
      );
      dedicatedResponse = _requests.subscription(
          name: "nwc-response-",
          explicitRelays: [connection.uri.relay],
          filters: [responseFilter],
          cacheRead: false,
          cacheWrite: false);

      dedicatedResponse.stream.listen((responseEvent) async {
        await _onResponse(responseEvent, connection);
      }, onError: (error) async {
        if (!completer.isCompleted) {
          completer.completeError(
              "Error on temporary response subscription: $error");
          _inflighRequests.remove(event.id);
          if (_inflighRequestTimers[event.id]?.isActive ?? false) {
            _inflighRequestTimers[event.id]!.cancel();
          }
          _inflighRequestTimers.remove(event.id);
        }
        if (dedicatedResponse!=null) {
          await _requests.closeSubscription(dedicatedResponse.requestId);
        }
      });
    }

    final bResponse = _broadcast.broadcast(
      nostrEvent: event,
      specificRelays: [connection.uri.relay],
      customSigner: connection.signer,
    );
    await bResponse.broadcastDoneFuture;

    _inflighRequestTimers[event.id] =
        Timer(timeout ?? Duration(seconds: 5), () async {
      if (!completer.isCompleted) {
        final error =
            "Timed out while executing NWC request ${request.method.name} with relay ${connection.uri.relay} and eventId ${event.id}"; // Added event.id to log
        completer.completeError(error);
        _inflighRequests.remove(event.id);
        _inflighRequestTimers.remove(event.id);
        if (connection.useETagForEachRequest &&
            dedicatedResponse != null) {
          await _requests.closeSubscription(dedicatedResponse.requestId);
        }
        Logger.log.w(error);
      }
    });

    try {
      NwcResponse response = await completer.future;
      if (connection.useETagForEachRequest &&
          dedicatedResponse != null) {
        await _requests.closeSubscription(dedicatedResponse.requestId);
      }
      if (response is T) {
        return response;
      }
      throw Exception(
          "error ${response.resultType} code: ${response.errorCode} ${response.errorMessage}");
    } catch (e) {
      if (_inflighRequestTimers[event.id]?.isActive ?? false) {
        _inflighRequestTimers[event.id]!.cancel();
      }
      _inflighRequests.remove(event.id);
      _inflighRequestTimers.remove(event.id); // Ensure removal

      if (connection.useETagForEachRequest &&
          dedicatedResponse != null) {
        await _requests.closeSubscription(dedicatedResponse.requestId);
      }
      rethrow;
    }
  }

  /// Does a `get_info` request for returning node detailed info
  Future<GetInfoResponse> getInfo(NwcConnection connection) async {
    return _executeRequest<GetInfoResponse>(connection, GetInfoRequest());
  }

  /// Does a `get_balance` request
  Future<GetBalanceResponse> getBalance(NwcConnection connection) async {
    return _executeRequest<GetBalanceResponse>(connection, GetBalanceRequest());
  }

  /// Does a `get_balance` request
  Future<GetBudgetResponse> getBudget(NwcConnection connection) async {
    return _executeRequest<GetBudgetResponse>(connection, GetBudgetRequest());
  }

  /// Does a `make_invoice` request
  Future<MakeInvoiceResponse> makeInvoice(NwcConnection connection,
      {required int amountSats,
      String? description,
      String? descriptionHash,
      int? expiry}) async {
    return _executeRequest<MakeInvoiceResponse>(
        connection,
        MakeInvoiceRequest(
            amountMsat: amountSats * 1000,
            description: description,
            descriptionHash: descriptionHash,
            expiry: expiry));
  }

  /// Does a `make_hold_invoice` request
  Future<MakeInvoiceResponse> makeHoldInvoice(NwcConnection connection,
      {required int amountSats,
      String? description,
      String? descriptionHash,
      int? expiry,
      required String paymentHash}) async {
    return _executeRequest<MakeInvoiceResponse>(
        connection,
        MakeHoldInvoiceRequest(
            amountMsat: amountSats * 1000,
            description: description,
            descriptionHash: descriptionHash,
            expiry: expiry,
            paymentHash: paymentHash));
  }

  /// Does a `cancel_hold_invoice` request
  Future<NwcResponse> cancelHoldInvoice(NwcConnection connection,
      {required String paymentHash}) async {
    return _executeRequest<NwcResponse>(
        connection, CancelHoldInvoiceRequest(paymentHash: paymentHash));
  }

  /// Does a `settle_hold_invoice` request
  Future<NwcResponse> settleHoldInvoice(NwcConnection connection,
      {required String preimage}) async {
    return _executeRequest<NwcResponse>(
        connection, SettleHoldInvoiceRequest(preimage: preimage));
  }

  /// Does a `pay_invoice` request
  Future<PayInvoiceResponse> payInvoice(NwcConnection connection,
      {required String invoice, Duration? timeout}) async {
    return _executeRequest<PayInvoiceResponse>(
        connection, PayInvoiceRequest(invoice: invoice),
        timeout: timeout);
  }

  /// Does a `lookup_invoice` request
  Future<LookupInvoiceResponse> lookupInvoice(NwcConnection connection,
      {String? paymentHash, String? invoice}) async {
    return _executeRequest<LookupInvoiceResponse>(connection,
        LookupInvoiceRequest(paymentHash: paymentHash, invoice: invoice));
  }

  /// Does a `list_transactions` request
  Future<ListTransactionsResponse> listTransactions(NwcConnection connection,
      {int? from,
      int? until,
      int? limit,
      int? offset,
      required bool unpaid,
      TransactionType? type}) async {
    return _executeRequest<ListTransactionsResponse>(
        connection,
        ListTransactionsRequest(
            from: from,
            until: until,
            limit: limit,
            offset: offset,
            unpaid: unpaid,
            type: type));
  }

  /// Disconnects everything related to this connection,
  /// i.e.: closes response & notification subscription and streams
  Future<void> disconnect(NwcConnection connection) async {
    if (connection.subscription != null) {
      Logger.log.d("closing nwc subscription $connection....");
      await _requests.closeSubscription(connection.subscription!.requestId);
    }
    Logger.log.d("closing nwc streams $connection....");
    await connection.close();
    _connections.remove(connection);
  }

  /// Disconnects all NWC connections
  Future<void> disconnectAll() async {
    await Future.wait(_connections.map(disconnect));
  }
}
