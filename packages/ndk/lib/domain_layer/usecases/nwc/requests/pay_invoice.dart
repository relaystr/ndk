import 'package:ndk/domain_layer/usecases/nwc/consts/nwc_method.dart';

import 'nwc_request.dart';

// Subclass for requests to pay a bolt11 invoice
class PayInvoiceRequest extends NwcRequest {
  final String invoice;
  final int? maxFeeSat;

  const PayInvoiceRequest({required this.invoice, int? maxFeeMsat})
      : maxFeeSat = maxFeeMsat == null ? null : maxFeeMsat ~/ 1000,
        super(method: NwcMethod.PAY_INVOICE);

  @override
  Map<String, dynamic> toMap() {
    return {
      ...super.toMap(),
      'params': {
        'invoice': invoice,
        if (maxFeeSat != null) 'max_fee': maxFeeSat! * 1000,
      },
    };
  }
}
