import 'dart:collection';

/// A fixed-capacity set that evicts the least recently added or touched value.
class BoundedLruSet<T> {
  final int maxSize;
  final LinkedHashSet<T> _values = LinkedHashSet<T>();

  BoundedLruSet({required this.maxSize}) : assert(maxSize >= 0);

  /// Adds or touches [value], returning whether it was not already retained.
  bool add(T value) {
    final existed = _values.remove(value);
    _values.add(value);
    while (_values.length > maxSize) {
      _values.remove(_values.first);
    }
    return !existed;
  }

  bool remove(T value) => _values.remove(value);

  bool contains(T value) => _values.contains(value);
}
