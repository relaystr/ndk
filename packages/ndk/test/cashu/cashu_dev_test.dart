import 'package:ndk/ndk.dart';
import 'package:test/test.dart';

void main() {
  setUp(() {});

  group('dev tests', () {
    test('getKeys', () async {
      final ndk = Ndk.emptyBootstrapRelaysConfig();

      final mintURL = 'http://127.0.0.1:8085';

      final keys = await ndk.cashuWallet.getKeysetMintFromNetwork(
        mintURL: mintURL,
      );
      expect(keys, isNotEmpty);
      print(keys);
    });
  });
}
