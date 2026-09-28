import 'dart:convert';
import 'dart:typed_data';

import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/bip340.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';
import 'package:test/test.dart';

import '../../mocks/mock_blossom_server.dart';
import '../../mocks/mock_event_verifier.dart';

const int handlerPortA = 30060;
const int handlerPortB = 30061;

void main() {
  late MockBlossomServer serverA;
  late MockBlossomServer serverB;
  late String urlA;
  late String urlB;
  late KeyPair key;
  late List<(String, String)> asked;
  late bool Function(String url) answer;

  Blossom clientWith({required bool handler}) {
    final ndk = Ndk(
      NdkConfig(
        eventVerifier: MockEventVerifier(),
        cache: MemCacheManager(),
        engine: NdkEngine.JIT,
        bootstrapRelays: [],
        authHandler: handler
            ? (url, pubkey) async {
                asked.add((url, pubkey));
                return answer(url);
              }
            : null,
      ),
    );
    ndk.accounts
        .loginPrivateKey(pubkey: key.publicKey, privkey: key.privateKey!);
    return ndk.blossom;
  }

  Uint8List bytes(String content) => Uint8List.fromList(utf8.encode(content));

  setUp(() async {
    serverA = MockBlossomServer(
      port: handlerPortA,
      authRefusalStatus: 401,
      supportRangeRequests: true,
    );
    serverB = MockBlossomServer(port: handlerPortB, authRefusalStatus: 401);
    await serverA.start();
    await serverB.start();
    urlA = 'http://localhost:$handlerPortA';
    urlB = 'http://localhost:$handlerPortB';
    key = Bip340.generatePrivateKey();
    asked = [];
    answer = (_) => true;
  });

  tearDown(() async {
    await serverA.stop();
    await serverB.stop();
  });

  group('a write without auth', () {
    test('goes out only to the servers the handler agrees to', () async {
      answer = (url) => url == urlA;
      final client = clientWith(handler: true);

      await client.uploadBlob(
        data: bytes('consented upload'),
        serverUrls: [urlA, urlB],
      );

      expect(asked, [(urlA, key.publicKey), (urlB, key.publicKey)]);
      expect(serverA.requests.single.authPubkey, key.publicKey);
      expect(serverB.requests, isEmpty);
    });

    test('sends and signs nothing when no server may see the account',
        () async {
      answer = (_) => false;
      final client = clientWith(handler: true);

      await expectLater(
        client.deleteBlob(sha256: 'a' * 64, serverUrls: [urlA, urlB]),
        throwsA(isA<BlossomAuthUnavailableException>()),
      );

      expect(serverA.requests, isEmpty);
      expect(serverB.requests, isEmpty);
    });

    test('signs with a throwaway key when there is no handler', () async {
      final client = clientWith(handler: false);

      await client.uploadBlob(
        data: bytes('anonymous upload'),
        serverUrls: [urlA],
      );

      final put = serverA.requests.single;
      expect(put.hasAuth, isTrue);
      expect(put.authPubkey, isNot(key.publicKey));
    });
  });

  group('require()', () {
    test('asks before sending and skips a server the handler refuses',
        () async {
      answer = (url) => url == urlB;
      final client = clientWith(handler: true);
      final other = Bip340.generatePrivateKey();
      final account = Account(
        type: AccountType.privateKey,
        pubkey: other.publicKey,
        signer: Bip340EventSigner(
          privateKey: other.privateKey,
          publicKey: other.publicKey,
        ),
      );

      final results = await client.mirrorToServers(
        blossomUrl: Uri.parse('https://cdn.example.com/${'b' * 64}'),
        targetServerUrls: [urlA, urlB],
        auth: AuthPolicy.require(account),
      );

      expect(results, hasLength(1));
      expect(asked.map((q) => q.$2), everyElement(other.publicKey));
      expect(serverA.requests, isEmpty);
      expect(serverB.requests.single.authPubkey, other.publicKey);
    });
  });

  group('a read that is refused', () {
    late String sha256;

    setUp(() async {
      final seeded = await clientWith(handler: false).uploadBlob(
        data: bytes('private blob ' * 300),
        serverUrls: [urlA],
      );
      sha256 = seeded.single.descriptor!.sha256;
      serverA.requireAuthForReads = true;
      serverA.clearRequests();
    });

    test('reveals nothing once the handler says no', () async {
      answer = (_) => false;
      final client = clientWith(handler: true);
      final account = Account(
        type: AccountType.privateKey,
        pubkey: key.publicKey,
        signer: Bip340EventSigner(
          privateKey: key.privateKey,
          publicKey: key.publicKey,
        ),
      );

      await expectLater(
        client.getBlob(
          sha256: sha256,
          serverUrls: [urlA],
          auth: AuthPolicy.allow(account),
        ),
        throwsA(isA<Exception>()),
      );

      expect(asked, [(urlA, key.publicKey)]);
      expect(serverA.countRequests(hasAuth: true), 0);
    });

    test('asks once per server for a whole stream', () async {
      final client = clientWith(handler: true);
      final account = Account(
        type: AccountType.privateKey,
        pubkey: key.publicKey,
        signer: Bip340EventSigner(
          privateKey: key.privateKey,
          publicKey: key.publicKey,
        ),
      );

      final stream = await client.getBlobStream(
        sha256: sha256,
        serverUrls: [urlA],
        auth: AuthPolicy.allow(account),
        chunkSize: 1024,
      );
      final chunks = await stream.toList();

      expect(chunks.length, greaterThan(1));
      expect(asked, [(urlA, key.publicKey)]);
    });
  });

  group('a report', () {
    test('without auth sends nothing once the handler says no', () async {
      answer = (_) => false;
      final client = clientWith(handler: true);

      await expectLater(
        client.report(
          sha256: 'c' * 64,
          eventId: 'd' * 64,
          reportType: 'malware',
          reportMsg: 'bad',
          serverUrl: urlA,
        ),
        throwsA(isA<BlossomAuthUnavailableException>()),
      );

      expect(serverA.reports, isEmpty);
    });

    test('without auth signs as the logged account once agreed', () async {
      final client = clientWith(handler: true);

      await client.report(
        sha256: 'c' * 64,
        eventId: 'd' * 64,
        reportType: 'malware',
        reportMsg: 'bad',
        serverUrl: urlA,
      );

      expect(serverA.reports.single['pubkey'], key.publicKey);
    });
  });
}
