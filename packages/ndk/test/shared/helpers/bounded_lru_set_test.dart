import 'package:ndk/shared/helpers/bounded_lru_set.dart';
import 'package:test/test.dart';

void main() {
  test('evicts the least recently used value at capacity', () {
    final values = BoundedLruSet<String>(maxSize: 2);

    expect(values.add('first'), isTrue);
    expect(values.add('second'), isTrue);
    expect(values.add('first'), isFalse);

    expect(values.add('third'), isTrue);
    expect(values.contains('first'), isTrue);
    expect(values.contains('second'), isFalse);
    expect(values.contains('third'), isTrue);

    expect(
      values.add('second'),
      isTrue,
      reason: 'an evicted id must trigger insert-only persistence again',
    );
  });
}
