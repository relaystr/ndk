// ignore_for_file: avoid_print

import 'package:ndk/ndk.dart';
import 'package:test/test.dart';

void main() async {
  test('download test - blossom', () async {
    final ndk = Ndk.defaultConfig();

    final downloadResult = await ndk.files.download(
        url:
            "https://cdn.hzrd149.com/b1674191a88ec5cdd733e4240a81803105dc412d6c6708d53ab94fc248f4f553.pdf");

    print(
        "file of type: ${downloadResult.mimeType}, size: ${downloadResult.data.length}");

    expect(downloadResult.data.length, greaterThan(0));
  });

  test('download test - non blossom', () async {
    final ndk = Ndk.defaultConfig();

    final downloadResult = await ndk.files
        .download(url: "https://camelus.app/.well-known/nostr.json");

    print(
        "file of type: ${downloadResult.mimeType}, size: ${downloadResult.data.length}");

    expect(downloadResult.data.length, greaterThan(0));
  });
}
