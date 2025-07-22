class WalletCashuProof {
  final String id;
  final int amount;

  final String secret;

  /// C unblinded signature
  final String unblindedSig;

  WalletCashuProof({
    required this.id,
    required this.amount,
    required this.secret,
    required this.unblindedSig,
  });

  Map<String, Object> toJson() {
    return {
      'id': id,
      'amount': amount,
      'secret': secret,
      'C': unblindedSig,
    };
  }

  Map<String, Object> toV4Json() {
    return {
      'a': amount,
      's': secret,
      'c': unblindedSig,
    };
  }

  factory WalletCashuProof.fromV4Json(String keysetId, Map json) {
    return WalletCashuProof(
      id: keysetId,
      amount: json['a'] ?? 0,
      secret: json['s']?.toString() ?? '',
      unblindedSig: json['c']?.toString() ?? '',
    );
  }
}
