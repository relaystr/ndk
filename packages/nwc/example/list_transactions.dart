import 'dart:io';

import 'package:ndk/ndk.dart';
import 'package:ndk_nwc/consts/transaction_type.dart';
import 'package:ndk_nwc/nwc.dart';
import 'package:ndk_nwc/nwc_connection.dart';
import 'package:ndk_nwc/responses/list_transactions_response.dart';
import 'package:test/test.dart';

void main() {
  test('list transactions', () async {
    Ndk ndk = Ndk.defaultConfig();
    Nwc nwc = Nwc(ndk);

    String testUri = Platform.environment['NWC_URI']!;

    NwcConnection connection = await nwc.connect(testUri);

    ListTransactionsResponse response = await nwc.listTransactions(connection,
        unpaid: false, type: TransactionType.incoming);

    expect(response, isNotNull);
    expect(response.transactions, isNotEmpty);
  });
}
