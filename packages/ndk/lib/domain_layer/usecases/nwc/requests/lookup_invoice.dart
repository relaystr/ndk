import '../consts/nwc_method.dart';
import 'nwc_request.dart';

// Subclass for requests to look up an invoice
class LookupInvoiceRequest extends NwcRequest {
  final String? paymentHash;
  final String? invoice;

  const LookupInvoiceRequest({
    this.paymentHash,
    this.invoice,
  }) : super(method: NwcMethod.LOOKUP_INVOICE);

  @override
  Map<String, dynamic> toMap() {
    return {
      ...super.toMap(),
      'params' : {
        if (paymentHash != null) 'payment_hash': paymentHash,
        if (invoice != null) 'invoice': invoice,
      }
    };
  }
}
