/// domain identifier entity
class Nip05 {
  /// null when [identifier] does not exist
  String? pubKey;
  String identifier;

  bool valid;
  int? networkFetchTime;
  List<String>? relays;

  /// creates a new [Nip05] instance
  /// [identifier] the nip05 identifier
  /// [valid] whether the nip05 is valid
  /// [networkFetchTime] the last time the nip05 was checked
  /// [relays] the relays associated with the nip05
  Nip05({
    required this.pubKey,
    required this.identifier,
    this.valid = false,
    this.networkFetchTime,
    this.relays = const [],
  });

  /// Lowercased `name@domain` form of [identifier], or null if malformed.
  /// A bare `domain` is the display form of the root identifier `_@domain`.
  static String? canonicalIdentifier(String identifier) {
    final parts = identifier.trim().toLowerCase().split("@");
    if (parts.length == 1) {
      parts.insert(0, "_");
    }
    if (parts.length != 2 || parts.any((part) => part.isEmpty)) {
      return null;
    }
    return parts.join("@");
  }

  Nip05 copyWith({
    String? pubKey,
    String? identifier,
    bool? valid,
    int? networkFetchTime,
    List<String>? relays,
  }) {
    return Nip05(
      pubKey: pubKey ?? this.pubKey,
      identifier: identifier ?? this.identifier,
      valid: valid ?? this.valid,
      networkFetchTime: networkFetchTime ?? this.networkFetchTime,
      relays: relays ?? this.relays,
    );
  }
}
