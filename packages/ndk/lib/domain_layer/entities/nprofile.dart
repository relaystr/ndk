/// Represents a decoded nprofile (profile reference)
class Nprofile {
  final String pubkey;
  final List<String>? relays;

  Nprofile({
    required this.pubkey,
    this.relays,
  });

  @override
  String toString() => 'Nprofile(pubkey: $pubkey, relays: $relays)';
}
