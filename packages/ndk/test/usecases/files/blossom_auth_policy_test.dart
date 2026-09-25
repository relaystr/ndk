import 'dart:convert';
import 'dart:typed_data';

import 'package:ndk/config/blossom_config.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/bip340.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';
import 'package:test/test.dart';

import '../../mocks/mock_blossom_server.dart';
import '../../mocks/mock_event_verifier.dart';

const int policyPort = 30040;

Account _signable(KeyPair keyPair) => Account(
      type: AccountType.privateKey,
      pubkey: keyPair.publicKey,
      signer: Bip340EventSigner(
        privateKey: keyPair.privateKey,
        publicKey: keyPair.publicKey,
      ),
    );

Account _watchOnly(KeyPair keyPair) => Account(
      type: AccountType.publicKey,
      pubkey: keyPair.publicKey,
      signer: Bip340EventSigner(privateKey: null, publicKey: keyPair.publicKey),
    );

void main() {
  late MockBlossomServer server;
  late Blossom client;
  late Account loggedIn;
  late Account other;
  late String serverUrl;

  setUp(() async {
    server = MockBlossomServer(port: policyPort, authRefusalStatus: 401);
    await server.start();
    serverUrl = 'http://localhost:$policyPort';

    final key = Bip340.generatePrivateKey();
    loggedIn = _signable(key);
    other = _signable(Bip340.generatePrivateKey());

    final ndk = Ndk(
      NdkConfig(
        eventVerifier: MockEventVerifier(),
        cache: MemCacheManager(),
        engine: NdkEngine.JIT,
      ),
    );
    ndk.accounts
        .loginPrivateKey(pubkey: key.publicKey, privkey: key.privateKey!);
    client = ndk.blossom;
  });

  tearDown(() async => server.stop());

  Future<String> seed(String content) async {
    final uploaded = await client.uploadBlob(
      data: Uint8List.fromList(utf8.encode(content)),
      serverUrls: [serverUrl],
    );
    expect(uploaded.first.success, true);
    server.clearRequests();
    return uploaded.first.descriptor!.sha256;
  }

  group('on a server that demands an identity', () {
    late String sha256;

    setUp(() async {
      sha256 = await seed('private blob');
      server.requireAuthForReads = true;
    });

    test('never() stays anonymous and is simply not served', () async {
      await expectLater(
        client.getBlob(
          sha256: sha256,
          serverUrls: [serverUrl],
          auth: const AuthPolicy.never(),
        ),
        throwsA(isA<Exception>()),
      );

      expect(server.countRequests(hasAuth: true), 0);
    });

    test('allow() reveals the identity only once asked', () async {
      final blob = await client.getBlob(
        sha256: sha256,
        serverUrls: [serverUrl],
        auth: AuthPolicy.allow(other),
      );

      expect(utf8.decode(blob.data), 'private blob');

      final gets = server.requests.where((r) => r.method == 'GET').toList();
      expect(gets, hasLength(2));
      expect(gets.first.hasAuth, false);
      expect(gets.last.authPubkey, other.pubkey);
    });

    test('require() reveals it from the start', () async {
      await client.getBlob(
        sha256: sha256,
        serverUrls: [serverUrl],
        auth: AuthPolicy.require(other),
      );

      final gets = server.requests.where((r) => r.method == 'GET').toList();
      expect(gets, hasLength(1));
      expect(gets.single.authPubkey, other.pubkey);
    });

    test('the authorization it signs is short lived', () async {
      await client.getBlob(
        sha256: sha256,
        serverUrls: [serverUrl],
        auth: AuthPolicy.require(other),
      );

      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      expect(
        server.requests.single.authExpiration,
        inInclusiveRange(now, now + BLOSSOM_AUTH_EXPIRATION.inSeconds),
      );
    });

    test('require() with an account that cannot sign sends nothing', () async {
      final watcher = _watchOnly(Bip340.generatePrivateKey());

      await expectLater(
        client.getBlob(
          sha256: sha256,
          serverUrls: [serverUrl],
          auth: AuthPolicy.require(watcher),
        ),
        throwsA(isA<BlossomAuthUnavailableException>()),
      );

      expect(server.requests, isEmpty,
          reason: 'going out bare is what require() rules out');
    });

    test('allow() with an account that cannot sign behaves as never()',
        () async {
      final watcher = _watchOnly(Bip340.generatePrivateKey());

      await expectLater(
        client.getBlob(
          sha256: sha256,
          serverUrls: [serverUrl],
          auth: AuthPolicy.allow(watcher),
        ),
        throwsA(isA<Exception>()),
      );

      expect(server.countRequests(hasAuth: true), 0);
    });
  });

  group('on a server that never asks', () {
    test('allow() never reveals the identity', () async {
      final sha256 = await seed('public blob');

      await client.getBlob(
        sha256: sha256,
        serverUrls: [serverUrl],
        auth: AuthPolicy.allow(other),
      );

      expect(server.countRequests(hasAuth: true), 0);
      expect(server.countRequests(method: 'GET'), 1);
    });
  });

  group('an upload', () {
    test('authorises as the account auth names, not the logged-in one',
        () async {
      final data = Uint8List.fromList(utf8.encode('mine to attribute'));

      await client.uploadBlob(
        data: data,
        serverUrls: [serverUrl],
        auth: AuthPolicy.require(other),
      );

      final puts = server.requests.where((r) => r.method == 'PUT').toList();
      expect(puts.single.authPubkey, other.pubkey);
      expect(puts.single.authPubkey, isNot(loggedIn.pubkey));
    });

    test('under never() sends no authorization at all', () async {
      final data = Uint8List.fromList(utf8.encode('anonymous upload'));

      await client.uploadBlob(
        data: data,
        serverUrls: [serverUrl],
        auth: const AuthPolicy.never(),
      );

      expect(server.countRequests(method: 'PUT', hasAuth: true), 0);
    });
  });

  group('a streamed download', () {
    late MockBlossomServer ranged;
    late Blossom rangedClient;
    late Account rangedOther;

    setUp(() async {
      ranged = MockBlossomServer(
        port: policyPort + 1,
        authRefusalStatus: 401,
        supportRangeRequests: true,
      );
      await ranged.start();

      final key = Bip340.generatePrivateKey();
      rangedOther = _signable(Bip340.generatePrivateKey());
      final ndk = Ndk(
        NdkConfig(
          eventVerifier: MockEventVerifier(),
          cache: MemCacheManager(),
          engine: NdkEngine.JIT,
        ),
      );
      ndk.accounts
          .loginPrivateKey(pubkey: key.publicKey, privkey: key.privateKey!);
      rangedClient = ndk.blossom;
    });

    tearDown(() async => ranged.stop());

    test('pays the refusal once for the whole stream', () async {
      final url = 'http://localhost:${ranged.port}';
      final data = Uint8List.fromList(utf8.encode('a' * 64));

      final uploaded =
          await rangedClient.uploadBlob(data: data, serverUrls: [url]);
      final sha256 = uploaded.first.descriptor!.sha256;
      ranged.clearRequests();
      ranged.requireAuthForReads = true;

      final stream = await rangedClient.getBlobStream(
        sha256: sha256,
        serverUrls: [url],
        chunkSize: 16,
        auth: AuthPolicy.allow(rangedOther),
      );
      final chunks = await stream.toList();

      expect(
        chunks.map((c) => utf8.decode(c.data)).join(),
        utf8.decode(data),
      );
      expect(ranged.countRequests(hasAuth: false), 1,
          reason: 'only the very first request should go out bare');
      expect(ranged.signedEventIds, hasLength(1));
    });
  });

  group('a report', () {
    late String sha256;

    setUp(() async => sha256 = await seed('reported blob'));

    Future<int> report({AuthPolicy? auth}) => client.report(
          sha256: sha256,
          eventId: 'e' * 64,
          reportType: 'malware',
          reportMsg: 'this blob is malware',
          serverUrl: serverUrl,
          auth: auth,
        );

    test('names the account auth points at', () async {
      await report(auth: AuthPolicy.require(other));

      expect(server.reports.single['pubkey'], other.pubkey);
    });

    test('under never() is signed by a throwaway key', () async {
      await report(auth: const AuthPolicy.never());

      expect(server.reports.single['pubkey'], isNot(loggedIn.pubkey));
      expect(server.reports.single['pubkey'], isNot(other.pubkey));
    });

    test('under require() with an account that cannot sign sends nothing',
        () async {
      final watcher = _watchOnly(Bip340.generatePrivateKey());

      await expectLater(
        report(auth: AuthPolicy.require(watcher)),
        throwsA(isA<BlossomAuthUnavailableException>()),
      );

      expect(server.reports, isEmpty);
    });

    test('under allow() with an account that cannot sign stays anonymous',
        () async {
      final watcher = _watchOnly(Bip340.generatePrivateKey());

      await report(auth: AuthPolicy.allow(watcher));

      expect(server.reports.single['pubkey'], isNot(loggedIn.pubkey));
      expect(server.reports.single['pubkey'], isNot(watcher.pubkey));
    });

    test('without auth still signs as the logged-in account', () async {
      await report();

      expect(server.reports.single['pubkey'], loggedIn.pubkey);
    });
  });
}
