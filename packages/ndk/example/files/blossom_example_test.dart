// ignore_for_file: avoid_print

import 'package:ndk/ndk.dart';
import 'package:test/test.dart';

void main() async {
  test('download test', () async {
    final ndk = Ndk.defaultConfig();

    final downloadResult = await ndk.blossom.getBlob(
      sha256:
          "b1674191a88ec5cdd733e4240a81803105dc412d6c6708d53ab94fc248f4f553",
      serverUrls: ["https://cdn.hzrd149.com", "https://nostr.download"],
    );

    print(
      "file of type: ${downloadResult.mimeType}, size: ${downloadResult.data.length}",
    );

    expect(downloadResult.data.length, greaterThan(0));
  }, skip: true);
}
