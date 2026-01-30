class CashuMintBalance {
  final String mintUrl;
  final Map<String, int> balances;

  CashuMintBalance({
    required this.mintUrl,
    required this.balances,
  });

  @override
  String toString() {
    return 'CashuMintBalance(mintUrl: $mintUrl, balances: $balances)';
  }
}
