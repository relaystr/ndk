import '../../domain_layer/entities/nip_05.dart';
import '../../domain_layer/repositories/nip_05_repo.dart';
import '../data_sources/http_request.dart';
import '../models/nip_05_model.dart';

/// implementation of the [Nip05Repository] interface with http
class Nip05HttpRepositoryImpl implements Nip05Repository {
  final HttpRequestDS httpDS;

  /// creates a new [Nip05HttpRepositoryImpl] instance
  Nip05HttpRepositoryImpl({required this.httpDS});

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
      json = await httpDS.jsonRequest(identifier.url, followRedirects: false);
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

/// A bare `domain` is the display form of the root identifier `_@domain`.
({String name, String url})? _parseIdentifier(String nip05) {
  final parts = nip05.trim().toLowerCase().split("@");
  final String name;
  final String domain;
  if (parts.length == 1) {
    name = "_";
    domain = parts[0];
  } else if (parts.length == 2) {
    name = parts[0];
    domain = parts[1];
  } else {
    return null;
  }
  if (name.isEmpty || domain.isEmpty) {
    return null;
  }

  final url = Uri.https(domain, "/.well-known/nostr.json", {"name": name});
  return (name: name, url: url.toString());
}
