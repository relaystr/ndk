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

      expect(
        responseNoQuote,
        emitsError(isA<Exception>()),
      );
      expect(
        responseNoMethod,
        emitsError(isA<Exception>()),
      );
    });
  });
}
