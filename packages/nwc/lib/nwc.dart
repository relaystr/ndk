import 'dart:async';
import 'dart:convert';

import 'package:ndk/ndk.dart';
import 'package:ndk/shared/logger/logger.dart';
import 'package:ndk/shared/nips/nip04/nip04.dart';
import 'responses/get_balance_response.dart';
import 'responses/get_info_response.dart';
import 'responses/list_transactions_response.dart';
import 'responses/lookup_invoice_response.dart';
import 'responses/pay_invoice_response.dart';
import 'nosrt_wallet_connect_uri.dart';
import 'nwc_connection.dart';
import 'requests/get_balance.dart';
import 'requests/get_info.dart';
import 'requests/list_transactions.dart';
import 'requests/lookup_invoice.dart';
import 'requests/make_invoice.dart';
import 'requests/nwc_request.dart';
import 'requests/pay_invoice.dart';
import 'responses/make_invoice_response.dart';
import 'responses/nwc_response.dart';
import 'consts/nwc_kind.dart';
import 'consts/transaction_type.dart';
import 'consts/nwc_method.dart';
import 'nwc_notification.dart';

/// Main entry point for the NWC (Nostr Wallet Connect) library.
class Nwc {
  static const String NWC_PROTOCOL_PREFIX = "nostr+walletconnect://";

  Ndk _ndk;

  Map<String, Completer<NwcResponse>> _inflighRequests = {};

  Set<NwcConnection> _connections = {};

  Nwc(this._ndk);

  Future<NwcConnection> connect(String uri,
      {bool doGetInfoMethod=false, Function(String?)? onError}) async {
    var parsedUri = NostrWalletConnectUri.parseConnectionUri(uri);
    var relay = Uri.decodeFull(parsedUri.relay);
    var filter =
        Filter(kinds: [NwcKind.INFO.value], authors: [parsedUri.walletPubkey]);

    Completer<NwcConnection> completer = Completer();
    _ndk.requests
        .query(
            name: "nwc-info",
            explicitRelays: [relay],
            filters: [filter],
            timeout: 5,
            cacheRead: false,
            cacheWrite: false)
        .stream
        .listen((event) async {
      if (event.kind == NwcKind.INFO.value && event.content != "") {
        NwcConnection connection = NwcConnection(parsedUri);

        connection.permissions = event.content.split(" ").toSet();

        if (connection.permissions.length == 1) {
          connection.permissions =
              connection.permissions.first.split(",").toSet();
        }

        List<String> versionTags = Nip01Event.getTags(event.tags, "v");
        if (versionTags.isNotEmpty) {
          connection.supportedVersions = versionTags.first.split(" ");
        }

        await subscribeToNotificationsAndResponses(connection);

        if (doGetInfoMethod && connection.permissions.contains(NwcMethod.GET_INFO.name)) {
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

  Future<void> subscribeToNotificationsAndResponses(
      NwcConnection connection) async {
    connection.subscription = _ndk.requests.subscription(
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
        await onLegacyNotification(event, connection);
      } else if (event.kind == NwcKind.RESPONSE.value) {
        await onResponse(event, connection);
      } else if (event.kind == NwcKind.NOTIFICATION.value) {
        await onNotification(event, connection);
      }
      // else ignore
    });
  }

  Future<void> onResponse(Nip01Event event, NwcConnection connection) async {
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
        Logger.log.i("nwc response ${data}");
        response.deserializeError(data);
        connection.responseStream.add(response);
        var eId = event.getEId();
        if (eId != null) {
          Completer<NwcResponse>? completer = _inflighRequests[eId];
          if (completer != null) {
            completer.complete(response);
            _inflighRequests.remove(eId);
          }
        }
      }
    }
  }

  Future<void> onLegacyNotification(
      Nip01Event event, NwcConnection connection) async {
    if (event.content != "") {
      var decrypted = Nip04.decrypt(
          connection.uri.secret, connection.uri.walletPubkey, event.content);
      Map<String, dynamic> data;
      data = json.decode(decrypted);
      if (data.containsKey("notification_type") &&
          data['notification'] != null) {
        NwcNotification notification = NwcNotification.fromMap(data['notification']);
        connection.notificationStream.add(notification);
      } else if (data.containsKey("error")) {
        // TODO ??
      }
    }
  }

  Future<void> onNotification(
      Nip01Event event, NwcConnection connection) async {
    if (event.content != "") {
    // TODO
    //   var decrypted = Nip44.decrypt(
    //       connection.uri.secret, connection.uri.walletPubkey, event.content);
    //   Map<String, dynamic> data;
    //   data = json.decode(decrypted);
    //   if (data.containsKey("notification_type") &&
    //       data['notification'] != null) {
    //     NwcNotification notification = NwcNotification.fromMap(data['notification']);
    //     connection.notificationStream.add(notification);
    //   } else if (data.containsKey("error")) {
    //     // TODO ??
    //   }
    }
  }

  Future<T> _executeRequest<T extends NwcResponse>(
      NwcConnection connection, NwcRequest request) async {
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
      await _ndk.relays
          .broadcastEvent(event, [connection.uri.relay], connection.signer);
      Completer<T> completer = Completer();
      _inflighRequests[event.id] = completer;
      return completer.future;
    }
    throw Exception("${request.method.name} method not in permissions");
  }

  Future<GetInfoResponse> getInfo(NwcConnection connection) async {
    return _executeRequest<GetInfoResponse>(connection, GetInfoRequest());
  }

  Future<GetBalanceResponse> getBalance(NwcConnection connection) async {
    return _executeRequest<GetBalanceResponse>(connection, GetBalanceRequest());
  }

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

  Future<PayInvoiceResponse> payInvoice(NwcConnection connection,
      {required String invoice}) async {
    return _executeRequest<PayInvoiceResponse>(
        connection, PayInvoiceRequest(invoice: invoice));
  }

  Future<LookupInvoiceResponse> lookupInvoice(NwcConnection connection,
      {String? paymentHash, String? invoice}) async {
    return _executeRequest<LookupInvoiceResponse>(connection,
        LookupInvoiceRequest(paymentHash: paymentHash, invoice: invoice));
  }

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

  disconnect(NwcConnection connection) async {
    if (connection.subscription != null) {
      Logger.log.d("closing nwc subscription ${connection}....");
      await _ndk.requests.closeSubscription(connection.subscription!.requestId);
    }
    Logger.log.d("closing nwc streams ${connection}....");
    await connection.responseStream.close();
    await connection.notificationStream.close();
    _connections.remove(connection);
  }

  close() async {
    List<NwcConnection> list = _connections.toList();
    list.forEach((connection) async {
      await disconnect(connection);
    });
  }
}