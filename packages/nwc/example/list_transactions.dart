import 'dart:io';

import 'package:ndk/domain_layer/usecases/nwc/consts/transaction_type.dart';
import 'package:ndk/ndk.dart';
import 'package:test/test.dart';

void main() {
  test('list transactions', () async {
    Ndk ndk = Ndk.emptyBootstrapRelaysConfig();

    String testUri = Platform.environment['NWC_URI']!;

    NwcConnection connection = await ndk.nwc.connect(testUri);

    ListTransactionsResponse response = await ndk.nwc.listTransactions(connection,
        unpaid: false, type: TransactionType.incoming);

    expect(response, isNotNull);
    expect(response.transactions, isNotEmpty);
  });
}
