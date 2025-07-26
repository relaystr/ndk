import 'package:ndk/domain_layer/usecases/cashu_wallet/cashu_wallet_proof_select.dart';
import 'package:ndk/ndk.dart';
import 'package:test/test.dart';

void main() {
  setUp(() {});

  group('dev tests', () {
    test('fund', () async {
      final ndk = Ndk.emptyBootstrapRelaysConfig();

      final mintURL = 'http://127.0.0.1:8085';

      final fundResponse = await ndk.cashuWallet.fund(
        mintURL: mintURL,
        amount: 52,
        unit: 'sat',
        method: 'bolt11',
      );

      print(fundResponse);
    });

    test('receive', () async {
      final ndk = Ndk.emptyBootstrapRelaysConfig();

      final mintURL = 'http://127.0.0.1:8085';

      final fundResponse = await ndk.cashuWallet.fund(
        mintURL: mintURL,
        amount: 52,
        unit: 'sat',
        method: 'bolt11',
      );

      final eCashToken = ndk.cashuWallet.proofsToToken(
        proofs: fundResponse,
        mintUrl: mintURL,
        unit: 'sat',
      );

      print(eCashToken);

      final receiveResponse = await ndk.cashuWallet.receive(eCashToken);

      print(receiveResponse);
    });

    test('spend test', () async {
      final ndk = Ndk.emptyBootstrapRelaysConfig();

      final mintURL = 'http://127.0.0.1:8085';

      final fundResponse = await ndk.cashuWallet.fund(
        mintURL: mintURL,
        amount: 52,
        unit: 'sat',
        method: 'bolt11',
      );

      final spendResult = await ndk.cashuWallet.spend(
        mint: mintURL,
        amount: 16,
        unit: 'sat',
      );
      print(spendResult);
    });
  });
}
