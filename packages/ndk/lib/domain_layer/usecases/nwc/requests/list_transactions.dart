import 'package:ndk/domain_layer/usecases/nwc/consts/nwc_method.dart';

import '../consts/transaction_type.dart';
import 'nwc_request.dart';

// Subclass for requests to get a list of transactions
class ListTransactionsRequest extends NwcRequest {
  final int? from;
  final int? until;
  final int? limit;
  final int? offset;
  final bool unpaid;
  final TransactionType? type;

  const ListTransactionsRequest({
    this.from,
    this.until,
    this.limit,
    this.offset,
    this.unpaid = false,
    this.type,
  }) : super(method: NwcMethod.LIST_TRANSACTIONS);

  @override
  Map<String, dynamic> toMap() {
    return {
      ...super.toMap(),
      'params': {
        if (from != null) 'from': from,
        if (until != null) 'until': until,
        if (limit != null) 'limit': limit,
        if (offset != null) 'offset': offset,
        'unpaid': unpaid,
        if (type != null) 'type': type!.name,
      }
    };
  }
}
