import 'dart:io';

import 'package:ndk/ndk.dart';

void main() async {
  Ndk ndk = Ndk.emptyBootstrapRelaysConfig();

  // use an NWC_URI env var or replace with your NWC uri connection
  NwcConnection connection = await ndk.nwc.connect(Platform.environment['NWC_URI']!);

  GetBalanceResponse balanceResponse = await ndk.nwc.getBalance(connection);

  print("Balance: ${balanceResponse.balanceSats} sats");

  await ndk.destroy();
}
