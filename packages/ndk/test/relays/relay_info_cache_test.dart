import 'dart:async';

import 'package:ndk/domain_layer/entities/global_state.dart';
import 'package:ndk/domain_layer/entities/relay_info.dart';
import 'package:ndk/domain_layer/repositories/nostr_transport.dart';
import 'package:ndk/domain_layer/repositories/relay_info_repo.dart';
import 'package:ndk/domain_layer/usecases/relay_manager.dart';
import 'package:test/test.dart';

class _Repo implements RelayInfoRepo {
  final requested = <String>[];
  Completer<RelayInfo?> next = Completer();

  @override
  Future<RelayInfo?> getRelayInfo(String url) {
    requested.add(url);
    return next.future;
  }
}

class _NoTransport implements NostrTransportFactory {
  @override
  NostrTransport call(
    String url, {
    Function? onReconnect,
    Function(int?, Object?, String?)? onDisconnect,
  }) => throw UnimplementedError();
}

void main() {
  const url = 'wss://relay.example';
  final info = RelayInfo.fromJson({'name': 'Example'}, 'https://relay.example');
  late _Repo repo;
  late RelayManager manager;

  setUp(() {
    repo = _Repo();
    manager = RelayManager(
      globalState: GlobalState(),
      nostrTransportFactory: _NoTransport(),
      bootstrapRelays: [],
      relayInfoRepo: repo,
    );
  });

  test('concurrent and later calls share one fetch per relay', () async {
    final first = manager.getRelayInfo(url);
    final second = manager.getRelayInfo('$url/');
    repo.next.complete(info);

    expect(await first, same(info));
    expect(await second, same(info));
    expect(await manager.getRelayInfo(url), same(info));
    expect(repo.requested, [url]);
  });

  test('a failed fetch is retried on the next call', () async {
    repo.next.complete(null);
    expect(await manager.getRelayInfo(url), isNull);

    repo.next = Completer()..complete(info);
    expect(await manager.getRelayInfo(url), same(info));
    expect(repo.requested, [url, url]);
  });

  test('a throwing repo is retried on the next call', () async {
    repo.next.completeError(StateError('offline'));
    await expectLater(manager.getRelayInfo(url), throwsStateError);

    repo.next = Completer()..complete(info);
    expect(await manager.getRelayInfo(url), same(info));
  });
}
