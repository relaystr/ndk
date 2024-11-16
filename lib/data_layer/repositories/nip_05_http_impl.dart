import '../../domain_layer/entities/nip_05.dart';
import '../../domain_layer/repositories/nip_05_repo.dart';
import '../data_sources/http_request.dart';
import '../models/nip_05_model.dart';

/// implementation of the [Nip05Repository] interface with http
class Nip05RepositoryImpl implements Nip05Repository {
  final HttpRequestDS httpDS;

  /// creates a new [Nip05RepositoryImpl] instance
  Nip05RepositoryImpl({required this.httpDS});

  @override
  Future<Nip05?> requestNip05(String nip05, String pubkey) async {
    String username = nip05.split("@")[0];
    String url = nip05.split("@")[1];

    String myUrl = "https://$url/.well-known/nostr.json?name=$username";

    final json = await httpDS.jsonRequest(myUrl);

    Map names = json["names"];

    Map relays = json["relays"] ?? {};

    List<String> pRelays = [];
    if (relays[pubkey] != null) {
      pRelays = List<String>.from(relays[pubkey]);
    }

    bool valid = names[username] == pubkey;

    /// additional check for the case where "_"
    if (!valid) {
      valid = names["_"] == pubkey;
    }

    final result = Nip05Model(
      pubKey: pubkey,
      nip05: nip05,
      valid: valid,
      networkFetchTime: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      relays: pRelays,
    );

    return result;
  }
}
