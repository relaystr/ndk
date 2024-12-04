import 'dart:io';

import 'package:ndk/ndk.dart';

void main() async {
  Ndk ndk = Ndk.emptyBootstrapRelaysConfig();

  // use an NWC_URI env var or replace with your NWC uri connection
  NwcConnection connection = await ndk.nwc.connect(Platform.environment['NWC_URI']!);

  int amount = 1000;
  String description = "hello";
  MakeInvoiceResponse response = await ndk.nwc.makeInvoice(connection,
      amountSats: amount, description: description);

  print("invoice: ${response.invoice}");

  await ndk.destroy();
}
