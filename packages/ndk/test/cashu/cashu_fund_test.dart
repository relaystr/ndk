import 'package:ndk/domain_layer/entities/cashu/cashu_quote.dart';
import 'package:ndk/domain_layer/entities/wallet/wallet_transaction.dart';
import 'package:ndk/domain_layer/usecases/cashu/cashu_keypair.dart';
import 'package:ndk/entities.dart';
import 'package:ndk/ndk.dart';
import 'package:test/test.dart';

const devMintUrl = 'https://dev.mint.camelus.app';
const failingMintUrl = 'https://mint.example.com';

void main() {
  setUp(() {});

  group('fund tests - exceptions ', () {
    test('fund - invalid mint throws exception', () async {
      final ndk = Ndk.emptyBootstrapRelaysConfig();

      expect(
        () async => await ndk.cashu.initiateFund(
          mintUrl: failingMintUrl,
          amount: 52,
          unit: 'sat',
          method: 'bolt11',
        ),
        throwsA(isA<Exception>()),
      );
    });
    test('fund - no keyset throws exception', () async {
      final ndk = Ndk.emptyBootstrapRelaysConfig();

      expect(
        () async => await ndk.cashu.initiateFund(
          mintUrl: devMintUrl,
          amount: 52,
          unit: 'nokeyset',
          method: 'bolt11',
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('fund - retriveFunds no quote throws exception', () async {
      final ndk = Ndk.emptyBootstrapRelaysConfig();

      final Stream<CashuWalletTransaction> response = ndk.cashu.retriveFunds(
        draftTransaction: CashuWalletTransaction(
            id: 'test0',
            walletId: '',
            changeAmount: 5,
            unit: 'sat',
            walletType: WalletType.CASHU,
            state: WalletTransactionState.draft,
            mintUrl: devMintUrl,
            qoute: null),
      );

      expect(
        response,
        emitsError(isA<Exception>()),
      );
    });

    test('fund - retriveFunds exceptions', () async {
      final ndk = Ndk.emptyBootstrapRelaysConfig();

      final baseDraftTransaction = CashuWalletTransaction(
        id: 'test0',
        walletId: '',
        changeAmount: 5,
        unit: 'sat',
        walletType: WalletType.CASHU,
        state: WalletTransactionState.draft,
        mintUrl: devMintUrl,
        qoute: null,
      );

      final Stream<CashuWalletTransaction> responseNoQuote =
          ndk.cashu.retriveFunds(
        draftTransaction: baseDraftTransaction,
      );

      final Stream<CashuWalletTransaction> responseNoMethod =
          ndk.cashu.retriveFunds(
        draftTransaction: baseDraftTransaction.copyWith(
          qoute: CashuQuote(
            quoteId: "quoteId",
            request: "request",
            amount: 5,
            unit: 'sat',
            state: CashuQuoteState.paid,
            expiry: 0,
            mintUrl: devMintUrl,
            quoteKey: CashuKeypair.generateCashuKeyPair(),
          ),
        ),
      );

      final Stream<CashuWalletTransaction> responseNoKeysets =
          ndk.cashu.retriveFunds(
        draftTransaction: baseDraftTransaction.copyWith(
          method: "sat",
          qoute: CashuQuote(
            quoteId: "quoteId",
            request: "request",
            amount: 5,
            unit: 'sat',
            state: CashuQuoteState.paid,
            expiry: 0,
            mintUrl: devMintUrl,
            quoteKey: CashuKeypair.generateCashuKeyPair(),
          ),
        ),
      );

      expect(
        responseNoQuote,
        emitsError(isA<Exception>()),
      );
      expect(
        responseNoMethod,
        emitsError(isA<Exception>()),
      );
      expect(
        responseNoKeysets,
        emitsError(isA<Exception>()),
      );
    });
  });

  group('fund', () {
    final ndk = Ndk.emptyBootstrapRelaysConfig();
    test("fund - successfull", () async {
      const fundAmount = 100;
      const fundUnit = "sat";

      final draftTransaction = await ndk.cashu.initiateFund(
        mintUrl: devMintUrl,
        amount: fundAmount,
        unit: fundUnit,
        method: "bolt11",
      );
      final transactionStream =
          ndk.cashu.retriveFunds(draftTransaction: draftTransaction);

      await expectLater(
        transactionStream,
        emitsInOrder([
          isA<CashuWalletTransaction>()
              .having((t) => t.state, 'state', WalletTransactionState.pending),
          isA<CashuWalletTransaction>()
              .having((t) => t.state, 'state', WalletTransactionState.completed)
              .having((t) => t.transactionDate!, 'transactionDate', isA<int>()),
        ]),
      );
      // check balance
      final allBalances = await ndk.cashu.getBalances();
      final balanceForMint =
          allBalances.where((element) => element.mintUrl == devMintUrl);
      expect(balanceForMint.length, 1);
      final balance = balanceForMint.first.balances[fundUnit];

      expect(balance, equals(fundAmount));
    });
  });
}
