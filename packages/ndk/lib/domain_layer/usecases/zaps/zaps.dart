import 'package:ndk/domain_layer/usecases/nwc/nwc_connection.dart';
import 'package:ndk/domain_layer/usecases/zaps/zap_receipt.dart';

import '../../entities/filter.dart';
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
    required int amount,
    EventSigner? signer,
    Iterable<String>? relays,
    String? pubKey,
    String? eventId,
  }) async {
    String? lud16Link = Lnurl.getLud16LinkFromLud16(lnurl);
    String? invoice = await Lnurl.getInvoiceCode(
        lud16Link: lud16Link!,
        sats: amount,
        pubKey: pubKey,
        eventId: eventId,
        signer: signer,
        relays: relays);
    if (invoice == null) {
      return ZapResponse(error: "couldn't get invoice from $lnurl");
    }
    try {
      PayInvoiceResponse payResponse =
          await _nwc.payInvoice(nwcConnection, invoice: invoice);
      if (payResponse.preimage.isNotEmpty && payResponse.errorCode != null) {
        NdkResponse? receiptResponse;
        if (pubKey != null && relays != null && relays.isNotEmpty) {
          // if it's a zap, try to find the zap receipt
          receiptResponse = _requests.query(explicitRelays: relays, filters: [
            eventId != null
                ? Filter(
                    kinds: [ZapReceipt.KIND], eTags: [eventId], pTags: [pubKey])
                : Filter(kinds: [ZapReceipt.KIND], pTags: [pubKey]),
          ]);

          // TODO:
          //  - The zap receipt event's pubkey MUST be the same as the recipient's lnurl provider's nostrPubkey (retrieved in step 1 of the protocol flow).
          //  - The invoiceAmount contained in the bolt11 tag of the zap receipt MUST equal the amount tag of the zap request (if present).
          //  - The lnurl tag of the zap request (if present) SHOULD equal the recipient's lnurl.
        }
        return ZapResponse(
            zapReceiptResponse: receiptResponse, payInvoiceResponse: payResponse);
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

  ///
  ZapResponse({this.zapReceiptResponse, this.payInvoiceResponse, this.error});
}
