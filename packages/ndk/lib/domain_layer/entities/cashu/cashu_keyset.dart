class CahsuKeyset {
  final String id;
  final String mintUrl;
  final String unit;
  final bool active;
  final int inputFeePPK;
  final Set<CahsuMintKeyPair> mintKeyPairs;
  int? fetchedAt;

  CahsuKeyset({
    required this.id,
    required this.mintUrl,
    required this.unit,
    required this.active,
    required this.inputFeePPK,
    required this.mintKeyPairs,
    this.fetchedAt,
  }) {
    fetchedAt ??= DateTime.now().millisecondsSinceEpoch ~/ 1000;
  }

  factory CahsuKeyset.fromResponses({
    required CahsuKeysetResponse keysetResponse,
    required CahsuKeysResponse keysResponse,
  }) {
    if (keysetResponse.id != keysResponse.id ||
        keysetResponse.mintUrl != keysResponse.mintUrl ||
        keysetResponse.unit != keysResponse.unit) {
      throw ArgumentError('Keyset and keys responses do not match');
    }

    return CahsuKeyset(
      id: keysetResponse.id,
      mintUrl: keysetResponse.mintUrl,
      unit: keysetResponse.unit,
      active: keysetResponse.active,
      inputFeePPK: keysetResponse.inputFeePPK,
      mintKeyPairs: keysResponse.mintKeyPairs,
    );
  }

  factory CahsuKeyset.fromJson(Map<String, dynamic> json) {
    return CahsuKeyset(
      id: json['id'] as String,
      mintUrl: json['mintUrl'] as String,
      unit: json['unit'] as String,
      active: json['active'] as bool,
      inputFeePPK: json['inputFeePPK'] as int,
      mintKeyPairs: (json['mintKeyPairs'] as List<dynamic>)
          .map((e) => CahsuMintKeyPair(
                amount: e['amount'] as int,
                pubkey: e['pubkey'] as String,
              ))
          .toSet(),
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'mintUrl': mintUrl,
      'unit': unit,
      'active': active,
      'inputFeePPK': inputFeePPK,
      'mintKeyPairs': mintKeyPairs
          .map((pair) => {'amount': pair.amount, 'pubkey': pair.pubkey})
          .toList(),
      'fetchedAt': fetchedAt,
    };
  }
}

class CahsuMintKeyPair {
  final int amount;
  final String pubkey;

  CahsuMintKeyPair({
    required this.amount,
    required this.pubkey,
  });
}

class CahsuKeysetResponse {
  final String id;
  final String mintUrl;
  final String unit;
  final bool active;
  final int inputFeePPK;

  CahsuKeysetResponse({
    required this.id,
    required this.mintUrl,
    required this.unit,
    required this.active,
    required this.inputFeePPK,
  });

  factory CahsuKeysetResponse.fromServerMap({
    required Map<String, dynamic> map,
    required String mintUrl,
  }) {
    return CahsuKeysetResponse(
      id: map['id'] as String,
      mintUrl: mintUrl,
      unit: map['unit'] as String,
      active: map['active'] as bool,
      inputFeePPK: map['input_fee_ppk'] as int,
    );
  }
}

class CahsuKeysResponse {
  final String id;
  final String mintUrl;
  final String unit;
  final Set<CahsuMintKeyPair> mintKeyPairs;

  CahsuKeysResponse({
    required this.id,
    required this.mintUrl,
    required this.unit,
    required this.mintKeyPairs,
  });

  factory CahsuKeysResponse.fromServerMap({
    required Map<String, dynamic> map,
    required String mintUrl,
  }) {
    final mintKeyPairs = <CahsuMintKeyPair>{};
    final keys = map['keys'] as Map<String, dynamic>;

    for (final entry in keys.entries) {
      /// some mints have keysets with values like: 9223372036854775808, larger then int max \
      /// even accounting for fiat values these proofs are unrealistic \
      /// => skipped
      final amount = int.tryParse(entry.key);
      if (amount != null) {
        mintKeyPairs.add(CahsuMintKeyPair(
          amount: amount,
          pubkey: entry.value,
        ));
      }
    }

    return CahsuKeysResponse(
      id: map['id'] as String,
      mintUrl: mintUrl,
      unit: map['unit'] as String,
      mintKeyPairs: mintKeyPairs,
    );
  }
}
