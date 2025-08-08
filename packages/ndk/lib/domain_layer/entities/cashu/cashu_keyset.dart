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
    return CahsuKeysResponse(
      id: map['id'] as String,
      mintUrl: mintUrl,
      unit: map['unit'] as String,
      mintKeyPairs: (map['keys'] as Map<String, dynamic>)
          .entries
          .map((e) => CahsuMintKeyPair(
                amount: int.parse(e.key),
                pubkey: e.value,
              ))
          .toSet(),
    );
  }
}
