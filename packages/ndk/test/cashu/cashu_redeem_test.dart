import 'package:ndk/domain_layer/entities/cashu/cashu_quote.dart';
import 'package:ndk/domain_layer/entities/cashu/cashu_quote_melt.dart';
import 'package:ndk/entities.dart';
import 'package:ndk/ndk.dart';
import 'package:test/test.dart';

import 'cashu_test_tools.dart';
import 'mocks/cashu_http_client_mock.dart';

const devMintUrl = 'https://dev.mint.camelus.app';
const failingMintUrl = 'https://mint.example.com';
const mockMintUrl = "https://mock.mint";

void main() {
  setUp(() {});

  group('redeem tests - exceptions ', () {
    test("invalid mint url", () async {
      final ndk = Ndk.emptyBootstrapRelaysConfig();

      expect(
        () async => await ndk.cashu.initiateRedeem(
          mintUrl: failingMintUrl,
          request: "request",
          unit: "sat",
          method: "bolt11",
        ),
        throwsA(isA<Exception>()),
      );
    });

    test("malformed melt quote", () async {
      final ndk = Ndk.emptyBootstrapRelaysConfig();

      final draftTransaction = CashuWalletTransaction(
        id: "testId",
        walletId: devMintUrl,
        changeAmount: -1,
        unit: "sat",
        walletType: WalletType.CASHU,
        state: WalletTransactionState.draft,
        mintUrl: devMintUrl,
      );

      final redeemStream =
          ndk.cashu.redeem(draftRedeemTransaction: draftTransaction);

      await expectLater(
        () async => await redeemStream.last,
        throwsA(isA<Exception>()),
      );

      final dTwithQuote = draftTransaction.copyWith(
        qouteMelt: CashuQuoteMelt(
          quoteId: '',
          amount: 1,
          feeReserve: null,
          paid: false,
          expiry: null,
          mintUrl: '',
          state: CashuQuoteState.unpaid,
          unit: '',
          request: '',
        ),
      );
      final redeemStream2 =
          ndk.cashu.redeem(draftRedeemTransaction: dTwithQuote);

      await expectLater(
        () async => await redeemStream2.last,
        throwsA(isA<Exception>()),
      );

      // missing request
      final dTwithQuoteAndMethod = dTwithQuote.copyWith(method: "bolt11");
      final redeemStream3 =
          ndk.cashu.redeem(draftRedeemTransaction: dTwithQuoteAndMethod);

      await expectLater(
        () async => await redeemStream3.last,
        throwsA(isA<Exception>()),
      );

      final complete = dTwithQuoteAndMethod.copyWith(
        mintUrl: mockMintUrl,
        method: "bolt11",
        qouteMelt: CashuQuoteMelt(
          quoteId: '',
          amount: 1,
          feeReserve: null,
          paid: false,
          expiry: null,
          mintUrl: devMintUrl,
          state: CashuQuoteState.unpaid,
          unit: 'sat',
          request: 'lnbc1...',
        ),
      );
      final redeemStream4 = ndk.cashu.redeem(draftRedeemTransaction: complete);

      // no host found (mock.mint)
      await expectLater(
        () async => await redeemStream4.last,
        throwsA(isA<Exception>()),
      );
    });
  });

  group('redeem', () {
    test("redeem mock", () async {
      final cache = MemCacheManager();

      final myHttpMock = MockCashuHttpClient();

      final mockRequest = "lnbc1...";

      final cashu = CashuTestTools.mockHttpCashu(
          customMockClient: myHttpMock, customCache: cache);

      await cache.saveProofs(proofs: [
        CashuProof(
          keysetId: '00c726786980c4d9',
          amount: 1,
          secret: 'proof-s-1',
          unblindedSig: '',
        ),
        CashuProof(
          keysetId: '00c726786980c4d9',
          amount: 2,
          secret: 'proof-s-2',
          unblindedSig: '',
        ),
        CashuProof(
          keysetId: '00c726786980c4d9',
          amount: 4,
          secret: 'proof-s-4',
          unblindedSig: '',
        ),
      ], mintUrl: mockMintUrl);

      final meltQuoteTransaction = await cashu.initiateRedeem(
        mintUrl: mockMintUrl,
        request: mockRequest,
        unit: "sat",
        method: "bolt11",
      );

      final redeemStream =
          cashu.redeem(draftRedeemTransaction: meltQuoteTransaction);

      expectLater(
          redeemStream,
          emitsInOrder(
            [
              isA<CashuWalletTransaction>().having(
                  (p0) => p0.state, 'state', WalletTransactionState.pending),
              isA<CashuWalletTransaction>().having(
                  (p0) => p0.state, 'state', WalletTransactionState.completed),
            ],
          ));
    });
  });
}
