import 'package:ndk/domain_layer/usecases/nwc/consts/nwc_method.dart';

import 'nwc_request.dart';

class SettleHoldInvoiceRequest extends NwcRequest {
  final String preimage;

  const SettleHoldInvoiceRequest({
    required this.preimage,
  }) : super(method: NwcMethod.SETTLE_HOLD_INVOICE);

  @override
  Map<String, dynamic> toMap() {
    return {
      ...super.toMap(),
      'params': {
        'preimage': preimage,
      }
    };
  }
}
