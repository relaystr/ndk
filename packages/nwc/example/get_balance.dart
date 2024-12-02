import 'dart:io';
import 'package:ndk_nwc/commands/get_balance_response.dart';
import 'package:ndk_nwc/commands/list_transactions_response.dart';
import 'package:ndk_nwc/commands/make_invoice_response.dart';
import 'package:ndk_nwc/consts/transaction_type.dart';
import 'package:test/test.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk_nwc/nwc.dart';
import 'package:ndk_nwc/nwc_connection.dart';

void main() {
  test('get balance', () async {
    Ndk ndk = Ndk.defaultConfig();
    Nwc nwc = Nwc(ndk);

    String testUri = Platform.environment['NWC_URI']!;

    NwcConnection connection = await nwc.connect(testUri);

    GetBalanceResponse balanceResponse = await nwc.getBalance(connection);
    expect(balanceResponse, isNotNull);
    expect(true, balanceResponse.balanceMsats > 0);
  });
}
