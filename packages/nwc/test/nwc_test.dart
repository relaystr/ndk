import 'package:ndk_nwc/commands/get_balance_response.dart';
import 'package:ndk_nwc/commands/list_transactions_response.dart';
import 'package:ndk_nwc/commands/make_invoice_response.dart';
import 'package:ndk_nwc/consts/transaction_type.dart';
import 'package:test/test.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk_nwc/nwc.dart';
import 'package:ndk_nwc/nwc_connection.dart';

void main() {
  group('Nwc', () {
    late Nwc nwc;
    late NwcConnection connection;

    setUp(() async {
      nwc = Nwc(Ndk(NdkConfig(
          cache: MemCacheManager(), eventVerifier: Bip340EventVerifier())));
      String testUri = 'nostr+walletconnect://....CHANGE ME';

      connection = await nwc.connect(testUri);
      expect(connection, isNotNull);
    });

    test('connect should complete with a valid NwcConnection', () async {
      expect(connection.info, isNotNull);
      await expectLater(
          connection.responseStream.stream, emitsInAnyOrder([isNotNull]));
    });

    test('get balance', () async {
      GetBalanceResponse balanceResponse = await nwc.getBalance(connection);
      expect(balanceResponse, isNotNull);
      expect(true, balanceResponse.balanceMsats > 0);
    });

    test('make invoice', () async {
      int amount = 1000;
      MakeInvoiceResponse response = await nwc.makeInvoice(connection,
          amountSats: amount, description: "hello");
      expect(response, isNotNull);
      expect(response.amountSat, amount);
      expect(response.invoice, isNotEmpty);
      expect(response.invoice.startsWith("lnbc"), true);
    });

    test('list transactions', () async {

      ListTransactionsResponse response = await nwc.listTransactions(connection, unpaid: false, type: TransactionType.incoming);
      expect(response, isNotNull);
      expect(response.transactions, isNotEmpty);
    });
  });
}
