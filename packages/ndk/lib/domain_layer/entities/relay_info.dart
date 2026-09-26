import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../shared/logger/logger.dart';

class RelayInfo {
  final String name;

  final String description;

  /// Nostr public key of the relay admin
  final String pubKey;

  /// Alternative contact of the relay admin
  final String contact;

  /// Supported NIPS
  final List<dynamic> nips;

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
    final List<dynamic> nips = json["supported_nips"] ?? [];
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

  /// Fetches optional relay metadata with a deadline covering connection setup
  /// and the entire response body. A stalled relay must not retain an HTTP
  /// socket after its Nostr connection has been released.
  static Future<RelayInfo?> get(
    String url, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    Uri uri = Uri.parse(url).replace(scheme: 'https');
    final client = http.Client();
    final abort = Completer<void>();
    try {
      final request = http.AbortableRequest(
        'GET',
        uri,
        abortTrigger: abort.future,
      )..headers['Accept'] = 'application/nostr+json';
      final response =
          await (() async {
            return http.Response.fromStream(await client.send(request));
          })().timeout(
            timeout,
            onTimeout: () {
              abort.complete();
              throw TimeoutException(
                'Relay metadata request timed out',
                timeout,
              );
            },
          );
      final decodedResponse =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      return RelayInfo.fromJson(decodedResponse, uri.toString());
    } catch (e) {
      Logger.log.d(() => e);
      return null;
    } finally {
      // Abort covers streamed bodies; closing our private client releases its
      // established sockets and requests cancellation of pending connections.
      client.close();
    }
  }

  /// does this relay support given nip
  bool supportsNip(int nip) {
    return nips.contains(nip);
  }
}
