import 'package:equatable/equatable.dart';

/// Represents a parsed Nostr Wallet Connect URI with support for multiple relays
///
/// ## Supported URI Formats:
///
/// ### Single Relay (backward compatible):
/// ```
/// nostr+walletconnect://pubkey?relay=wss://relay.example.com&secret=secret123
/// ```
///
/// ### Multiple Relays (comma-separated):
/// ```
/// nostr+walletconnect://pubkey?relays=wss://relay1.com,wss://relay2.com&secret=secret123
/// ```
///
/// ### Mixed Format (relay + relays parameters):
/// ```
/// nostr+walletconnect://pubkey?relay=wss://relay1.com&relays=wss://relay2.com,wss://relay3.com&secret=secret123
/// ```
///
/// ## Usage Examples:
///
/// ```dart
/// // Parse existing URI
/// final connection = await nwc.connect('nostr+walletconnect://pubkey?relays=wss://relay1.com,wss://relay2.com&secret=secret123');
///
/// // Create new multi-relay URI
/// final uri = NostrWalletConnectUri.createMultiRelay(
///   walletPubkey: 'pubkey123',
///   relays: ['wss://relay1.example.com', 'wss://relay2.example.com'],
///   secret: 'secret123'
/// );
/// final uriString = uri.toUri();
/// ```
class NostrWalletConnectUri extends Equatable {
  final String walletPubkey;
  final List<String> relays;
  final String secret;
  final String? lud16;

  const NostrWalletConnectUri({
    required this.walletPubkey,
    required this.relays,
    required this.secret,
    this.lud16,
  });

  /// Legacy constructor for backward compatibility with single relay
  @Deprecated('Use the new constructor with relays list instead')
  factory NostrWalletConnectUri.legacy({
    required String walletPubkey,
    required String relay,
    required String secret,
    String? lud16,
  }) =>
      NostrWalletConnectUri(
        walletPubkey: walletPubkey,
        relays: [relay],
        secret: secret,
        lud16: lud16,
      );

  /// Legacy getter for backward compatibility
  @Deprecated('Use relays list instead')
  String get relay => relays.isNotEmpty ? relays.first : '';

  factory NostrWalletConnectUri.parseConnectionUri(String uri) {
    Uri parsedUri = Uri.parse(uri);

    String pubkey = parsedUri.host; // _extractPubkey(parsedUri.toString());
    String? secret = parsedUri.queryParameters['secret'];
    String? lud16 = parsedUri.queryParameters['lud16'];

    if (pubkey.isEmpty ||
        secret == null ||
        parsedUri.scheme != 'nostr+walletconnect') {
      throw Exception(
          "Required fields (scheme, pubkey, secret) are missing or incorrect in the connection URI.");
    }

    // Parse relays - support both single relay and comma-separated relays
    List<String> relaysList = [];

    // Check for single relay parameter (backward compatibility)
    List<String>? relayParams = parsedUri.queryParametersAll['relay'];
    if (relayParams != null) {
      for (var relay in relayParams) {
        List<String> commaSeparatedRelays = relay
            .split(',')
            .map((r) => r.trim())
            .where((r) => r.isNotEmpty)
            .toList();
        for (String relay in commaSeparatedRelays) {
          if (!relaysList.contains(relay)) {
            relaysList.add(relay);
          }
        }
      }
    }

    // Check for comma-separated relays in a single parameter
    String? relaysParam = parsedUri.queryParameters['relays'];
    if (relaysParam != null) {
      List<String> commaSeparatedRelays = relaysParam
          .split(',')
          .map((r) => r.trim())
          .where((r) => r.isNotEmpty)
          .toList();
      for (String relay in commaSeparatedRelays) {
        if (!relaysList.contains(relay)) {
          relaysList.add(relay);
        }
      }
    }

    if (relaysList.isEmpty) {
      throw Exception("At least one relay is required in the connection URI.");
    }

    return NostrWalletConnectUri(
      walletPubkey: pubkey,
      relays: relaysList,
      secret: secret,
      lud16: lud16,
    );
  }

  // static String? _extractPubkey(String uri) {
  //   final RegExp regex = RegExp(r'nostr\+walletconnect:\/\/([^?]+)');
  //   final Match? match = regex.firstMatch(uri);
  //   return match?.group(1);
  // }

  /// Creates a NWC URI string from the components
  /// Supports both single and multiple relays
  String toUri() {
    final buffer = StringBuffer('nostr+walletconnect://$walletPubkey?');
    final params = <String>[];

    // Add relays - use comma-separated format for multiple relays
    params.add('relays=${Uri.encodeComponent(relays.join(','))}');

    params.add('secret=${Uri.encodeComponent(secret)}');

    if (lud16 != null) {
      params.add('lud16=${Uri.encodeComponent(lud16!)}');
    }

    buffer.write(params.join('&'));
    return buffer.toString();
  }

  /// Creates a NWC URI with multiple relays
  /// Example: NostrWalletConnectUri.createMultiRelay(
  ///   walletPubkey: 'pubkey123',
  ///   relays: ['wss://relay1.com', 'wss://relay2.com'],
  ///   secret: 'secret123'
  /// )
  factory NostrWalletConnectUri.createMultiRelay({
    required String walletPubkey,
    required List<String> relays,
    required String secret,
    String? lud16,
  }) {
    if (relays.isEmpty) {
      throw ArgumentError('At least one relay must be provided');
    }
    return NostrWalletConnectUri(
      walletPubkey: walletPubkey,
      relays: relays,
      secret: secret,
      lud16: lud16,
    );
  }

  @override
  List<Object?> get props => [
        walletPubkey,
        relays,
        secret,
      ];
}
