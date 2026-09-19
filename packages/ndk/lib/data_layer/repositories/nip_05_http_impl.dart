import '../../config/nip_05_defaults.dart';
import '../../domain_layer/entities/nip_05.dart';
import '../../domain_layer/repositories/nip_05_repo.dart';
import '../data_sources/http_request.dart';
import '../models/nip_05_model.dart';

/// implementation of the [Nip05Repository] interface with http
class Nip05HttpRepositoryImpl implements Nip05Repository {
  final HttpRequestDS httpDS;

  /// how long to wait for a nostr.json response
  final Duration timeout;

  /// creates a new [Nip05HttpRepositoryImpl] instance
  Nip05HttpRepositoryImpl({
    required this.httpDS,
    this.timeout = NIP_05_REQUEST_TIMEOUT,
  });

  @override
  Future<Nip05?> requestNip05(String nip05, String pubkey) async {
    final identifier = _parseIdentifier(nip05);
    if (identifier == null) {
      return null;
    }

    // NIP-05: fetchers MUST ignore HTTP redirects
    final json = await httpDS.jsonRequest(
      identifier.url,
      followRedirects: false,
      timeout: timeout,
    );

    Map names = json["names"];

    Map relays = json["relays"] ?? {};

    List<String> pRelays = [];
    if (relays[pubkey] != null) {
      pRelays = List<String>.from(relays[pubkey]);
    }

    bool valid = names[identifier.name] == pubkey;

    final result = Nip05Model(
      pubKey: pubkey,
      nip05: nip05,
      valid: valid,
      networkFetchTime: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      relays: pRelays,
    );

    return result;
  }

  @override
  Future<Nip05?> fetchNip05(String nip05) async {
    final identifier = _parseIdentifier(nip05);
    if (identifier == null) {
      return null;
    }

    final Map<String, dynamic> json;
    try {
      json = await httpDS.jsonRequest(
        identifier.url,
        followRedirects: false,
        timeout: timeout,
      );
    } on HttpRequestException catch (e) {
      if (e.statusCode == 404) {
        return null;
      }
      rethrow;
    }

    Map names = json["names"];
    Map relays = json["relays"] ?? {};

    String? pubkey = names[identifier.name];

    if (pubkey == null) {
      return null;
    }

    List<String> pRelays = [];
    if (relays[pubkey] != null) {
      pRelays = List<String>.from(relays[pubkey]);
    }

    return Nip05Model(
      pubKey: pubkey,
      nip05: nip05,
      valid: true,
      networkFetchTime: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      relays: pRelays,
    );
  }
}

({String name, String url})? _parseIdentifier(String nip05) {
  final canonical = Nip05.canonicalIdentifier(nip05);
  if (canonical == null) {
    return null;
  }
  final [name, domain] = canonical.split("@");

  final url = Uri.https(domain, "/.well-known/nostr.json", {"name": name});
  return (name: name, url: url.toString());
}
