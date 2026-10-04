import '../entities/relay_info.dart';

/// repository to fetch NIP-11 relay information
abstract class RelayInfoRepo {
  /// network request to get the [RelayInfo] of the relay at [url];
  /// returns null when it is unavailable
  Future<RelayInfo?> getRelayInfo(String url);
}
