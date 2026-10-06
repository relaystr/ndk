import 'package:ndk/domain_layer/entities/global_state.dart';
import 'package:ndk/domain_layer/entities/request_state.dart';
import 'package:ndk/domain_layer/usecases/requests/concurrency_check.dart';
import 'package:ndk/ndk.dart';
import 'package:test/test.dart';

void main() {
  RequestState query(String id, List<Filter> filters) {
    return RequestState(
      NdkRequest.query(id, timeoutDuration: null, filters: filters),
    );
  }

  group('request hashing', () {
    late ConcurrencyCheck concurrencyCheck;

    setUp(() {
      concurrencyCheck = ConcurrencyCheck(GlobalState());
    });

    test('dedups filters whose lists differ only in order', () {
      final first = query('1', [
        Filter(authors: ['a', 'b'], kinds: [1, 7]),
      ]);
      final second = query('2', [
        Filter(authors: ['b', 'a'], kinds: [7, 1]),
      ]);

      expect(concurrencyCheck.check(first), false);
      expect(concurrencyCheck.check(second), true);
    });

    test('dedups tags whose values or keys differ only in order', () {
      final first = query('1', [
        Filter(pTags: ['a', 'b'], eTags: ['c']),
      ]);
      final second = query('2', [
        Filter(eTags: ['c'], pTags: ['b', 'a']),
      ]);

      expect(concurrencyCheck.check(first), false);
      expect(concurrencyCheck.check(second), true);
    });

    test('dedups requests whose filters differ only in order', () {
      final first = query('1', [
        Filter(authors: ['a']),
        Filter(authors: ['b']),
      ]);
      final second = query('2', [
        Filter(authors: ['b']),
        Filter(authors: ['a']),
      ]);

      expect(concurrencyCheck.check(first), false);
      expect(concurrencyCheck.check(second), true);
    });

    test('keeps different filters apart', () {
      final first = query('1', [
        Filter(authors: ['a', 'b']),
      ]);
      final second = query('2', [
        Filter(authors: ['a', 'c']),
      ]);

      expect(concurrencyCheck.check(first), false);
      expect(concurrencyCheck.check(second), false);
    });
  });
}
