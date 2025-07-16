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
}
