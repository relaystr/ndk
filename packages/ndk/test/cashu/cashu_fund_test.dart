import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:ndk/domain_layer/entities/cashu/cashu_quote.dart';
import 'package:ndk/domain_layer/usecases/cashu/cashu_keypair.dart';
import 'package:ndk/entities.dart';
import 'package:ndk/ndk.dart';
import 'package:test/test.dart';

import 'cashu_test_tools.dart';
import 'mocks/cashu_http_client_mock.dart';

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
    test("fund - initiateFund", () async {
      final ndk = Ndk.emptyBootstrapRelaysConfig();
      const fundAmount = 5;
      const fundUnit = "sat";

      final draftTransaction = await ndk.cashu.initiateFund(
        mintUrl: devMintUrl,
        amount: fundAmount,
        unit: fundUnit,
        method: "bolt11",
      );

      expect(draftTransaction, isA<CashuWalletTransaction>());
      expect(draftTransaction.changeAmount, equals(fundAmount));
      expect(draftTransaction.unit, equals(fundUnit));
      expect(draftTransaction.mintUrl, equals(devMintUrl));
      expect(draftTransaction.state, equals(WalletTransactionState.draft));
      expect(draftTransaction.qoute, isA<CashuQuote>());
      expect(draftTransaction.qoute!.amount, equals(fundAmount));
      expect(draftTransaction.qoute!.unit, equals(fundUnit));
      expect(draftTransaction.qoute!.mintUrl, equals(devMintUrl));
      expect(draftTransaction.qoute!.state, equals(CashuQuoteState.unpaid));
      expect(draftTransaction.qoute!.request, isNotEmpty);
      expect(draftTransaction.qoute!.quoteId, isNotEmpty);
      expect(draftTransaction.qoute!.quoteKey, isA<CashuKeypair>());
      expect(draftTransaction.qoute!.expiry, isA<int>());
      expect(draftTransaction.method, equals("bolt11"));
      expect(draftTransaction.usedKeysets!.length, greaterThan(0));
      expect(draftTransaction.transactionDate, isNull);
      expect(draftTransaction.initiatedDate, isNotNull);
      expect(draftTransaction.id, isNotEmpty);
    });

    test("fund - successfull", () async {
      final ndk = Ndk.emptyBootstrapRelaysConfig();
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

    test("fund - expired quote", () async {
      const fundAmount = 5;
      const fundUnit = "sat";
      const mockMintUrl = "http://mock.mint";

      final myHttpMock = MockCashuHttpClient();

      myHttpMock.setCustomResponse(
          "POST",
          "/v1/mint/quote/bolt11",
          http.Response(
            jsonEncode({
              "quote": "d00e6cbc-04c9-4661-8909-e47c19612bf0",
              "request":
                  "lnbc50p1p5tctmqdqqpp5y7jyyyq3ezyu3p4c9dh6qpnjj6znuzrz35ernjjpkmw6lz7y2mxqsp59g4z52329g4z52329g4z52329g4z52329g4z52329g4z52329g4q9qrsgqcqzysl62hzvm9s5nf53gk22v5nqwf9nuy2uh32wn9rfx6grkjh6vr5jmy09mra5cna504azyhkd2ehdel9sm7fm72ns6ws2fk4m8cwc99hdgptq8hv4",
              "amount": 5,
              "unit": "sat",
              "state": "UNPAID",
              "expiry": 1757106960
            }),
            200,
            headers: {'content-type': 'application/json'},
          ));

      myHttpMock.setCustomResponse(
          "GET",
          "/v1/mint/quote/bolt11/d00e6cbc-04c9-4661-8909-e47c19612bf0",
          http.Response(
            jsonEncode({
              "quote": "d00e6cbc-04c9-4661-8909-e47c19612bf0",
              "request":
                  "lnbc50p1p5tctmqdqqpp5y7jyyyq3ezyu3p4c9dh6qpnjj6znuzrz35ernjjpkmw6lz7y2mxqsp59g4z52329g4z52329g4z52329g4z52329g4z52329g4z52329g4q9qrsgqcqzysl62hzvm9s5nf53gk22v5nqwf9nuy2uh32wn9rfx6grkjh6vr5jmy09mra5cna504azyhkd2ehdel9sm7fm72ns6ws2fk4m8cwc99hdgptq8hv4",
              "amount": 5,
              "unit": "sat",
              "state": "UNPAID",
              "expiry": 1757106960
            }),
            200,
            headers: {'content-type': 'application/json'},
          ));

      final cashu = CashuTestTools.mockHttpCashu(customMockClient: myHttpMock);

      final draftTransaction = await cashu.initiateFund(
        mintUrl: mockMintUrl,
        amount: fundAmount,
        unit: fundUnit,
        method: "bolt11",
      );

      final transactionStream =
          cashu.retriveFunds(draftTransaction: draftTransaction);

      await expectLater(
        transactionStream,
        emitsInOrder([
          isA<CashuWalletTransaction>()
              .having((t) => t.state, 'state', WalletTransactionState.pending),
          isA<CashuWalletTransaction>()
              .having((t) => t.state, 'state', WalletTransactionState.failed),
        ]),
      );
      // check balance
      final allBalances = await cashu.getBalances();
      final balanceForMint =
          allBalances.where((element) => element.mintUrl == mockMintUrl);
      expect(balanceForMint.length, 1);
      final balance = balanceForMint.first.balances[fundUnit];

      expect(balance, equals(0));
    });

    test("fund - mint err no signature", () async {
      const fundAmount = 5;
      const fundUnit = "sat";
      const mockMintUrl = "http://mock.mint";

      final myHttpMock = MockCashuHttpClient();

      final cashu = CashuTestTools.mockHttpCashu(customMockClient: myHttpMock);

      final draftTransaction = await cashu.initiateFund(
        mintUrl: mockMintUrl,
        amount: fundAmount,
        unit: fundUnit,
        method: "bolt11",
      );

      final transactionStream =
          cashu.retriveFunds(draftTransaction: draftTransaction);

      await expectLater(
        transactionStream,
        emitsInOrder([
          isA<CashuWalletTransaction>()
              .having((t) => t.state, 'state', WalletTransactionState.pending),
          emitsError(isA<Exception>()),
        ]),
      );

      //check balance
      final allBalances = await cashu.getBalances();
      final balanceForMint =
          allBalances.where((element) => element.mintUrl == mockMintUrl);
      expect(balanceForMint.length, 1);
      final balance = balanceForMint.first.balances[fundUnit];

      expect(balance, equals(0));
    });
  });
}
