import 'package:http/http.dart' as http;

import '../../data_layer/data_sources/http_request.dart';
import '../../data_layer/repositories/relay_info_http_impl.dart';

class RelayInfo {
  final String name;

  final String description;

  /// Nostr public key of the relay admin
  final String pubKey;

  /// Alternative contact of the relay admin
  final String contact;

  /// Supported NIPs, normalized by [normalizeNip]
  final List<String> nips;

  /// Software description
  final String software;

  /// Relay icon
  final String icon;

  /// Relay software version identifier
  final String version;

  final String privacyPolicy;
  final String termsOfService;

  RelayInfo._(
    this.name,
    this.description,
    this.pubKey,
    this.contact,
    this.nips,
    this.software,
    this.version,
    this.icon,
    this.privacyPolicy,
    this.termsOfService,
  );

  factory RelayInfo.fromJson(Map<String, dynamic> json, String url) {
    final String name = json["name"] ?? '';
    final String description = json["description"] ?? "";
    final String pubKey = json["pubkey"] ?? "";
    final String contact = json["contact"] ?? "";
    String icon;
    if (json["icon"] != null) {
      icon = json["icon"];
    } else {
      icon = "$url${url.endsWith("/") ? "" : "/"}favicon.ico";
    }
    final List<String> nips = [
      for (final nip in json["supported_nips"] ?? []) normalizeNip(nip),
    ];
    final String software = json["software"] ?? "";
    final String version = json["version"] ?? "";
    final String privacyPolicy = json["privacy_policy"] ?? "";
    final String termsOfService = json["terms_of_service"] ?? "";
    return RelayInfo._(
      name,
      description,
      pubKey,
      contact,
      nips,
      software,
      version,
      icon,
      privacyPolicy,
      termsOfService,
    );
  }

  /// Fetches relay metadata with a private HTTP client that is closed
  /// afterwards.
  @Deprecated('Use Ndk.relays.getRelayInfo or RelayInfoHttpRepoImpl instead')
  static Future<RelayInfo?> get(
    String url, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final client = http.Client();
    try {
      return await RelayInfoHttpRepoImpl(
        httpDS: HttpRequestDS(client),
        timeout: timeout,
      ).getRelayInfo(url);
    } finally {
      client.close();
    }
  }

  /// does this relay support given nip, e.g. "1", "01", "77" or "EE"
  bool supportsNip(String nip) {
    return nips.contains(normalizeNip(nip));
  }

  /// Relays list NIPs as ints (1) or strings ("01", "7D", "ee").
  static String normalizeNip(Object nip) {
    return nip.toString().trim().toUpperCase().replaceFirst(
      RegExp(r'^0+(?=.)'),
      '',
    );
  }
}
