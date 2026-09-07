/// Optional Nostr Wallet Connect extension specifications.
///
/// The identifiers correspond to specification filenames in
/// https://github.com/nostr-wallet-connect/nwc.
enum NwcExtension {
  notifications('02'),
  holdInvoices('03'),
  keysend('04'),
  transactionHistory('05'),
  metadata('06'),
  deepLinks('07'),
  bip321('321');

  /// Identifier advertised by NWC wallet services.
  final String identifier;

  const NwcExtension(this.identifier);

  /// Returns the extension matching [identifier], or `null` when it is not
  /// known by this version of NDK.
  static NwcExtension? fromIdentifier(String identifier) {
    final normalizedIdentifier = identifier.trim();
    for (final extension in NwcExtension.values) {
      if (extension.identifier == normalizedIdentifier) {
        return extension;
      }
    }
    return null;
  }

  /// Parses identifiers from NIP-47 fields.
  ///
  /// Each input may be a single identifier, as used by `get_info`, or a
  /// space-separated list, as used by the kind 13194 info event.
  static Set<NwcExtension> fromIdentifiers(Iterable<String> identifiers) {
    final extensions = <NwcExtension>{};
    for (final value in identifiers) {
      for (final identifier in value.split(RegExp(r'\s+'))) {
        final extension = fromIdentifier(identifier);
        if (extension != null) {
          extensions.add(extension);
        }
      }
    }
    return extensions;
  }
}
