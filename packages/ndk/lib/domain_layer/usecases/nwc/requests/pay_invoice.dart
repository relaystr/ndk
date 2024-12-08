import 'package:ndk/domain_layer/usecases/nwc/consts/nwc_method.dart';

import 'nwc_request.dart';

// Subclass for requests to pay a bolt11 invoice
class PayInvoiceRequest extends NwcRequest {
  final String invoice;

  const PayInvoiceRequest({
    required this.invoice,
  }) : super(method: NwcMethod.PAY_INVOICE);

  @override
  Map<String, dynamic> toMap() {
    return {
      ...super.toMap(),
      'params': {
        'invoice': invoice,
      }
    };
  }
}
