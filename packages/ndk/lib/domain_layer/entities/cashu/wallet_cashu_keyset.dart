class WalletCahsuKeyset {
  final String id;
  final String mintUrl;
  final String unit;
  final bool active;
  final int inputFeePPK;
  final Set<WalletCahsuMintKeyPair> mintKeyPairs;
  int? fetchedAt;

  WalletCahsuKeyset({
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

  factory WalletCahsuKeyset.fromResponses({
    required WalletCahsuKeysetResponse keysetResponse,
    required WalletCahsuKeysResponse keysResponse,
  }) {
    if (keysetResponse.id != keysResponse.id ||
        keysetResponse.mintUrl != keysResponse.mintUrl ||
        keysetResponse.unit != keysResponse.unit) {
      throw ArgumentError('Keyset and keys responses do not match');
    }

    return WalletCahsuKeyset(
      id: keysetResponse.id,
      mintUrl: keysetResponse.mintUrl,
      unit: keysetResponse.unit,
      active: keysetResponse.active,
      inputFeePPK: keysetResponse.inputFeePPK,
      mintKeyPairs: keysResponse.mintKeyPairs,
    );
  }
}

class WalletCahsuMintKeyPair {
  final int amount;
  final String pubkey;

  WalletCahsuMintKeyPair({
    required this.amount,
    required this.pubkey,
  });
}

class WalletCahsuKeysetResponse {
  final String id;
  final String mintUrl;
  final String unit;
  final bool active;
  final int inputFeePPK;

  WalletCahsuKeysetResponse({
    required this.id,
    required this.mintUrl,
    required this.unit,
    required this.active,
    required this.inputFeePPK,
  });

  factory WalletCahsuKeysetResponse.fromServerMap({
    required Map<String, dynamic> map,
    required String mintUrl,
  }) {
    return WalletCahsuKeysetResponse(
      id: map['id'] as String,
      mintUrl: mintUrl,
      unit: map['unit'] as String,
      active: map['active'] as bool,
      inputFeePPK: map['input_fee_ppk'] as int,
    );
  }
}

class WalletCahsuKeysResponse {
  final String id;
  final String mintUrl;
  final String unit;
  final Set<WalletCahsuMintKeyPair> mintKeyPairs;

  WalletCahsuKeysResponse({
    required this.id,
    required this.mintUrl,
    required this.unit,
    required this.mintKeyPairs,
  });

  factory WalletCahsuKeysResponse.fromServerMap({
    required Map<String, dynamic> map,
    required String mintUrl,
  }) {
    return WalletCahsuKeysResponse(
      id: map['id'] as String,
      mintUrl: mintUrl,
      unit: map['unit'] as String,
      mintKeyPairs: (map['keys'] as Map<String, dynamic>)
          .entries
          .map((e) => WalletCahsuMintKeyPair(
                amount: int.parse(e.key),
                pubkey: e.value,
              ))
          .toSet(),
    );
  }
}
