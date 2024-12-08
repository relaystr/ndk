import 'package:ndk/domain_layer/usecases/nwc/consts/nwc_method.dart';

import 'nwc_request.dart';

// Subclass for requests to get balance
class GetBalanceRequest extends NwcRequest {
  const GetBalanceRequest() : super(method: NwcMethod.GET_BALANCE);
}
