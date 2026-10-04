import '../../domain_layer/entities/relay_info.dart';
import '../../domain_layer/repositories/relay_info_repo.dart';
import '../../shared/logger/logger.dart';
import '../data_sources/http_request.dart';

/// implementation of the [RelayInfoRepo] interface with http
class RelayInfoHttpRepoImpl implements RelayInfoRepo {
  final HttpRequestDS httpDS;

  /// deadline covering connection setup and the entire response body, so a
  /// stalled relay does not retain an HTTP socket
  final Duration timeout;

  /// creates a new [RelayInfoHttpRepoImpl] instance
  RelayInfoHttpRepoImpl({
    required this.httpDS,
    this.timeout = const Duration(seconds: 5),
  });

  @override
  Future<RelayInfo?> getRelayInfo(String url) async {
    try {
      final json = await httpDS.jsonRequest(
        url,
        timeout: timeout,
        headers: const {'Accept': 'application/nostr+json'},
      );
      return RelayInfo.fromJson(
        json,
        Uri.parse(url).replace(scheme: 'https').toString(),
      );
    } catch (e) {
      Logger.log.d(() => e);
      return null;
    }
  }
}
