import 'dart:io';

import 'package:ndk/ndk.dart';
import 'package:ndk_nwc/nwc.dart';
import 'package:ndk_nwc/nwc_connection.dart';
import 'package:ndk_nwc/responses/make_invoice_response.dart';
import 'package:ndk_nwc/responses/pay_invoice_response.dart';

void main() async {
  Ndk ndk = Ndk.emptyBootstrapRelaysConfig();
  Nwc nwc = Nwc(ndk);

  // use an NWC_URI env var or replace with your NWC uri connection
  NwcConnection connection = await nwc.connect(Platform.environment['NWC_URI']!);

  // use an INVOICE env var or replace with your bolt11 invoice
  String invoice = Platform.environment['INVOICE']!;

  PayInvoiceResponse payInvoice = await nwc.payInvoice(connection, invoice: invoice);

  print("preimage: ${payInvoice.preimage}");

  await nwc.close();
  await ndk.close();
}