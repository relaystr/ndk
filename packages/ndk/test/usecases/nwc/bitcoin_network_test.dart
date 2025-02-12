import 'package:ndk/domain_layer/usecases/nwc/consts/bitcoin_network.dart';
import 'package:test/test.dart';

void main() {
  group('BitcoinNetwork', () {
    test('fromPlaintext returns correct network for valid plaintext', () {
      expect(BitcoinNetwork.fromPlaintext('mainnet'), BitcoinNetwork.mainnet);
      expect(BitcoinNetwork.fromPlaintext('testnet'), BitcoinNetwork.testnet);
      expect(BitcoinNetwork.fromPlaintext('signet'), BitcoinNetwork.signet);
      expect(BitcoinNetwork.fromPlaintext('mutinynet'), BitcoinNetwork.mutinynet);
      expect(BitcoinNetwork.fromPlaintext('regtest'), BitcoinNetwork.regtest);
    });

    test('fromPlaintext returns mainnet for invalid plaintext', () {
      expect(BitcoinNetwork.fromPlaintext('invalid'), BitcoinNetwork.mainnet);
    });
  });
}