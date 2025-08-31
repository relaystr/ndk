import '../../../../shared/nips/nip01/bip340.dart';
import '../../../../shared/nips/nip01/helpers.dart';

class NostrConnect {
  List<String> relays;
  List<String>? perms;
  String? appName;
  String? appUrl;
  String? appImageUrl;

  final keyPair = Bip340.generatePrivateKey();
  final secret = Helpers.getSecureRandomString(16);

  String get nostrConnectURL {
    final pubkey = keyPair.publicKey;

    final params = <String>[];

    for (final relay in relays) {
      params.add('relay=${Uri.encodeComponent(relay)}');
    }

    params.add('secret=$secret');

    if (perms != null && perms!.isNotEmpty) {
      params.add('perms=${perms!.join(',')}');
    }

    if (appName != null) {
      params.add('name=${Uri.encodeComponent(appName!)}');
    }

    if (appUrl != null) {
      params.add('url=${Uri.encodeComponent(appUrl!)}');
    }

    if (appImageUrl != null) {
      params.add('image=${Uri.encodeComponent(appImageUrl!)}');
    }

    return 'nostrconnect://$pubkey?${params.join('&')}';
  }

  NostrConnect({
    required this.relays,
    this.perms,
    this.appName,
    this.appUrl,
    this.appImageUrl,
  }) {
    if (relays.isEmpty) {
      throw ArgumentError("At least one relay is required");
    }
  }
}
