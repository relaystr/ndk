// ignore_for_file: avoid_print

import 'dart:io';

import 'package:ndk/ndk.dart';

void main() async {
  // We use an empty bootstrap relay list,
  // since NWC will provide the relay we connect to so we don't need default relays
  final ndk = Ndk.emptyBootstrapRelaysConfig();

  // You need an NWC_URI env var or to replace with your NWC uri connection
  final nwcUri = Platform.environment['NWC_URI']!;
  final connection = await ndk.nwc.connect(nwcUri);

  print(
      "waiting for ${connection.isLegacyNotifications() ? "legacy " : ""}notifications");
  await for (final notification in connection.notificationStream.stream) {
    print('notification ${notification.type} amount: ${notification.amount}');
  }

  ndk.destroy();
}
