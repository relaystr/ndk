import 'package:flutter_test/flutter_test.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk_flutter/main/ndk_flutter.dart';
import 'package:ndk_flutter/widgets/message_of_the_day/motd_data.dart';
import 'package:ndk_flutter/widgets/message_of_the_day/n_motd_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _StubRequests implements Requests {
  final List<Nip01Event> events;

  _StubRequests(this.events);

  @override
  NdkResponse query({
    Filter? filter,
    List<Filter>? filters,
    String name = '',
    RelaySet? relaySet,
    bool cacheRead = true,
    bool cacheWrite = true,
    Duration? timeout,
    Function()? timeoutCallbackUserFacing,
    Function()? timeoutCallback,
    Iterable<String>? explicitRelays,
    int? desiredCoverage,
    RelayAuth? auth,
    List<Account>? authenticateAs,
    bool paginate = false,
  }) {
    return NdkResponse(
      'query',
      Stream<Nip01Event>.fromIterable(events),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('Unexpected Requests call: ${invocation.memberName}');
}

class _StubNdk implements Ndk {
  final List<Nip01Event> events;

  _StubNdk(this.events);

  @override
  Requests get requests => _StubRequests(events);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('Unexpected NDK call: ${invocation.memberName}');
}

class _FailingRequests implements Requests {
  @override
  NdkResponse query({
    Filter? filter,
    List<Filter>? filters,
    String name = '',
    RelaySet? relaySet,
    bool cacheRead = true,
    bool cacheWrite = true,
    Duration? timeout,
    Function()? timeoutCallbackUserFacing,
    Function()? timeoutCallback,
    Iterable<String>? explicitRelays,
    int? desiredCoverage,
    RelayAuth? auth,
    List<Account>? authenticateAs,
    bool paginate = false,
  }) {
    throw StateError('query failed');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('Unexpected Requests call: ${invocation.memberName}');
}

class _FailingNdk implements Ndk {
  const _FailingNdk();

  @override
  Requests get requests => _FailingRequests();

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('Unexpected NDK call: ${invocation.memberName}');
}

Nip01Event _motdEvent({
  required String id,
  String content = 'Hello world',
  List<List<String>> tags = const [
    ['d', 'motd'],
  ],
  int createdAt = 100,
  String pubKey = 'author',
}) => Nip01Event(
  id: id,
  pubKey: pubKey,
  kind: MotdData.kKind,
  tags: tags,
  content: content,
  createdAt: createdAt,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('compareVersions', () {
    test('orders numeric segments', () {
      expect(NMotdController.compareVersions('1.10.0', '1.9.0'), greaterThan(0));
      expect(NMotdController.compareVersions('1.9.0', '1.10.0'), lessThan(0));
      expect(NMotdController.compareVersions('2.0.0', '1.99.99'), greaterThan(0));
    });

    test('treats missing segments as zero', () {
      expect(NMotdController.compareVersions('1.0', '1.0.0'), 0);
      expect(NMotdController.compareVersions('1.9', '1.10.0'), lessThan(0));
    });

    test('handles pre-release suffixes', () {
      expect(
        NMotdController.compareVersions('1.0.0-beta', '1.0.0'),
        lessThan(0),
      );
      expect(
        NMotdController.compareVersions('1.0.0', '1.0.0-beta'),
        greaterThan(0),
      );
      expect(NMotdController.compareVersions('1.0.0-beta', '1.0.0-beta'), 0);
    });

    test('ignores build metadata', () {
      expect(NMotdController.compareVersions('1.0.0+42', '1.0.0'), 0);
    });

    test('returns zero for equal versions', () {
      expect(NMotdController.compareVersions('3.2.1', '3.2.1'), 0);
    });
  });

  group('resolveLinkUrl', () {
    test('accepts https urls', () {
      expect(
        MotdData.resolveLinkUrl('https://example.com/motd')?.toString(),
        'https://example.com/motd',
      );
      // Scheme comparison is case insensitive.
      expect(
        MotdData.resolveLinkUrl('HTTPS://example.com')?.scheme,
        'https',
      );
    });

    test('rejects schemes outside the allow list', () {
      expect(MotdData.resolveLinkUrl('http://example.com'), isNull);
      expect(MotdData.resolveLinkUrl('javascript:alert(1)'), isNull);
      expect(MotdData.resolveLinkUrl('intent://scan#Intent;end'), isNull);
      expect(MotdData.resolveLinkUrl('file:///etc/passwd'), isNull);
      expect(MotdData.resolveLinkUrl('myapp://settings'), isNull);
    });

    test('accepts extra schemes when explicitly allowed', () {
      final uri = MotdData.resolveLinkUrl(
        'myapp://settings',
        allowedSchemes: {'https', 'myapp'},
      );
      expect(uri?.toString(), 'myapp://settings');
    });

    test('rejects malformed and host-less urls without throwing', () {
      expect(MotdData.resolveLinkUrl(null), isNull);
      expect(MotdData.resolveLinkUrl(''), isNull);
      expect(MotdData.resolveLinkUrl('   '), isNull);
      expect(MotdData.resolveLinkUrl('example.com'), isNull);
      expect(MotdData.resolveLinkUrl('https://'), isNull);
      expect(MotdData.resolveLinkUrl('https:///path'), isNull);
      expect(MotdData.resolveLinkUrl('http://[::1'), isNull);
      expect(MotdData.resolveLinkUrl('ht\ttp://example.com'), isNull);
    });
  });

  group('NMotdController', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('starts hidden when no message exists', () async {
      final controller = NMotdController(
        ndkFlutter: NdkFlutter(ndk: _StubNdk(const [])),
        authorPubkey: 'author',
      );
      await controller.start();

      expect(controller.status, NMotdStatus.loaded);
      expect(controller.current, isNull);
      expect(controller.shouldShow(), isFalse);
    });

    test('shows when a message exists', () async {
      final controller = NMotdController(
        ndkFlutter: NdkFlutter(
          ndk: _StubNdk([
            _motdEvent(id: 'event-1', content: 'Hello'),
          ]),
        ),
        authorPubkey: 'author',
      );
      await controller.start();

      expect(controller.status, NMotdStatus.loaded);
      expect(controller.current?.message, 'Hello');
      expect(controller.current?.url, isNull);
      expect(controller.current?.version, isNull);
      expect(controller.shouldShow(), isTrue);
    });

    test('parses title, url and version tags', () async {
      final controller = NMotdController(
        ndkFlutter: NdkFlutter(
          ndk: _StubNdk([
            _motdEvent(
              id: 'event-1',
              tags: const [
                ['d', 'motd'],
                ['title', 'Hello from the team'],
                ['url', 'https://example.com'],
                ['version', '2.0.0'],
              ],
            ),
          ]),
        ),
        authorPubkey: 'author',
      );
      await controller.start();

      expect(controller.current?.title, 'Hello from the team');
      expect(controller.current?.url, 'https://example.com');
      expect(controller.current?.version, '2.0.0');
      expect(
        controller.shouldShow(appVersion: '1.0.0'),
        isTrue,
      );
    });

    test('parses url and version tags', () async {
      final controller = NMotdController(
        ndkFlutter: NdkFlutter(
          ndk: _StubNdk([
            _motdEvent(
              id: 'event-1',
              tags: const [
                ['d', 'motd'],
                ['url', 'https://example.com'],
                ['version', '2.0.0'],
              ],
            ),
          ]),
        ),
        authorPubkey: 'author',
      );
      await controller.start();

      expect(controller.current?.url, 'https://example.com');
      expect(controller.current?.version, '2.0.0');
      expect(
        controller.shouldShow(appVersion: '1.0.0'),
        isTrue,
      );
    });

    test('filters by nostr version when both versions are present', () async {
      final controller = NMotdController(
        ndkFlutter: NdkFlutter(
          ndk: _StubNdk([
            _motdEvent(
              id: 'event-1',
              tags: const [
                ['d', 'motd'],
                ['version', '1.2.0'],
              ],
            ),
          ]),
        ),
        authorPubkey: 'author',
      );
      await controller.start();

      // nostr version > app version -> show
      expect(controller.shouldShow(appVersion: '1.0.0'), isTrue);
      // nostr version == app version -> hide
      expect(controller.shouldShow(appVersion: '1.2.0'), isFalse);
      // nostr version < app version -> hide
      expect(controller.shouldShow(appVersion: '2.0.0'), isFalse);
      // no app version -> version filtering is skipped
      expect(controller.shouldShow(), isTrue);
    });

    test('ignores events with a different d tag', () async {
      final controller = NMotdController(
        ndkFlutter: NdkFlutter(
          ndk: _StubNdk([
            _motdEvent(
              id: 'event-1',
              tags: const [
                ['d', 'announcements'],
              ],
            ),
          ]),
        ),
        authorPubkey: 'author',
        dTagValue: 'motd',
      );
      await controller.start();

      expect(controller.current, isNull);
      expect(controller.shouldShow(), isFalse);
    });

    test('ignores events signed by another author', () async {
      // A relay may ignore the requested author filter and return a valid
      // event signed by an attacker.
      final controller = NMotdController(
        ndkFlutter: NdkFlutter(
          ndk: _StubNdk([
            _motdEvent(
              id: 'attacker-event',
              content: 'Malicious message',
              createdAt: 999,
              pubKey: 'attacker',
              tags: const [
                ['d', 'motd'],
                ['url', 'https://evil.example.com'],
              ],
            ),
            _motdEvent(
              id: 'legit-event',
              content: 'Legit message',
              createdAt: 100,
            ),
          ]),
        ),
        authorPubkey: 'author',
      );
      await controller.start();

      expect(controller.status, NMotdStatus.loaded);
      expect(controller.current?.eventId, 'legit-event');
      expect(controller.current?.message, 'Legit message');
    });

    test('shows nothing when only a foreign author matches', () async {
      final controller = NMotdController(
        ndkFlutter: NdkFlutter(
          ndk: _StubNdk([
            _motdEvent(
              id: 'attacker-event',
              content: 'Malicious message',
              pubKey: 'attacker',
            ),
          ]),
        ),
        authorPubkey: 'author',
      );
      await controller.start();

      expect(controller.current, isNull);
      expect(controller.shouldShow(), isFalse);
    });

    test('picks the newest message from cache', () async {
      final controller = NMotdController(
        ndkFlutter: NdkFlutter(
          ndk: _StubNdk([
            _motdEvent(id: 'old', content: 'old', createdAt: 100),
            _motdEvent(id: 'new', content: 'new', createdAt: 200),
          ]),
        ),
        authorPubkey: 'author',
      );
      await controller.start();

      expect(controller.current?.eventId, 'new');
      expect(controller.current?.message, 'new');
    });

    test('dismiss suppresses the popup until a new version arrives', () async {
      final controller = NMotdController(
        ndkFlutter: NdkFlutter(
          ndk: _StubNdk([
            _motdEvent(id: 'event-1', content: 'Hello'),
          ]),
        ),
        authorPubkey: 'author',
      );
      await controller.start();
      expect(controller.shouldShow(), isTrue);

      await controller.dismiss();
      expect(controller.shouldShow(), isFalse);

      // A new controller instance (same author + d tag) restores dismissal.
      final fresh = NMotdController(
        ndkFlutter: NdkFlutter(
          ndk: _StubNdk([
            _motdEvent(id: 'event-1', content: 'Hello'),
          ]),
        ),
        authorPubkey: 'author',
      );
      await fresh.start();
      expect(fresh.shouldShow(), isFalse);

      // But a changed message is shown again.
      final updated = NMotdController(
        ndkFlutter: NdkFlutter(
          ndk: _StubNdk([
            _motdEvent(id: 'event-2', content: 'Updated'),
          ]),
        ),
        authorPubkey: 'author',
      );
      await updated.start();
      expect(updated.shouldShow(), isTrue);
    });

    test('exposes the error when the lookup fails', () async {
      final controller = NMotdController(
        ndkFlutter: NdkFlutter(ndk: const _FailingNdk()),
        authorPubkey: 'author',
      );
      await controller.start();

      expect(controller.status, NMotdStatus.error);
      expect(controller.error, isNotNull);
      expect(controller.shouldShow(), isFalse);
    });
  });
}