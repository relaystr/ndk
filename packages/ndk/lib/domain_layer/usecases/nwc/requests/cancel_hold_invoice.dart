import 'package:ndk/domain_layer/usecases/nwc/consts/nwc_method.dart';

import 'nwc_request.dart';

class CancelHoldInvoiceRequest extends NwcRequest {
  final String paymentHash;

  const CancelHoldInvoiceRequest({
    required this.paymentHash,
  }) : super(method: NwcMethod.CANCEL_HOLD_INVOICE);

  @override
  Map<String, dynamic> toMap() {
    return {
      ...super.toMap(),
      'params': {
        'payment_hash': paymentHash,
      }
    };
  }
}
