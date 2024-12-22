import 'dart:async';

import 'package:ndk/domain_layer/usecases/nwc/nwc_connection.dart';
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

/// Zaps
class Zaps {
  final Requests _requests;
  final Nwc _nwc;

  Zaps({
    required Requests requests,
    required Nwc nwc,
  })  : _requests = requests,
        _nwc = nwc;

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
      zapRequest = await Lnurl.zapRequest(
          amountSats: amountSats,
          signer: signer,
          pubKey: pubKey,
          comment: comment,
          relays: relays,
          eventId: eventId);
    }
    String? invoice = await Lnurl.getInvoiceCode(
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
          await _nwc.payInvoice(nwcConnection, invoice: invoice, timeout: Duration(seconds: 10));
      if (payResponse.preimage.isNotEmpty && payResponse.errorCode == null) {
        ZapResponse zapResponse = ZapResponse(
            payInvoiceResponse: payResponse);
        if (zapRequest != null && fetchZapReceipt) {
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
              if (receipt.isValid(invoice)) {
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
