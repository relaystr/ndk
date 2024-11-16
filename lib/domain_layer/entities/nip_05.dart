/// domain identifier entity
class Nip05 {
  String pubKey;
  String nip05;

  bool valid;
  int? networkFetchTime;
  List<String>? relays;

  /// creates a new [Nip05] instance
  /// [nip05] the nip05 identifier
  /// [valid] whether the nip05 is valid
  /// [networkFetchTime] the last time the nip05 was checked
  /// [relays] the relays associated with the nip05
  Nip05({
    required this.pubKey,
    required this.nip05,
    this.valid = false,
    this.networkFetchTime,
    this.relays = const [],
  });
}
