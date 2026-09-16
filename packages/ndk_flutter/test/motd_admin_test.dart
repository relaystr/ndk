import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk_flutter/l10n/app_localizations.dart';
import 'package:ndk_flutter/main/ndk_flutter.dart';
import 'package:ndk_flutter/widgets/message_of_the_day/motd_data.dart';
import 'package:ndk_flutter/widgets/message_of_the_day/n_motd_admin.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _author = 'author';

class _FakeSigner implements EventSigner {
  late final String pubkey;
  final eventsSigned = <Nip01Event>[];

  _FakeSigner([this.pubkey = _author]);

  @override
  String getPublicKey() => pubkey;

  @override
  Future<Nip01Event> sign(Nip01Event event) async {
    eventsSigned.add(event);
    return event;
  }

  @override
  bool canSign() => true;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('Unexpected signer call: ${invocation.memberName}');
}

class _FakeAccounts implements Accounts {
  final _FakeSigner signer;

  _FakeAccounts(this.signer);

  @override
  Account? getLoggedAccount() => Account(
    type: AccountType.privateKey,
    pubkey: signer.pubkey,
    signer: signer,
  );

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('Unexpected accounts call: ${invocation.memberName}');
}

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

class _FakeBroadcast implements Broadcast {
  final eventsBroadcast = <Nip01Event>[];
  final eventsDeleted = <Nip01Event>[];

  @override
  NdkBroadcastResponse broadcast({
    required Nip01Event nostrEvent,
    Iterable<String>? specificRelays,
    EventSigner? customSigner,
    double? considerDonePercent,
    Duration? timeout,
    bool? saveToCache,
  }) {
    eventsBroadcast.add(nostrEvent);
    return _ok(nostrEvent);
  }

  @override
  NdkBroadcastResponse broadcastDeletion({
    Nip01Event? event,
    List<Nip01Event>? events,
    Nip01Event? eventAndAllVersions,
    List<Nip01Event>? eventsAndAllVersions,
    String? eventId,
    List<String>? eventIds,
    Iterable<String>? customRelays,
    EventSigner? customSigner,
    String reason = "delete",
  }) {
    if (eventAndAllVersions != null) eventsDeleted.add(eventAndAllVersions);
    return _ok(eventAndAllVersions ?? events?.first ?? event!);
  }

  NdkBroadcastResponse _ok(Nip01Event event) => NdkBroadcastResponse(
    publishEvent: event,
    broadcastDoneStream: const Stream.empty(),
    broadcastDoneFuture: Future.value([]),
  );

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('Unexpected broadcast call: ${invocation.memberName}');
}

class _StubNdk implements Ndk {
  @override
  final _FakeAccounts accounts;
  @override
  final _StubRequests requests;
  @override
  final _FakeBroadcast broadcast;

  _StubNdk(this.accounts, this.requests, this.broadcast);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('Unexpected NDK call: ${invocation.memberName}');
}

Future<void> _pump(WidgetTester tester, _StubNdk ndk) async {
  tester.view.physicalSize = const Size(1200, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);

  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SingleChildScrollView(
          child: NMotdAdmin(ndkFlutter: NdkFlutter(ndk: ndk), authorPubkey: _author),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('creates a kind 30078 event with message, url and version',
      (tester) async {
    final signer = _FakeSigner(_author);
    final ndk = _StubNdk(
      _FakeAccounts(signer),
      _StubRequests(const []),
      _FakeBroadcast(),
    );
    await _pump(tester, ndk);

    await tester.enterText(find.byType(TextField).first, 'Welcome!');
    await tester.enterText(
      find.byType(TextField).at(1),
      'https://example.com',
    );
    await tester.enterText(find.byType(TextField).at(2), '1.2.0');
    await tester.tap(find.text('Publish'));
    await tester.pumpAndSettle();

    expect(ndk.broadcast.eventsBroadcast, hasLength(1));
    final event = ndk.broadcast.eventsBroadcast.single;
    expect(event.kind, MotdData.kKind);
    expect(event.pubKey, _author);
    expect(event.content, 'Welcome!');
    expect(event.getTags('d').first, 'motd');
    expect(event.getTags('url').first, 'https://example.com');
    expect(event.getTags('version').first, '1.2.0');
  });

  testWidgets('pre-fills version field from appVersion', (tester) async {
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);

    final signer = _FakeSigner(_author);
    final ndk = _StubNdk(
      _FakeAccounts(signer),
      _StubRequests(const []),
      _FakeBroadcast(),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NMotdAdmin(
            ndkFlutter: NdkFlutter(ndk: ndk),
            authorPubkey: _author,
            appVersion: '9.9.9',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('9.9.9'), findsOneWidget);
  });

  testWidgets('loaded event fills fields and delete removes it',
      (tester) async {
    final signer = _FakeSigner(_author);
    final existing = Nip01Event(
      id: 'existing',
      pubKey: _author,
      kind: MotdData.kKind,
      tags: const [
        ['d', 'motd'],
        ['url', 'https://example.com'],
        ['version', '2.0.0'],
      ],
      content: 'Old message',
      createdAt: 100,
    );
    final ndk = _StubNdk(
      _FakeAccounts(signer),
      _StubRequests([existing]),
      _FakeBroadcast(),
    );
    await _pump(tester, ndk);

    expect(find.text('Old message'), findsOneWidget);
    expect(find.text('https://example.com'), findsOneWidget);
    expect(find.text('2.0.0'), findsOneWidget);
    expect(find.text('Update'), findsOneWidget);

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(ndk.broadcast.eventsDeleted, hasLength(1));
    expect(ndk.broadcast.eventsDeleted.single.id, 'existing');
    expect(find.text('Old message'), findsNothing);
    expect(find.text('Delete'), findsNothing);
  });

  testWidgets('blocks publishing when not logged in as the author',
      (tester) async {
    final signer = _FakeSigner('someoneElse');
    final ndk = _StubNdk(
      _FakeAccounts(signer),
      _StubRequests(const []),
      _FakeBroadcast(),
    );
    await _pump(tester, ndk);

    await tester.enterText(find.byType(TextField).first, 'Not allowed');
    await tester.tap(find.text('Publish'));
    await tester.pumpAndSettle();

    expect(ndk.broadcast.eventsBroadcast, isEmpty);
    expect(find.text('You must be logged in as the message author to manage it.'), findsOneWidget);
  });
}