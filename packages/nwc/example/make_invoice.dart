import 'dart:io';

import 'package:ndk/ndk.dart';
import 'package:ndk_nwc/commands/make_invoice_response.dart';
import 'package:ndk_nwc/nwc.dart';
import 'package:ndk_nwc/nwc_connection.dart';
import 'package:test/test.dart';

void main() {
  test('make invoice', () async {
    Ndk ndk = Ndk.defaultConfig();
    Nwc nwc = Nwc(ndk);

    String testUri = Platform.environment['NWC_URI']!;

    NwcConnection connection = await nwc.connect(testUri);

    int amount = 1000;
    String description = "hello";
    MakeInvoiceResponse response = await nwc.makeInvoice(connection,
        amountSats: amount, description: description);

    expect(response, isNotNull);
    expect(response.amountSat, amount);
    expect(response.invoice, isNotEmpty);
    expect(response.invoice.startsWith("lnbc"), true);
    expect(response.description, description);
  });
}
