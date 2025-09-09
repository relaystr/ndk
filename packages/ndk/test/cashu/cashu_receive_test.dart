import 'package:http/http.dart' as http;
import 'package:ndk/data_layer/data_sources/http_request.dart';
import 'package:ndk/data_layer/repositories/cashu/cashu_repo_impl.dart';
import 'package:ndk/entities.dart';
import 'package:ndk/ndk.dart';
import 'package:test/test.dart';

import 'cashu_test_tools.dart';

const devMintUrl = 'https://dev.mint.camelus.app';
const failingMintUrl = 'https://mint.example.com';
const mockMintUrl = "https://mock.mint";

void main() {
  setUp(() {});

  group('receive tests - exceptions ', () {
    test("invalid token", () {
      final ndk = Ndk.emptyBootstrapRelaysConfig();

      final rcvStream = ndk.cashu.receive("cashuBinvalidtoken");
      expect(
        () async => await rcvStream.last,
        throwsA(isA<Exception>()),
      );
    });

    test("empty token", () async {
      final ndk = Ndk.emptyBootstrapRelaysConfig();

      final rcvStream = ndk.cashu.receive(
          "cashuBo2FteBxodHRwczovL2Rldi5taW50LmNhbWVsdXMuYXBwYXVjc2F0YXSBomFpQGFwgaRhYQBhc2BhY0BhZKNhZUBhc0BhckA");

      expect(
        () async => await rcvStream.last,
        throwsA(isA<Exception>()),
      );
    });

    test("invalid mint", () async {
      final ndk = Ndk.emptyBootstrapRelaysConfig();

      final rcvStream = ndk.cashu.receive(
          "cashuBo2FtdGh0dHBzOi8vbWludC5pbnZhbGlkYXVjc2F0YXSBomFpSABV3vjPJfyNYXCBpGFhAWFzeEBmYmMxYWY4ZTk1YWQyZTVjMGQzY2U3MTMxNjI3MDBkOGNmN2NhNDQ2Njc1ZTE5NTc0NWE5ZWYzMDI1Zjc0NjdhYWNYIQJYTRSL3snLOVtf2OECtcqM_y7kG1VCQnVeWc9BPzP4zGFko2FlWCAlHMDORr2HAR0NNMsV4tB3s09bCB_s35QvHIEVkqed3mFzWCBLAh8gJ0J0uv7WzGkFC9gn4jZc7sFTpZvEgnitZ6ijrGFyWCC9QCslHjMWBU_2TWwnUNXj-rM7-iP6_8RqxiJMsa1Dcg");

      expect(
        () async => await rcvStream.last,
        throwsA(isA<Exception>()),
      );
    });
  });

  group('receive', () {
    test("receive integration, double spend", () async {
      final cache = MemCacheManager();
      final cache2 = MemCacheManager();

      final client = HttpRequestDS(http.Client());
      final cashuRepo = CashuRepoImpl(client: client);
      final cashuRepo2 = CashuRepoImpl(client: client);
      final cashu = Cashu(cashuRepo: cashuRepo, cacheManager: cache);

      final cashu2 = Cashu(cashuRepo: cashuRepo2, cacheManager: cache2);

      const fundAmount = 32;
      const fundUnit = "sat";

      final draftTransaction = await cashu.initiateFund(
        mintUrl: devMintUrl,
        amount: fundAmount,
        unit: fundUnit,
        method: "bolt11",
      );
      final transactionStream =
          cashu.retriveFunds(draftTransaction: draftTransaction);

      final transaction = await transactionStream.last;
      expect(transaction.state, WalletTransactionState.completed);

      final spending = await cashu.initiateSpend(
        mintUrl: devMintUrl,
        amount: 16,
        unit: fundUnit,
      );
      final token = spending.token.toV4TokenString();

      final rcvStream = cashu2.receive(token);

      await expectLater(
          rcvStream,
          emitsInOrder(
            [
              isA<CashuWalletTransaction>().having(
                  (t) => t.state, 'state', WalletTransactionState.pending),
              isA<CashuWalletTransaction>()
                  .having(
                      (t) => t.state, 'state', WalletTransactionState.completed)
                  .having(
                      (t) => t.transactionDate!, 'transactionDate', isA<int>()),
            ],
          ));

      final balance =
          await cashu2.getBalanceMintUnit(unit: fundUnit, mintUrl: devMintUrl);

      expect(balance, equals(16));

      // try to double spend the same token
      final rcvStream2 = cashu2.receive(token);

      expect(
        () async => await rcvStream2.last,
        throwsA(isA<Exception>()),
      );
    });
  });
}
