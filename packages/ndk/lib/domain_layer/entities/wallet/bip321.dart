/// Helpers for BIP-321 URIs containing BOLT11 payment instructions.
class Bip321 {
  Bip321._();

  /// Creates a BIP-321 URI containing one BOLT11 `lightning` instruction.
  static String fromBolt11(String invoice) {
    if (!invoice.toLowerCase().startsWith('ln')) {
      throw ArgumentError.value(invoice, 'invoice', 'Must be a BOLT11 invoice');
    }
    return Uri(
      scheme: 'bitcoin',
      queryParameters: {'lightning': invoice},
    ).toString();
  }

  /// Selects the single BOLT11 `lightning` instruction from [payment].
  static String getBolt11(String payment) {
    final Uri uri;
    try {
      uri = Uri.parse(payment);
    } on FormatException {
      throw FormatException('Invalid BIP-321 URI', payment);
    }

    if (uri.scheme.toLowerCase() != 'bitcoin') {
      throw FormatException('BIP-321 URI must use the bitcoin scheme', payment);
    }

    final requiredParameters = uri.queryParametersAll.keys.where(
      (key) => key.startsWith('req-'),
    );
    if (requiredParameters.isNotEmpty) {
      throw UnsupportedError(
        'Unsupported required BIP-321 parameter: '
        '${requiredParameters.first}',
      );
    }

    final instructions = uri.queryParametersAll['lightning'];
    if (instructions == null ||
        instructions.length != 1 ||
        instructions.single.isEmpty) {
      throw const FormatException(
        'BIP-321 URI must contain one lightning instruction',
      );
    }

    final invoice = instructions.single;
    if (!invoice.toLowerCase().startsWith('ln')) {
      throw const FormatException('Invalid BOLT11 lightning instruction');
    }
    return invoice;
  }

  /// Returns the BOLT11 amount in millisatoshis, or null when amountless.
  static int? getBolt11AmountMsat(String invoice) {
    final separator = invoice.toLowerCase().lastIndexOf('1');
    if (separator < 0) {
      throw const FormatException('Invalid BOLT11 invoice');
    }

    final hrp = invoice.toLowerCase().substring(0, separator);
    final match = RegExp(
      r'^ln(?:bcrt|bc|tb|sb)([0-9]*)([munp]?)$',
    ).firstMatch(hrp);
    if (match == null) {
      throw const FormatException('Invalid BOLT11 invoice prefix');
    }

    final digits = match.group(1)!;
    if (digits.isEmpty) return null;

    final amount = int.parse(digits);
    return switch (match.group(2)!) {
      '' => amount * 100000000000,
      'm' => amount * 100000000,
      'u' => amount * 100000,
      'n' => amount * 100,
      'p' when amount % 10 == 0 => amount ~/ 10,
      'p' => throw const FormatException(
          'BOLT11 pico-bitcoin amount is not a whole millisatoshi',
        ),
      _ => throw const FormatException('Invalid BOLT11 amount multiplier'),
    };
  }
}
