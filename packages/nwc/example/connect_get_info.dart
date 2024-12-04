import 'dart:io';

import 'package:ndk/ndk.dart';

void main() async {
  Ndk ndk = Ndk.emptyBootstrapRelaysConfig();

  // use an NWC_URI env var or replace with your NWC uri connection
  NwcConnection connection = await ndk.nwc.connect(Platform.environment['NWC_URI']!, doGetInfoMethod: true);

  print("alias: ${connection.info!.alias}");
  print("pubkey: ${connection.info!.pubkey}");

  await ndk.destroy();
}
