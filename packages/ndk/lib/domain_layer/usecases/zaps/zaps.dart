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
  final EventSigner? _signer;
  final Requests _requests;
  final Nwc _nwc;

  Zaps({
    required Requests requests,
    required Nwc nwc,
    EventSigner? signer,
  })  : _requests = requests,
        _nwc = nwc,
        _signer = signer;

  /// zap or pay some lnurl, for zap to be created it is necessary:
  /// - that the lnurl has the allowsNostr: true
  /// - non empty relays
  /// - non empty pubKey
  /// - non empty _signer
  Future<ZapResponse> zap({
    required NwcConnection nwcConnection,
    required String lnurl,
    required int amount,

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
        signer: _signer,
        relays: relays);
    if (invoice == null) {
      return ZapResponse(error: "couldn't get invoice from $lnurl");
    }
    try {
      PayInvoiceResponse payResponse =
          await _nwc.payInvoice(nwcConnection, invoice: invoice);
      if (payResponse.preimage.isNotEmpty && payResponse.errorCode != null) {
        NdkResponse receiptResponse = _requests.query(filters: [
          Filter(kinds: [ZapReceipt.KIND])
        ]);
        return ZapResponse(
            receiptResponse: receiptResponse, payInvoiceResponse: payResponse);
      }
      return ZapResponse(error: payResponse.errorMessage);
    } catch (e) {
      return ZapResponse(error: e.toString());
    }
  }
}

/// zap response
class ZapResponse {
  NdkResponse? receiptResponse;
  PayInvoiceResponse? payInvoiceResponse;
  String? error;

  ///
  ZapResponse({this.receiptResponse, this.payInvoiceResponse, this.error});
}
