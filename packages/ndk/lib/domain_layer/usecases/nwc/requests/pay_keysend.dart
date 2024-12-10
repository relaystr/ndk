import 'package:ndk/domain_layer/usecases/nwc/consts/nwc_method.dart';

import '../tlv_record.dart';
import 'nwc_request.dart';

// Subclass for requests for a keysend payment
class PayKeysendRequest extends NwcRequest {
  final int amountSat;
  final String pubkey;
  final String? preimage;
  final List<TlvRecord>? tlvRecords;

  const PayKeysendRequest({
    required amountMsat,
    required this.pubkey,
    this.preimage,
    this.tlvRecords,
  })  : amountSat = amountMsat ~/ 1000,
        super(method: NwcMethod.PAY_KEYSEND);

  @override
  Map<String, dynamic> toMap() {
    return {
      ...super.toMap(),
      'params': {
        'amount': amountSat * 1000,
        'pubkey': pubkey,
        if (preimage != null) 'preimage': preimage,
        'tlv_records': tlvRecords?.map((e) => e.toMap()).toList(),
      }
    };
  }
}
