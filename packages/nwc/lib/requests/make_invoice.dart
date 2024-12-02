import 'package:ndk_nwc/consts/nwc_method.dart';

import 'nwc_request.dart';

// Subclass for requests to make a bolt11 invoice
class MakeInvoiceRequest extends NwcRequest {
  final int amountSat;
  final String? description;
  final String? descriptionHash;
  final int? expiry;

  const MakeInvoiceRequest({
    required amountMsat,
    this.description,
    this.descriptionHash,
    this.expiry,
  })  : amountSat = amountMsat ~/ 1000,
        super(method: NwcMethod.MAKE_INVOICE);

  @override
  Map<String, dynamic> toMap() {
    return {
      ...super.toMap(),
      'params': {
        'amount': amountSat * 1000,
        if (description != null) 'description': description,
        if (descriptionHash != null) 'description_hash': descriptionHash,
        if (expiry != null) 'expiry': expiry,
      }
    };
  }
}
