import 'package:ndk/ndk.dart';
import 'package:test/test.dart';
import 'package:http/http.dart' as http;

void main() {
  test('Get blobs with NDK', () async {
    final ndk = Ndk.defaultConfig();

    ndk.accounts.loginPrivateKey(
      pubkey:
          "672a31bfc59d3f04548ec9b7daeeba2f61814e8ccc40448045007f5479f693a3",
      privkey:
          "3501454135014541350145413501453fefb02227e449e57cf4d3a3ce05378683",
    );

    final blobs = await ndk.blossom.listBlobs(
      pubkey: ndk.accounts.getPublicKey()!,
      serverUrls: ["https://blossom.primal.net"],
    );

    print(blobs.length);
  });

  test('Get blobs manually', () async {
    final ndk = Ndk.defaultConfig();

    ndk.accounts.loginPrivateKey(
      pubkey:
          "672a31bfc59d3f04548ec9b7daeeba2f61814e8ccc40448045007f5479f693a3",
      privkey:
          "3501454135014541350145413501453fefb02227e449e57cf4d3a3ce05378683",
    );

    final authEvent = Nip01Event(
      pubKey: ndk.accounts.getPublicKey()!,
      kind: 24242,
      tags: [
        ["t", "list"],
        [
          "expiration",
          ((DateTime.now().millisecondsSinceEpoch ~/ 1000) + 60).toString(),
        ],
      ],
      content: "List Blobs",
    );

    ndk.accounts.getLoggedAccount()!.signer.sign(authEvent);

    final uri = Uri.parse(
      'https://blossom.primal.net/list/${ndk.accounts.getPublicKey()!}',
    );

    final response = await http.get(
      uri,
      headers: {'Authorization': 'Nostr ${authEvent.toBase64()}'},
    );

    print(response.body);
  });
}