import 'package:ndk/domain_layer/usecases/nwc/consts/nwc_method.dart';

import 'nwc_request.dart';

/// Request to create a BIP-321 URI containing a Lightning receive instruction.
class ReceiveRequest extends NwcRequest {
  /// The requested amount in millisatoshis, or null for a variable amount.
  final int? amountMsat;

  /// An optional description for the payment instruction.
  final String? description;

  /// Optional application-defined metadata.
  final Map<String, dynamic>? metadata;

  const ReceiveRequest({this.amountMsat, this.description, this.metadata})
      : super(method: NwcMethod.RECEIVE);

  @override
  Map<String, dynamic> toMap() {
    return {
      ...super.toMap(),
      'params': {
        if (amountMsat != null) 'amount': amountMsat,
        if (description != null) 'description': description,
        if (metadata != null) 'metadata': metadata,
      },
    };
  }
}
