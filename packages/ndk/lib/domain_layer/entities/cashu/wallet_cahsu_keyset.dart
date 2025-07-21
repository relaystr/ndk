class WalletCahsuKeyset {
  final String id;
  final String mintURL;
  final String unit;
  final bool active;
  final int inputFeePPK;
  final Set<WalletCahsuMintKeyPair> mintKeyPairs;

  WalletCahsuKeyset({
    required this.id,
    required this.mintURL,
    required this.unit,
    required this.active,
    required this.inputFeePPK,
    required this.mintKeyPairs,
  });

  factory WalletCahsuKeyset.fromResponses({
    required WalletCahsuKeysetResponse keysetResponse,
    required WalletCahsuKeystResponse keysResponse,
  }) {
    if (keysetResponse.id != keysResponse.id ||
        keysetResponse.mintURL != keysResponse.mintURL ||
        keysetResponse.unit != keysResponse.unit) {
      throw ArgumentError('Keyset and keys responses do not match');
    }

    return WalletCahsuKeyset(
      id: keysetResponse.id,
      mintURL: keysetResponse.mintURL,
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
  final String mintURL;
  final String unit;
  final bool active;
  final int inputFeePPK;

  WalletCahsuKeysetResponse({
    required this.id,
    required this.mintURL,
    required this.unit,
    required this.active,
    required this.inputFeePPK,
  });

  factory WalletCahsuKeysetResponse.fromServerMap({
    required Map<String, dynamic> map,
    required String mintURL,
  }) {
    return WalletCahsuKeysetResponse(
      id: map['id'] as String,
      mintURL: mintURL,
      unit: map['unit'] as String,
      active: map['active'] as bool,
      inputFeePPK: map['input_fee_ppk'] as int,
    );
  }
}

class WalletCahsuKeystResponse {
  final String id;
  final String mintURL;
  final String unit;
  final Set<WalletCahsuMintKeyPair> mintKeyPairs;

  WalletCahsuKeystResponse({
    required this.id,
    required this.mintURL,
    required this.unit,
    required this.mintKeyPairs,
  });

  factory WalletCahsuKeystResponse.fromServerMap({
    required Map<String, dynamic> map,
    required String mintURL,
  }) {
    return WalletCahsuKeystResponse(
      id: map['id'] as String,
      mintURL: mintURL,
      unit: map['unit'] as String,
      mintKeyPairs: (map['keys'] as Map<String, String>)
          .entries
          .map((e) => WalletCahsuMintKeyPair(
                amount: int.parse(e.key),
                pubkey: e.value,
              ))
          .toSet(),
    );
  }
}
