import 'dart:io';

import 'package:ndk/ndk.dart';
import 'package:logger/logger.dart' as lib_logger;

void main() async {
  // We use an empty bootstrap relay list,
  // since NWC will provide the relay we connect to so we don't need default relays
  final ndk = Ndk.emptyBootstrapRelaysConfig();

  Logger.setLogLevel(lib_logger.Level.warning);

  // You need an NWC_URI env var or to replace with your NWC uri connection
  final nwcUri = Platform.environment['NWC_URI']!;
  final connection = await ndk.nwc.connect(nwcUri);

  GetBalanceResponse balanceResponse = await ndk.nwc.getBalance(connection);

  print("Balance: ${balanceResponse.balanceSats} sats");

  await ndk.destroy();
}
