import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart';
import 'package:ndk/domain_layer/usecases/nwc/nwc_connection.dart';
import 'package:ndk/domain_layer/usecases/zaps/Invoice_response.dart';
import 'package:ndk/domain_layer/usecases/zaps/zap_receipt.dart';
import 'package:ndk/domain_layer/usecases/zaps/zap_request.dart';

import '../../../shared/logger/logger.dart';
import '../../entities/filter.dart';
import '../../entities/nip_01_event.dart';
import '../../entities/request_response.dart';
import '../../repositories/event_signer.dart';
import '../lnurl/lnurl.dart';
import '../nwc/nwc.dart';
import '../nwc/responses/pay_invoice_response.dart';
import '../requests/requests.dart';

import 'package:http/http.dart' as http;

/// Zaps
class Zaps {
  final Requests _requests;
  final Nwc _nwc;

  Zaps({
    required Requests requests,
    required Nwc nwc,
  })  : _requests = requests,
        _nwc = nwc;

  /// creates an invoice with an optional zap request encoded if signer, pubKey & relays are non empty
  Future<InvoiceResponse?> fecthInvoice({
    required String lud16Link,
    required int amountSats,
    ZapRequest? zapRequest,
    String? comment,
    http.Client? client
  }) async {
    var lnurlResponse = await Lnurl.getLnurlResponse(lud16Link, client: client);
    if (lnurlResponse == null) {
      return null;
    }

    var callback = lnurlResponse.callback!;
    if (callback.contains("?")) {
      callback += "&";
    } else {
      callback += "?";
    }

    final amount = amountSats * 1000;
    callback += "amount=$amount";

    if (comment != null && comment.trim() != '') {
      var commentNum = lnurlResponse.commentAllowed;
      if (commentNum != null) {
        if (commentNum < comment.length) {
          comment = comment.substring(0, commentNum);
        }
        callback += "&comment=${Uri.encodeQueryComponent(comment)}";
      }
    }

    // ZAP ?
    if (lnurlResponse.doesAllowsNostr && zapRequest!=null && zapRequest.sig.isNotEmpty) {
      Logger.log.d(jsonEncode(zapRequest));
      var eventStr = Uri.encodeQueryComponent(jsonEncode(zapRequest));
      callback += "&nostr=$eventStr";
    }

    Logger.log.d("getInvoice callback $callback");

    Uri uri = Uri.parse(callback);

    try {
      var response = await (client ?? http.Client()).get(uri);
      final decodedResponse =
      jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      String invoice = decodedResponse["pr"];
      return InvoiceResponse(invoice: invoice, amountSats: amountSats, nostrPubkey: lnurlResponse.nostrPubkey);

    } catch (e) {
      Logger.log.d(e);
    }
    return null;
  }

  Future<ZapRequest> createZapRequest({
    required int amountSats,
    required EventSigner signer,
    required String pubKey,
    String? eventId,
    String? comment,
    required Iterable<String> relays,
    String? pollOption,
  }) async {
    if (amountSats<0) {
      throw ArgumentError("amount cannot be < 0");
    }
    final amount = amountSats * 1000;

    var tags = [
      ["relays", ...relays],
      ["amount", amount.toString()],
      ["p", pubKey],
    ];
    if (eventId != null) {
      tags.add(["e", eventId]);
    }
    if (pollOption != null) {
      tags.add(["poll_option", pollOption]);
    }
    var event = ZapRequest(
        pubKey: signer.getPublicKey(), tags: tags, content: comment??'');
    await signer.sign(event);
    return event;
  }

