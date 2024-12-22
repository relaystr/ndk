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
          await _nwc.payInvoice(nwcConnection, invoice: invoice);
      if (payResponse.preimage.isNotEmpty && payResponse.errorCode == null) {
        NdkResponse? receiptResponse;
        if (zapRequest != null) {
          // if it's a zap, try to find the zap receipt
          receiptResponse = _requests.query(explicitRelays: relays, filters: [
            Filter(
                kinds: [ZapReceipt.KIND],
                eTags: [eventId!],
                pTags: [pubKey!])
          ]);
        }
        ZapResponse zapResponse = ZapResponse(
            zapReceiptResponse: receiptResponse,
            payInvoiceResponse: payResponse);
        if (receiptResponse != null) {
          receiptResponse.future.then((events) {
            Nip01Event? event = events.where((event) {
              ZapReceipt receipt = ZapReceipt.fromEvent(event);
              return receipt.bolt11 == invoice;
            }).firstOrNull;
            if (event!=null) {
              ZapReceipt receipt = ZapReceipt.fromEvent(event);
              Logger.log.d("Zap Receipt: $receipt");
              if (receipt.isValid(invoice)) {
                zapResponse.emitReceipt(receipt);
                return;
              }
              Logger.log.w("Zap Receipt invalid: $receipt");
            }
            zapResponse.emitReceipt(null);
          });
        }
        return zapResponse;
      }
      return ZapResponse(error: payResponse.errorMessage);
    } catch (e) {
      return ZapResponse(error: e.toString());
    }
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
}
