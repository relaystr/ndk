import 'package:ndk/domain_layer/usecases/nwc/consts/nwc_method.dart';

import 'make_invoice.dart';

class MakeHoldInvoiceRequest extends MakeInvoiceRequest {
  final String paymentHash;

  const MakeHoldInvoiceRequest({
    required super.amountMsat,
    super.description,
    super.descriptionHash,
    super.expiry,
    required this.paymentHash,
  }) : super(method: NwcMethod.MAKE_HOLD_INVOICE);

  @override
  Map<String, dynamic> toMap() {
    final map = super.toMap();
    (map['params'] as Map<String, dynamic>)['payment_hash'] = paymentHash;
    return map;
  }
}
