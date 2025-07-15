class WalletCashuEventContent {
  final String privKey;
  final Set<String> mints;

  WalletCashuEventContent({
    required this.privKey,
    required this.mints,
  });

  /// converts to plain list data from WalletCashuEvent
  List<List<String>> toCashuEventContent() {
    final jsonList = [
      ["privkey", privKey]
    ];

    jsonList.addAll(mints.map((mint) => ["mint", mint]));

    return jsonList;
  }

  /// extracts data from plain lists
  factory WalletCashuEventContent.fromCashuEventContent(
    List<List<String>> jsonList,
  ) {
    String? privKey;
    final Set<String> mints = {};

    for (final item in jsonList) {
      if (item.length == 2) {
        final key = item[0];
        final value = item[1];

        if (key == 'privkey') {
          privKey = value;
        } else if (key == 'mint') {
          mints.add(value);
        }
      }
    }

    if (privKey == null) {
      throw ArgumentError('Input list does not contain a private key.');
    }

    return WalletCashuEventContent(privKey: privKey, mints: mints);
  }
}
