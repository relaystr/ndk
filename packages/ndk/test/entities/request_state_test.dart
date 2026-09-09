import 'package:ndk/domain_layer/entities/request_state.dart';
import 'package:ndk/ndk.dart';
import 'package:test/test.dart';

RequestState _query() => RequestState(
      NdkRequest.query(
        'a-query',
        filters: [
          Filter(kinds: [Nip01Event.kTextNodeKind])
        ],
        timeoutDuration: const Duration(seconds: 5),
      ),
    );

void main() {
  group('RequestState.didAllRequestsFinish', () {
    test('a request that reached no relay is finished', () {
      expect(_query().didAllRequestsFinish, isTrue);
    });

    test('waits for every relay it was sent to', () {
      final state = _query();
      final fast = RelayConnectionKey.anonymous('wss://fast.example.com');
      final slow = RelayConnectionKey.anonymous('wss://slow.example.com');
      state.addRequest(fast, state.request.filters);
      state.addRequest(slow, state.request.filters);

      state.requests[fast]!.receivedEOSE = true;
      expect(state.didAllRequestsFinish, isFalse);

      state.requests[slow]!.receivedEOSE = true;
      expect(state.didAllRequestsFinish, isTrue);
    });

    test('waits for a relay whose connection is still being worked out', () {
      final state = _query();
      final fast = RelayConnectionKey.anonymous('wss://fast.example.com');

      // a second send path is resolving which connection to use, so it has no
      // entry yet. The relay that answered must not look like the only one
      state.pendingConnections++;
      state.addRequest(fast, state.request.filters);
      state.requests[fast]!.receivedEOSE = true;

      expect(state.didAllRequestsFinish, isFalse);

      state.pendingConnections--;
      expect(state.didAllRequestsFinish, isTrue);
    });

    test('a relay that is authenticating is not finished', () {
      final state = _query();
      final key = RelayConnectionKey.anonymous('wss://relay.example.com');
      state.addRequest(key, state.request.filters);

      state.requests[key]!.receivedClosed = true;
      state.requests[key]!.retryingAuth = true;
      expect(state.didAllRequestsFinish, isFalse);

      state.requests[key]!.retryingAuth = false;
      expect(state.didAllRequestsFinish, isTrue);
    });
  });
}
