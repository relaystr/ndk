import 'package:equatable/equatable.dart';

class NostrWalletConnectUri extends Equatable {
  final String walletPubkey;
  final String relay;
  final String secret;
  final String? lud16;

  const NostrWalletConnectUri({
    required this.walletPubkey,
    required this.relay,
    required this.secret,
    this.lud16,
  });

  factory NostrWalletConnectUri.parseConnectionUri(String uri) {
    Uri parsedUri = Uri.parse(uri);

    String? pubkey = _extractPubkey(parsedUri.toString());
    String? relayUrl = parsedUri.queryParameters['relay'];
    String? secret = parsedUri.queryParameters['secret'];
    String? lud16 = parsedUri.queryParameters['lud16'];

    if (pubkey == null || relayUrl == null || secret == null) {
      throw Exception(
          "Required fields (pubkey, relay, secret) are missing in the connection URI.");
    }

    return NostrWalletConnectUri(
      walletPubkey: pubkey,
      relay: relayUrl,
      secret: secret,
      lud16: lud16,
    );
  }

  static String? _extractPubkey(String uri) {
    int startIndex = uri.indexOf('//') + 2;
    int endIndex = uri.indexOf('?');
    return uri.substring(startIndex, endIndex);
  }

  @override
  List<Object?> get props => [
        walletPubkey,
        relay,
        secret,
      ];
}
