import 'dart:convert';
import 'dart:typed_data';

import 'package:ndk/entities.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/bip340.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';
import 'package:test/test.dart';

import '../../mocks/mock_blossom_server.dart';
import '../../mocks/mock_event_verifier.dart';

const int filesAuthPort = 30050;

Account _signable(KeyPair keyPair) => Account(
      type: AccountType.privateKey,
      pubkey: keyPair.publicKey,
      signer: Bip340EventSigner(
        privateKey: keyPair.privateKey,
        publicKey: keyPair.publicKey,
      ),
    );

/// The facade owns no policy of its own, it only has to hand one down.
void main() {
  late MockBlossomServer server;
  late Files files;
  late Account other;
  late String serverUrl;

  setUp(() async {
    server = MockBlossomServer(port: filesAuthPort, authRefusalStatus: 401);
    await server.start();
    serverUrl = 'http://localhost:$filesAuthPort';

    final key = Bip340.generatePrivateKey();
    other = _signable(Bip340.generatePrivateKey());

    final ndk = Ndk(
      NdkConfig(
        eventVerifier: MockEventVerifier(),
        cache: MemCacheManager(),
        engine: NdkEngine.JIT,
      ),
    );
    ndk.accounts.loginPrivateKey(
      pubkey: key.publicKey,
      privkey: key.privateKey!,
    );
    files = ndk.files;
  });

  tearDown(() async => server.stop());

  test('upload carries the identity the policy names', () async {
    await files.upload(
      file: NdkFile(
        data: Uint8List.fromList(utf8.encode('through the facade')),
        mimeType: 'text/plain',
      ),
      serverUrls: [serverUrl],
      auth: AuthPolicy.require(other),
    );

    final puts = server.requests.where((r) => r.method == 'PUT').toList();
    expect(puts.single.authPubkey, other.pubkey);
  });

  test('download authorises only once the server asks', () async {
    final uploaded = await files.upload(
      file: NdkFile(
        data: Uint8List.fromList(utf8.encode('facade blob')),
        mimeType: 'text/plain',
      ),
      serverUrls: [serverUrl],
    );
    final sha256 = uploaded.first.descriptor!.sha256;
    server.clearRequests();
    server.requireAuthForReads = true;

    final blob = await files.download(
      url: '$serverUrl/$sha256',
      serverUrls: [serverUrl],
      auth: AuthPolicy.allow(other),
    );

    expect(utf8.decode(blob.data), 'facade blob');

    final gets = server.requests.where((r) => r.method == 'GET').toList();
    expect(gets, hasLength(2));
    expect(gets.first.hasAuth, false);
    expect(gets.last.authPubkey, other.pubkey);
  });

  test('a plain url is fetched directly and never carries a policy', () async {
    final response = await files.download(
      url: '$serverUrl/static/test.txt',
      auth: AuthPolicy.require(other),
    );

    expect(utf8.decode(response.data), contains('Static file content'));
    expect(server.countRequests(hasAuth: true), 0);
  });
}
