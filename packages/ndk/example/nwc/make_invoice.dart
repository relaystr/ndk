import 'dart:io';

import 'package:ndk/ndk.dart';

void main() async {
  // We use an empty bootstrap relay list,
  // since NWC will provide the relay we connect to so we don't need default relays
  final ndk = Ndk.emptyBootstrapRelaysConfig();

  // You need an NWC_URI env var or to replace with your NWC uri connection
  final nwcUri = Platform.environment['NWC_URI']!;
  final connection = await ndk.nwc.connect(nwcUri);

  final amount = 1000;
  final description = "hello";
  final response = await ndk.nwc
      .makeInvoice(connection, amountSats: amount, description: description);

  print("invoice: ${response.invoice}");

  await ndk.destroy();
}
