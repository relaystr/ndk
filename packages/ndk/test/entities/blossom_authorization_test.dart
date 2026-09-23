import 'dart:async';

import 'package:ndk/ndk.dart';
import 'package:test/test.dart';

Nip01Event _authEvent(String content) => Nip01Event(
      pubKey:
          'd0a1ffb8761b974cec4a3be8cbcb2e96a7090dcf465ffeac839aa4ca20c9a59e',
      kind: 24242,
      tags: [
        ['t', content],
      ],
      content: content,
    );

const _first = 'https://first.example';
const _second = 'https://second.example';
const _third = 'https://third.example';

void main() {
  group('BlossomAuthorization.none', () {
    test('never produces an event', () async {
      const auth = BlossomAuthorization.none();

      expect(auth.upfront, isNull);
      expect(auth.resolvedFor(_first), isNull);
      expect(await auth.onRefusal(_first), isNull);
    });
  });

  group('BlossomAuthorization.upfront', () {
    test('produces its event before and after a refusal', () async {
      final event = _authEvent('upload');
      final auth = BlossomAuthorization.upfront(event);

      expect(auth.upfront, same(event));
      expect(auth.resolvedFor(_first), same(event));
      expect(await auth.onRefusal(_first), same(event));
    });
  });

  group('BlossomAuthorization.onRefusal', () {
    test('sends nothing until a server refuses', () {
      var signed = false;
      final auth = BlossomAuthorization.onRefusal(() async {
        signed = true;
        return _authEvent('get');
      });

      expect(auth.upfront, isNull);
      expect(auth.resolvedFor(_first), isNull);
      expect(signed, false, reason: 'building the policy must not sign');
    });

    test('signs once a server refuses, and remembers the signature', () async {
      final event = _authEvent('get');
      final auth = BlossomAuthorization.onRefusal(() async => event);

      expect(await auth.onRefusal(_first), same(event));
      expect(auth.resolvedFor(_first), same(event),
          reason: 'that server should not have to refuse again');
      expect(auth.upfront, isNull);
    });

    test('keeps the signature from a server that never refused', () async {
      final auth = BlossomAuthorization.onRefusal(
        () async => _authEvent('get'),
      );

      await auth.onRefusal(_first);

      expect(auth.resolvedFor(_second), isNull,
          reason: 'it never asked, so it must not learn who is asking');
    });

    test('signs once for concurrent refusals from several servers', () async {
      var signatures = 0;
      final gate = Completer<void>();
      final auth = BlossomAuthorization.onRefusal(() async {
        signatures++;
        await gate.future;
        return _authEvent('delete');
      });

      // three servers refuse before any signature came back
      final pending = [
        auth.onRefusal(_first),
        auth.onRefusal(_second),
        auth.onRefusal(_third),
      ];
      gate.complete();
      final events = await Future.wait(pending);

      expect(signatures, 1,
          reason: 'a remote signer would otherwise prompt once per server');
      expect(events.toSet(), hasLength(1));
    });

    test('signs once for sequential refusals', () async {
      var signatures = 0;
      final auth = BlossomAuthorization.onRefusal(() async {
        signatures++;
        return _authEvent('list');
      });

      await auth.onRefusal(_first);
      await auth.onRefusal(_second);

      expect(signatures, 1);
    });

    test('a signature the user turned down is not asked for again', () async {
      var prompts = 0;
      final auth = BlossomAuthorization.onRefusal(() async {
        prompts++;
        throw SignerRequestCancelledException('request-1');
      });

      await expectLater(auth.onRefusal(_first),
          throwsA(isA<SignerRequestCancelledException>()));
      await expectLater(auth.onRefusal(_second),
          throwsA(isA<SignerRequestCancelledException>()));

      expect(prompts, 1,
          reason: 'the user already declined, asking again is nagging');
      expect(auth.resolvedFor(_first), isNull);
    });

    test('an error from the remote signer is asked for again', () async {
      var prompts = 0;
      final auth = BlossomAuthorization.onRefusal(() async {
        prompts++;
        throw SignerRequestRejectedException(requestId: 'request-1');
      });

      await expectLater(auth.onRefusal(_first),
          throwsA(isA<SignerRequestRejectedException>()));
      await expectLater(auth.onRefusal(_second),
          throwsA(isA<SignerRequestRejectedException>()));

      expect(prompts, 2,
          reason: 'a bunker reports an unknown method the same way it reports '
              'a refusal, so this one cannot be read as a decision');
    });

    test('a signature that failed for any other reason is asked for again',
        () async {
      var prompts = 0;
      final auth = BlossomAuthorization.onRefusal(() async {
        prompts++;
        throw Exception('bunker connection dropped');
      });

      await expectLater(auth.onRefusal(_first), throwsA(isA<Exception>()));
      await expectLater(auth.onRefusal(_second), throwsA(isA<Exception>()));

      expect(prompts, 2,
          reason: 'a timeout says nothing about whether the user would agree');
    });

    test('a later server can still succeed after a transient failure',
        () async {
      final event = _authEvent('get');
      var prompts = 0;
      final auth = BlossomAuthorization.onRefusal(() async {
        prompts++;
        if (prompts == 1) throw Exception('bunker connection dropped');
        return event;
      });

      await expectLater(auth.onRefusal(_first), throwsA(isA<Exception>()));

      expect(await auth.onRefusal(_second), same(event));
      expect(auth.resolvedFor(_second), same(event));
    });
  });
}
