import 'package:ndk/domain_layer/usecases/nwc/consts/nwc_method.dart';

import 'nwc_request.dart';

// Subclass for requests to get info like supported methods
class GetInfoRequest extends NwcRequest {
  const GetInfoRequest() : super(method: NwcMethod.GET_INFO);
}