  /// zap or pay some lnurl, for zap to be created it is necessary:
  /// - that the lnurl has the allowsNostr: true
  /// - non empty relays
  /// - non empty pubKey
  /// - non empty _signer
  Future<ZapResponse> zap({
    required NwcConnection nwcConnection,
    required String lnurl,
    required int amountSats,
    bool fetchZapReceipt = false,
    EventSigner? signer,
    Iterable<String>? relays,
    String? pubKey,
    String? comment,
    String? eventId,
  }) async {
    String? lud16Link = Lnurl.getLud16LinkFromLud16(lnurl);
    ZapRequest? zapRequest;
    if (pubKey != null &&
        signer != null &&
        relays != null &&
        relays.isNotEmpty) {
      zapRequest = await createZapRequest(
          amountSats: amountSats,
          signer: signer,
          pubKey: pubKey,
          comment: comment,
          relays: relays,
          eventId: eventId);
    }
    InvoiceResponse? invoice = await fecthInvoice(
      lud16Link: lud16Link!,
      comment: comment,
      amountSats: amountSats,
      zapRequest: zapRequest,
    );
    if (invoice == null) {
      return ZapResponse(error: "couldn't get invoice from $lnurl");
    }
    try {
      PayInvoiceResponse payResponse =
          await _nwc.payInvoice(nwcConnection, invoice: invoice.invoice, timeout: Duration(seconds: 10));
      if (payResponse.preimage.isNotEmpty && payResponse.errorCode == null) {
        ZapResponse zapResponse = ZapResponse(
            payInvoiceResponse: payResponse);
        if (zapRequest != null && fetchZapReceipt && invoice.nostrPubkey!=null && invoice.nostrPubkey!.isNotEmpty) {
          // if it's a zap, try to find the zap receipt
          zapResponse.receiptResponse = _requests.subscription(filters: [
            eventId != null
                ? Filter(kinds: [ZapReceipt.KIND], eTags: [eventId], pTags: [pubKey!])
                : Filter(kinds: [ZapReceipt.KIND], pTags: [pubKey!])
          ]);
          // TODO make timeout waiting for receipt parameterizable somehow
          final timeout = Timer(Duration(seconds: 30), () {
            _requests.closeSubscription(
                zapResponse.zapReceiptResponse!.requestId);
            Logger.log.w("timed out waiting for zap receipt for invoice $invoice");
          });

          zapResponse.zapReceiptResponse!.stream.listen((event) {
            String? bolt11 = event.getFirstTag("bolt11");
            String? preimage = event.getFirstTag("preimage");
            if (bolt11!=null && bolt11 == invoice || preimage!=null && preimage==payResponse.preimage) {
              ZapReceipt receipt = ZapReceipt.fromEvent(event);
              Logger.log.d("Zap Receipt: $receipt");
              if (receipt.isValid(nostrPubKey: invoice.nostrPubkey!, recipientLnurl: lnurl)) {
                zapResponse.emitReceipt(receipt);
              } else {
                Logger.log.w("Zap Receipt invalid: $receipt");
              }
              timeout.cancel();
              _requests.closeSubscription(
                  zapResponse.zapReceiptResponse!.requestId);
            }
          });
        } else {
          zapResponse.emitReceipt(null);
        }
        return zapResponse;
      }
      return ZapResponse(error: payResponse.errorMessage);
    } catch (e) {
      return ZapResponse(error: e.toString());
    }
  }

  /// fetch all zap receipts matching given pubKey and optional event id, in sats
  Future<List<ZapReceipt>> fetchZappedReceipts(
      {required String pubKey, String? eventId, Duration? timeout}) async {
    NdkResponse? response = _requests.query(timeout: timeout??Duration(seconds:10), filters: [
      eventId != null
          ? Filter(kinds: [ZapReceipt.KIND], eTags: [eventId], pTags: [pubKey])
          : Filter(kinds: [ZapReceipt.KIND], pTags: [pubKey])
    ]);
    List<Nip01Event> events = await response.future;
    // TODO how to check validity of zap receipts without nostrPubKey and recipientLnurl????
    return events.map((event) => ZapReceipt.fromEvent(event)).toList();
  }

  /// fetch all zap receipts matching given pubKey and optional event id, in sats
  NdkResponse subscribeToZapReceipts(
      {required String pubKey, String? eventId}) {
    NdkResponse? response = _requests.subscription(filters: [
      eventId != null
          ? Filter(kinds: [ZapReceipt.KIND], eTags: [eventId], pTags: [pubKey])
          : Filter(kinds: [ZapReceipt.KIND], pTags: [pubKey])
    ]);
    return response;
  }
}

/// zap response
class ZapResponse {
  NdkResponse? zapReceiptResponse;
  PayInvoiceResponse? payInvoiceResponse;
  String? error;
  final _receiptCompleter = Completer<ZapReceipt?>();

  /// the validated zap receipt
  Future<ZapReceipt?> get zapReceipt {
    if (zapReceiptResponse == null) {
      return Future.value(null);
    }
    return _receiptCompleter.future;
  }

  /// emit the receipt
  emitReceipt(ZapReceipt? receipt) {
    _receiptCompleter.complete(receipt);
  }

  ///
  ZapResponse({this.zapReceiptResponse, this.payInvoiceResponse, this.error});

  set receiptResponse(NdkResponse receiptResponse) {
    zapReceiptResponse = receiptResponse;
  }
}