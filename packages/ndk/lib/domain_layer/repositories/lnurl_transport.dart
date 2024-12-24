import 'package:ndk/domain_layer/usecases/lnurl/lnurl_response.dart';
import 'package:ndk/ndk.dart';

/// transport to get the lnurl response
abstract class LnurlTransport {
  ///  network request to get theLnurl response and invoices
  Future<LnurlResponse?> requestLnurlResponse(String lnurl);

  /// fetch an invoice from lnurl callback endpoint
  Future<Map<String,dynamic>?> fetchInvoice(String callbacklink);
}
