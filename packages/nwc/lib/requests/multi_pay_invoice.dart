// Subclass for requests to pay multiple bolt11 invoices
import '../consts/nwc_method.dart';
import 'nwc_request.dart';

class MultiPayInvoiceRequest extends NwcRequest {
  final List<MultiPayInvoiceRequestInvoicesElement> invoices;

  const MultiPayInvoiceRequest({
    required this.invoices,
  }) : super(method: NwcMethod.MULTI_PAY_INVOICE);

  @override
  Map<String, dynamic> toMap() {
    return {
      ...super.toMap(),
      'params': {
        'invoices': invoices.map((e) => e.toMap()).toList(),
      }
    };
  }
}


class MultiPayInvoiceRequestInvoicesElement {
  final String invoice;
  final int amountSat;

  const MultiPayInvoiceRequestInvoicesElement({
    required this.invoice,
    required amountMsat,
  }) : amountSat = amountMsat ~/ 1000;

  Map<String, dynamic> toMap() {
    return {
      'params': {
        'invoice': invoice,
        'amount': amountSat * 1000,
      }
    };
  }
}
