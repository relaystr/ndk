import 'package:ndk/data_layer/data_sources/http_request.dart';
import 'package:ndk/domain_layer/entities/cashu/cashu_quote.dart';
import 'package:ndk/domain_layer/entities/cashu/cashu_quote_melt.dart';
import 'package:ndk/entities.dart';
import 'package:ndk/ndk.dart';
import 'package:test/test.dart';

import 'cashu_test_tools.dart';
import 'mocks/cashu_http_client_mock.dart';
import 'mocks/cashu_repo_mock.dart';

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
          seedPhrase: CashuUserSeedphrase(
              seedPhrase:
                  "reduce invest lunch step couch traffic measure civil want steel trip jar"),
          customMockClient: myHttpMock,
          customCache: cache);

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

    test("redeem fails after proofs spent on mint - proofs marked as spent",
        () async {
      // This test verifies the fix for the broken proofs issue:
      // When meltTokens() fails AFTER the mint has already spent the proofs,
      // the proofs should be marked as spent locally (not released back to the wallet).
      // Without this fix, proofs would be marked as unspent and become "broken" -
      // appearing available in the wallet but actually already burned on the mint.

      final cache = MemCacheManager();
      final myHttpMock = MockCashuHttpClient();

      // Use the mock repo that simulates melt failure after proofs are spent
      final mockRepo = CashuRepoMeltFailAfterSpendMock(
        client: HttpRequestDS(myHttpMock),
      );

      final cashu = CashuTestTools.mockHttpCashu(
        seedPhrase: CashuUserSeedphrase(
          seedPhrase:
              "reduce invest lunch step couch traffic measure civil want steel trip jar",
        ),
        customMockClient: myHttpMock,
        customCache: cache,
        customRepo: mockRepo,
      );

      // Add test proofs to cache
      final testProofs = [
        CashuProof(
          keysetId: '00c726786980c4d9',
          amount: 1,
          secret: 'proof-s-1',
          unblindedSig: 'sig1',
        ),
        CashuProof(
          keysetId: '00c726786980c4d9',
          amount: 2,
          secret: 'proof-s-2',
          unblindedSig: 'sig2',
        ),
        CashuProof(
          keysetId: '00c726786980c4d9',
          amount: 4,
          secret: 'proof-s-4',
          unblindedSig: 'sig4',
        ),
      ];

      await cache.saveProofs(proofs: testProofs, mintUrl: mockMintUrl);

      // Verify proofs are initially in unspent state
      final initialProofs = await cache.getProofs(mintUrl: mockMintUrl);
      expect(
        initialProofs.every((p) => p.state == CashuProofState.unspend),
        isTrue,
        reason: "All proofs should initially be unspent",
      );

      final meltQuoteTransaction = await cashu.initiateRedeem(
        mintUrl: mockMintUrl,
        request: "lnbc1...",
        unit: "sat",
        method: "bolt11",
      );

      final redeemStream =
          cashu.redeem(draftRedeemTransaction: meltQuoteTransaction);

      // Collect all events from the stream
      final events = await redeemStream.toList();

      // Should emit pending then failed
      expect(events.length, equals(2));
      expect(events[0].state, equals(WalletTransactionState.pending));
      expect(events[1].state, equals(WalletTransactionState.failed));
      expect(
        events[1].completionMsg,
        contains("Proofs were spent but melt failed"),
      );

      // CRITICAL ASSERTION: Verify selected proofs are marked as spent (not unspent/broken)
      // This is the key behavior that prevents broken proofs
      final spentProofs = await cache.getProofs(
        mintUrl: mockMintUrl,
        state: CashuProofState.spend,
      );

      // The melt quote has amount=1 + fee_reserve=2 = 3 sats total
      // With proofs [1, 2, 4], selection should pick 1+2=3, so 2 proofs
      expect(
        spentProofs.length,
        equals(2),
        reason:
            "Selected proofs should be marked as spent since they were burned on the mint",
      );
      expect(
        spentProofs.every((p) => p.state == CashuProofState.spend),
        isTrue,
        reason: "All selected proofs should be in spent state",
      );

      // Verify unselected proofs remain unspent
      final unspentProofs = await cache.getProofs(
        mintUrl: mockMintUrl,
        state: CashuProofState.unspend,
      );
      expect(
        unspentProofs.length,
        equals(1),
        reason: "Unselected proofs should remain unspent",
      );
    });
  });
}
