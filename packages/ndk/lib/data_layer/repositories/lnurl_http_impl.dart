import 'package:ndk/domain_layer/repositories/lnurl_transport.dart';
import 'package:ndk/domain_layer/usecases/lnurl/lnurl_response.dart';

import '../../domain_layer/repositories/nip_05_repo.dart';
import '../../shared/logger/logger.dart';
import '../data_sources/http_request.dart';

/// implementation of the [Nip05Repository] interface with http
class LnurlTransportHttpImpl implements LnurlTransport {
  final HttpRequestDS httpDS;

  /// constructor
  LnurlTransportHttpImpl(this.httpDS);

  @override
  Future<LnurlResponse?> requestLnurlResponse(String lnurl) async {
    try {
      final response = await httpDS.jsonRequest(lnurl);
      return LnurlResponse.fromJson(response);
    } catch (e) {
      Logger.log.w(e);
      return null;
    }
  }

  @override
  Future<Map<String,dynamic>?> fetchInvoice(String callbacklink) async {
    try {
      return await httpDS.jsonRequest(callbacklink);
    } catch (e) {
      Logger.log.d(e);
      return null;
    }
  }

}
