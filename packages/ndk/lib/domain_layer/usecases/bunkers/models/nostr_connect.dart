import '../../../../shared/nips/nip01/bip340.dart';
import '../../../../shared/nips/nip01/helpers.dart';
import 'nip46_client_metadata.dart';

class NostrConnect {
  List<String> relays;
  Nip46ClientMetadata? clientMetadata;

  final keyPair = Bip340.generatePrivateKey();
  final secret = Helpers.getSecureRandomHex(16);

  String get nostrConnectURL {
    final pubkey = keyPair.publicKey;

    final params = <String>[];

    for (final relay in relays) {
      params.add('relay=${Uri.encodeComponent(relay)}');
    }

    params.add('secret=$secret');

    final perms = clientMetadata?.perms;
    if (perms != null && perms.isNotEmpty) {
      params.add('perms=${perms.join(',')}');
    }

    clientMetadata?.displayInfo.forEach((key, value) {
      params.add('$key=${Uri.encodeComponent(value)}');
    });

    return 'nostrconnect://$pubkey?${params.join('&')}';
  }

  NostrConnect({
    required this.relays,
    this.clientMetadata,
  }) {
    if (relays.isEmpty) {
      throw ArgumentError("At least one relay is required");
    }
  }
}
