import 'package:ndk/domain_layer/usecases/nwc/consts/nwc_method.dart';

import 'nwc_request.dart';

/// Request to pay a Lightning instruction from a BIP-321 URI.
class PayRequest extends NwcRequest {
  /// The BIP-321 payment URI.
  final String payment;

  /// The amount to pay in millisatoshis when the instruction has no amount.
  final int? amountMsat;

  /// The maximum routing fee the sender is willing to pay, in millisatoshis.
  final int? maxFeeMsat;

  /// An optional message from the payer.
  final String? payerNote;

  /// Optional application-defined metadata.
  final Map<String, dynamic>? metadata;

  const PayRequest({
    required this.payment,
    this.amountMsat,
    this.maxFeeMsat,
    this.payerNote,
    this.metadata,
  }) : super(method: NwcMethod.PAY);

  @override
  Map<String, dynamic> toMap() {
    return {
      ...super.toMap(),
      'params': {
        'payment': payment,
        if (amountMsat != null) 'amount': amountMsat,
        if (maxFeeMsat != null) 'max_fee': maxFeeMsat,
        if (payerNote != null) 'payer_note': payerNote,
        if (metadata != null) 'metadata': metadata,
      },
    };
  }
}
