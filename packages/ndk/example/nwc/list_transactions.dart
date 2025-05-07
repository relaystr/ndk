// ignore_for_file: avoid_print

import 'dart:io';

import 'package:ndk/ndk.dart';

void main() async {
  // We use an empty bootstrap relay list,
  // since NWC will provide the relay we connect to so we don't need default relays
  final ndk = Ndk.emptyBootstrapRelaysConfig();

  // You need an NWC_URI env var or to replace with your NWC uri connection
  final nwcUri = Platform.environment['NWC_URI']!;
  final connection = await ndk.nwc.connect(nwcUri);

  ListTransactionsResponse response =
      await ndk.nwc.listTransactions(connection, unpaid: true);

  for (final transaction in response.transactions) {
    print(
        "Transaction ${transaction.type} state ${transaction.state} ${transaction.amountSat} sats ${transaction.description!}");
  }
  await ndk.destroy();
}
