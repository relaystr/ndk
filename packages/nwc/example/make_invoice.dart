import 'dart:io';

import 'package:ndk/ndk.dart';
import 'package:ndk_nwc/nwc.dart';
import 'package:ndk_nwc/nwc_connection.dart';
import 'package:ndk_nwc/responses/make_invoice_response.dart';

void main() async {
  Ndk ndk = Ndk.emptyBootstrapRelaysConfig();
  Nwc nwc = Nwc(ndk);

  // use an NWC_URI env var or replace with your NWC uri connection
  NwcConnection connection = await nwc.connect(Platform.environment['NWC_URI']!);

  int amount = 1000;
  String description = "hello";
  MakeInvoiceResponse response = await nwc.makeInvoice(connection,
      amountSats: amount, description: description);

  print("invoice: ${response.invoice}");

  await nwc.close();
  await ndk.close();
}
