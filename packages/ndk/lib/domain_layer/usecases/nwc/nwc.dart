import 'dart:async';
import 'dart:convert';

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
import 'requests/nwc_request.dart';
import 'requests/pay_invoice.dart';
import 'responses/nwc_response.dart';

/// Main entry point for the NWC (Nostr Wallet Connect - NIP47 ) usecase
class Nwc {
  static const String NWC_PROTOCOL_PREFIX = "nostr+walletconnect://";

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
      {bool doGetInfoMethod = false, Function(String?)? onError}) async {
    var parsedUri = NostrWalletConnectUri.parseConnectionUri(uri);
    var relay = Uri.decodeFull(parsedUri.relay);
    var filter =
        Filter(kinds: [NwcKind.INFO.value], authors: [parsedUri.walletPubkey]);

    Completer<NwcConnection> completer = Completer();

    _requests
        .query(
            name: "nwc-info",
            explicitRelays: [relay],
            filters: [filter],
            timeout: Duration(seconds: 5),
            cacheRead: false,
            cacheWrite: false)
        .stream
        .listen((event) async {
      if (event.kind == NwcKind.INFO.value && event.content != "") {
        final connection = NwcConnection(parsedUri);

        connection.permissions = event.content.split(" ").toSet();

        if (connection.permissions.length == 1) {
          connection.permissions =
              connection.permissions.first.split(",").toSet();
        }

        List<String> versionTags = Nip01Event.getTags(event.tags, "v");
        if (versionTags.isNotEmpty) {
          connection.supportedVersions = versionTags.first.split(" ");
        }

        await _subscribeToNotificationsAndResponses(connection);

        if (doGetInfoMethod &&
            connection.permissions.contains(NwcMethod.GET_INFO.name)) {
          await getInfo(connection).then((info) {
            connection.info = info;
          });
        }
        Logger.log.i("NWC ${connection.uri} connected");
        _connections.add(connection);
        completer.complete(connection);
      }
    });
    return completer.future;
  }

  Future<void> _subscribeToNotificationsAndResponses(
      NwcConnection connection) async {
    connection.subscription = _requests.subscription(
        name: "nwc-sub",
        explicitRelays: [connection.uri.relay],
        filters: [
          Filter(
            kinds: [
              NwcKind.RESPONSE.value,
              connection.isLegacyNotifications()
                  ? NwcKind.LEGACY_NOTIFICATION.value
                  : NwcKind.NOTIFICATION.value,
            ],
            authors: [connection.uri.walletPubkey],
            pTags: [connection.signer.getPublicKey()],
          )
        ],
        cacheRead: false,
        cacheWrite: false);
    connection.subscription!.stream.listen((event) async {
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
      Map<String, dynamic> data;
      data = json.decode(decrypted);
      NwcResponse? response;
      if (data.containsKey("result")) {
        if (data['result_type'] == NwcMethod.GET_INFO.name) {
          response = GetInfoResponse.deserialize(data);
        } else if (data['result_type'] == NwcMethod.GET_BALANCE.name) {
          response = GetBalanceResponse.deserialize(data);
        } else if (data['result_type'] == NwcMethod.MAKE_INVOICE.name) {
          response = MakeInvoiceResponse.deserialize(data);
        } else if (data['result_type'] == NwcMethod.PAY_INVOICE.name) {
          response = PayInvoiceResponse.deserialize(data);
        } else if (data['result_type'] == NwcMethod.LIST_TRANSACTIONS.name) {
          response = ListTransactionsResponse.deserialize(data);
        } else if (data['result_type'] == NwcMethod.LOOKUP_INVOICE.name) {
          response = LookupInvoiceResponse.deserialize(data);
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
            NwcNotification.fromMap(data['notification']);
        connection.notificationStream.add(notification);
      } else if (data.containsKey("error")) {
        // TODO ??
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
            NwcNotification.fromMap(data['notification']);
        connection.notificationStream.add(notification);
      } else if (data.containsKey("error")) {
        // TODO ??
      }
    }
  }

  Future<T> _executeRequest<T extends NwcResponse>(
      NwcConnection connection, NwcRequest request,
      {Duration? timeout}) async {
    if (connection.permissions.contains(request.method.name)) {
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
      final bResponse = _broadcast.broadcast(
        nostrEvent: event,
        specificRelays: [connection.uri.relay],
        customSigner: connection.signer,
      );
      await bResponse.broadcastDoneFuture;

      Completer<NwcResponse> completer = Completer();
      _inflighRequests[event.id] = completer;
      _inflighRequestTimers[event.id] =
          Timer(timeout ?? Duration(seconds: 5), () {
        if (!completer.isCompleted) {
          final error =
              "Timed out while executing NWC request ${request.method.name} with relay ${connection.uri.relay}";
          completer.completeError(error);
          _inflighRequests.remove(event.id);
          _inflighRequestTimers.remove(event.id);
          Logger.log.w(error);
        }
      });
      NwcResponse response = await completer.future;
      if (response is T) {
        return response;
      }
      throw Exception(
          "error ${response.resultType} code: ${response.errorCode} ${response.errorMessage}");
    }
    throw Exception("${request.method.name} method not in permissions");
  }

  /// Does a `get_info` request for returning node detailed info
  Future<GetInfoResponse> getInfo(NwcConnection connection) async {
    return _executeRequest<GetInfoResponse>(connection, GetInfoRequest());
  }

  /// Does a `get_balance` request
  Future<GetBalanceResponse> getBalance(NwcConnection connection) async {
    return _executeRequest<GetBalanceResponse>(connection, GetBalanceRequest());
  }

  /// Does a `make_invoie` request
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
    await connection.responseStream.close();
    await connection.notificationStream.close();
    _connections.remove(connection);
  }

  /// Disconnects all NWC connections
  Future<void> disconnectAll() async {
    await Future.wait(_connections.map(disconnect));
  }
}
