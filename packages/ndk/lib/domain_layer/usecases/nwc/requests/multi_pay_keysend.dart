import 'package:ndk/domain_layer/usecases/nwc/consts/nwc_method.dart';

import '../tlv_record.dart';
import 'nwc_request.dart';

// Subclass for requests to pay multiple keysend payments
class MultiPayKeysendRequest extends NwcRequest {
  final List<MultiPayKeysendRequestInvoicesElement> keysends;

  const MultiPayKeysendRequest({
    required this.keysends,
  }) : super(method: NwcMethod.MULTI_PAY_KEYSEND);

  @override
  Map<String, dynamic> toMap() {
    return {
      ...super.toMap(),
      'params': {
        'keysends': keysends.map((e) => e.toMap()).toList(),
      }
    };
  }
}

class MultiPayKeysendRequestInvoicesElement {
  final String pubkey;
  final int amountSat;
  final String? preimage;
  final List<TlvRecord>? tlvRecords;

  const MultiPayKeysendRequestInvoicesElement({
    required this.pubkey,
    required amountMsat,
    this.preimage,
    this.tlvRecords,
  }) : amountSat = amountMsat ~/ 1000;

  Map<String, dynamic> toMap() {
    return {
      'pubkey': pubkey,
      'amount': amountSat * 1000,
      if (preimage != null) 'preimage': preimage,
      'tlv_records': tlvRecords?.map((e) => e.toMap()).toList(),
    };
  }
}
