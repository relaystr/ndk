import 'dart:io';

import 'package:ndk/domain_layer/usecases/nwc/consts/transaction_type.dart';
import 'package:ndk/ndk.dart';
import 'package:test/test.dart';

void main() async {
  // We use an empty bootstrap relay list,
  // since NWC will provide the relay we connect to so we don't need default relays
  final ndk = Ndk.emptyBootstrapRelaysConfig();

  // You need an NWC_URI env var or to replace with your NWC uri connection
  final nwcUri = Platform.environment['NWC_URI']!;
  final connection = await ndk.nwc.connect(nwcUri);

  ListTransactionsResponse response =
      await ndk.nwc.listTransactions(connection, unpaid: false);

  response.transactions.forEach((transaction) {
    print(
        "Transaction ${transaction.type} ${transaction.amountSat} sats ${transaction.description!}");
  });
  await ndk.destroy();
}
