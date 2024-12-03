import 'dart:io';

import 'package:ndk/ndk.dart';
import 'package:ndk_nwc/nwc.dart';
import 'package:ndk_nwc/nwc_connection.dart';
import 'package:test/test.dart';

void main() async {
  Ndk ndk = Ndk.emptyBootstrapRelaysConfig();
  Nwc nwc = Nwc(ndk);

  // use an NWC_URI env var or replace with your NWC uri connection
  NwcConnection connection = await nwc.connect(Platform.environment['NWC_URI']!, doGetInfoMethod: true);

  print("alias: ${connection.info!.alias}");
  print("pubkey: ${connection.info!.pubkey}");

  await nwc.close();
  await ndk.close();
}
