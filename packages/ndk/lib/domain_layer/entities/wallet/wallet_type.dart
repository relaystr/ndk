enum WalletType {
  // ignore: constant_identifier_names
  NWC('nwc'),
  // ignore: constant_identifier_names
  CASHU('cashu');

  final String value;

  const WalletType(this.value);

  factory WalletType.fromValue(String value) {
    return WalletType.values.firstWhere(
      (kind) => kind.value == value,
      orElse: () => throw ArgumentError('Invalid event kind value: $value'),
    );
  }

  @override
  String toString() => value;
}
