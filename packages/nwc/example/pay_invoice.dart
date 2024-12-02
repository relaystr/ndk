import 'dart:io';

import 'package:ndk/ndk.dart';
import 'package:ndk_nwc/commands/make_invoice_response.dart';
import 'package:ndk_nwc/commands/pay_invoice_response.dart';
import 'package:ndk_nwc/nwc.dart';
import 'package:ndk_nwc/nwc_connection.dart';
import 'package:test/test.dart';

void main() {
  test('pay invoice', () async {
    Ndk ndk = Ndk.defaultConfig();
    Nwc nwc = Nwc(ndk);

    NwcConnection connection =
        await nwc.connect(Platform.environment['NWC_URI']!);

    MakeInvoiceResponse makeInvoice =
        await nwc.makeInvoice(connection, amountSats: 100);

    expect(makeInvoice.invoice, isNotEmpty);

    PayInvoiceResponse payInvoice =
        await nwc.payInvoice(connection, invoice: makeInvoice.invoice);

    expect(payInvoice.preimage, isNotEmpty);
  });
}
