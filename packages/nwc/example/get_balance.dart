import 'dart:io';

import 'package:ndk/ndk.dart';
import 'package:ndk_nwc/nwc.dart';
import 'package:ndk_nwc/nwc_connection.dart';
import 'package:ndk_nwc/responses/get_balance_response.dart';
import 'package:test/test.dart';

void main() {
  test('get balance', () async {
    Ndk ndk = Ndk.defaultConfig();
    Nwc nwc = Nwc(ndk);

    NwcConnection connection = await nwc.connect(Platform.environment['NWC_URI']!);

    GetBalanceResponse balanceResponse = await nwc.getBalance(connection);

    expect(balanceResponse, isNotNull);
    expect(true, balanceResponse.balanceMsats > 0);
  });
}
