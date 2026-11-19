/// Represents a decoded naddr (addressable event coordinate)
class Naddr {
  final String identifier;
  final String pubkey;
  final int kind;
  final List<String>? relays;

  Naddr({
    required this.identifier,
    required this.pubkey,
    required this.kind,
    this.relays,
  });

  @override
  String toString() =>
      'Naddr(identifier: $identifier, pubkey: $pubkey, kind: $kind, relays: $relays)';
}
