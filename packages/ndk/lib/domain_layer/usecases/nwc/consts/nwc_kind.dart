enum NwcKind {
  INFO(13194),
  REQUEST(23194),
  RESPONSE(23195),
  LEGACY_NOTIFICATION(23196),
  NOTIFICATION(23197);

  final int value;

  const NwcKind(this.value);

  factory NwcKind.fromValue(int value) {
    return NwcKind.values.firstWhere(
      (kind) => kind.value == value,
      orElse: () => throw ArgumentError('Invalid event kind value: $value'),
    );
  }
}
