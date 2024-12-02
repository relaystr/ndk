import 'dart:io';

import 'package:ndk/ndk.dart';
import 'package:ndk_nwc/nwc.dart';
import 'package:ndk_nwc/nwc_connection.dart';
import 'package:test/test.dart';

void main() {
  test('connect and get info', () async {
    Ndk ndk = Ndk.defaultConfig();
    Nwc nwc = Nwc(ndk);

    String testUri = Platform.environment['NWC_URI']!;

    NwcConnection connection = await nwc.connect(testUri);

    expect(connection, isNotNull);
    expect(connection.info, isNotNull);
    await expectLater(
        connection.responseStream.stream, emitsInAnyOrder([isNotNull]));
  });
}
