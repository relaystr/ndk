import 'package:http/http.dart' as http;
import 'package:ndk/data_layer/data_sources/http_request.dart';
import 'package:ndk/data_layer/repositories/cashu/cashu_repo_impl.dart';
import 'package:ndk/ndk.dart';
import 'package:test/test.dart';

void main() {
  setUp(() {});

  group('dev tests', () {
    test('fund', () async {
      final ndk = Ndk.emptyBootstrapRelaysConfig();

      final mintUrl = 'http://127.0.0.1:8085';

      final fundResponse = await ndk.cashu.fund(
        mintUrl: mintUrl,
        amount: 52,
        unit: 'sat',
        method: 'bolt11',
      );

      print(fundResponse);
    });

    test('receive', () async {
      final ndk = Ndk.emptyBootstrapRelaysConfig();

      final mintUrl = 'http://127.0.0.1:8085';

      final fundResponse = await ndk.cashu.fund(
        mintUrl: mintUrl,
        amount: 52,
        unit: 'sat',
        method: 'bolt11',
      );

      final eCashToken = ndk.cashu.proofsToToken(
        proofs: fundResponse,
        mintUrl: mintUrl,
        unit: 'sat',
      );

      print(eCashToken);

      final receiveResponse = await ndk.cashu.receive(eCashToken);

      print(receiveResponse);
    });

    test('spend test', () async {
      final ndk = Ndk.emptyBootstrapRelaysConfig();

      final mintUrl = 'http://127.0.0.1:8085';

      final fundResponse = await ndk.cashu.fund(
        mintUrl: mintUrl,
        amount: 52,
        unit: 'sat',
        method: 'bolt11',
      );

      final spendResult = await ndk.cashu.spend(
        mintUrl: mintUrl,
        amount: 16,
        unit: 'sat',
      );
      print(spendResult);
    });

    test('parse mint info', () async {
      final mintUrl = 'http://127.0.0.1:8085';

      final HttpRequestDS httpRequestDS = HttpRequestDS(http.Client());

      final repo = CashuRepoImpl(client: httpRequestDS);

      final mintInfo = await repo.getMintInfo(mintUrl: mintUrl);

      print(mintInfo);
    });
  }, skip: true);
}
