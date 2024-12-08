enum BitcoinNetwork {
  mainnet('mainnet'),
  testnet('testnet'),
  signet('signet'),
  mutinynet('mutinynet'),
  regtest('regtest');

  final String plaintext;

  const BitcoinNetwork(this.plaintext);

  static BitcoinNetwork fromPlaintext(String plaintext) {
    return BitcoinNetwork.values.firstWhere(
      (network) => network.plaintext == plaintext,
      orElse: () => BitcoinNetwork.mainnet,
    );
  }
}
