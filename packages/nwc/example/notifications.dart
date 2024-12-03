import 'dart:io';

import 'package:ndk/ndk.dart';
import 'package:ndk_nwc/nwc.dart';
import 'package:ndk_nwc/nwc_connection.dart';

void main() async {
  Ndk ndk = Ndk.emptyBootstrapRelaysConfig();
  Nwc nwc = Nwc(ndk);

  // use an NWC_URI env var or replace with your NWC uri connection
  NwcConnection connection = await nwc.connect(Platform.environment['NWC_URI']!);

  connection.notificationStream.stream.listen((notification) {
    print('notification ${notification.type} amount: ${notification.amount}');
  });

  await nwc.close();
  await ndk.close();
}
