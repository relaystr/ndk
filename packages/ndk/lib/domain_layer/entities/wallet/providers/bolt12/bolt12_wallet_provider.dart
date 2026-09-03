import 'dart:async';
import 'dart:convert';

import 'package:dart_bip353/dart_bip353.dart';
import 'package:dart_bolt12_decoder/dart_bolt12_decoder.dart';

import 'package:ndk/domain_layer/usecases/nwc/responses/pay_invoice_response.dart';
import 'package:ndk/domain_layer/usecases/nwc/responses/pay_response.dart';
import 'package:ndk/domain_layer/usecases/nwc/responses/receive_response.dart';
import '../../wallet.dart';
import '../../wallet_balance.dart';
import '../../wallet_provider.dart';
import '../../wallet_transaction.dart';
import '../../wallet_type.dart';
import 'bolt12_wallet.dart';

typedef Bip353OfferResolver = Future<String?> Function(String address);

class Bolt12ResolvedOffer {
  final String offer;
  final String source;
  final String? bip353Address;
  final Map<String, dynamic> decoded;

  const Bolt12ResolvedOffer({
    required this.offer,
    required this.source,
    required this.decoded,
    this.bip353Address,
  });

  Map<String, dynamic> toMetadata() => {
        'offer': offer,
        'source': source,
        'bip353Address': bip353Address,
        'description': _nonEmptyString(decoded['offer_description']),
        'nodeId': _nonEmptyString(decoded['offer_node_id']),
        'offerId': _nonEmptyString(decoded['offer_id']),
        'amount': _nonEmptyString(decoded['offer_amount']),
        'issuer': _nonEmptyString(decoded['offer_issuer']),
        'currency': _nonEmptyString(decoded['offer_currency']),
        'expiresAt': _intValue(decoded['offer_absolute_expiry']),
        'quantityMax': _intValue(decoded['offer_quantity_max']),
        'hasBlindedPaths': decoded['has_blinded_paths'] == true ||
            _hasValues(decoded['offer_paths']),
      };

  static String? _nonEmptyString(Object? value) {
    final normalized = value?.toString().trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }

  static int? _intValue(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  static bool _hasValues(Object? value) {
    if (value is Iterable) return value.isNotEmpty;
    return value != null;
  }
}

/// Provider for receive-only BOLT12 offer wallets.
class Bolt12WalletProvider implements WalletProvider {
  const Bolt12WalletProvider();

  @override
  WalletType get type => WalletType.BOLT12;

  /// Whether [input] has the shape of a supported BOLT12 input.
  ///
  /// Full offer validation and BIP353 DNS resolution happen in [resolveInput].
  static bool isSupportedInput(String input) {
    final value = input.trim();
    if (value.isEmpty) return false;
    if (_directOffer(value) != null) return true;
    return _bip353Address(value) != null;
  }

  /// Resolves a direct offer, a BIP321 `bitcoin:?lno=...` URI, or a BIP353
  /// address into a validated canonical BOLT12 offer.
  static Future<Bolt12ResolvedOffer> resolveInput(
    String input, {
    Bip353OfferResolver? bip353Resolver,
  }) async {
    final source = input.trim();
    if (source.isEmpty) {
      throw const FormatException('BOLT12 offer or BIP353 address is required');
    }

    final direct = _directOffer(source);
    if (direct != null) {
      return _validate(offer: direct, source: source);
    }

    final address = _bip353Address(source);
    if (address == null) {
      throw const FormatException(
        'Expected an lno offer, bitcoin:?lno=... URI, or BIP353 address',
      );
    }

    final resolver = bip353Resolver ?? _resolveBip353;
    final resolvedOffer = await resolver(address);
    if (resolvedOffer == null || resolvedOffer.trim().isEmpty) {
      throw FormatException(
        'BIP353 address $address does not publish a BOLT12 offer',
      );
    }

    return _validate(
      offer: resolvedOffer,
      source: source,
      bip353Address: address,
    );
  }

  static Future<String?> _resolveBip353(String address) async {
    final response = await Bip353.getAdressResolve(address);
    return response.offer;
  }

  static Bolt12ResolvedOffer _validate({
    required String offer,
    required String source,
    String? bip353Address,
  }) {
    final envelope = _Bolt12OfferEnvelope.parse(offer);
    final canonicalOffer = envelope.canonicalOffer;

    // dart_bolt12_decoder 0.8.0 predates the current blinded-path encoding
    // and also requires description + issuer id, which modern offers may omit.
    // Use it for the offer shapes it understands and retain strict structural
    // validation for current-spec offers.
    Map<String, dynamic> decoded = envelope.details;
    if (envelope.isSupportedByDetailDecoder) {
      final packageDecoded = Bolt12Decoder.decode(canonicalOffer);
      if (packageDecoded != null &&
          packageDecoded['type'] == 'offer' &&
          packageDecoded['valid'] == true) {
        decoded = {...decoded, ...packageDecoded};
      }
    }

    return Bolt12ResolvedOffer(
      offer: canonicalOffer,
      source: source,
      bip353Address: bip353Address,
      decoded: Map.unmodifiable(decoded),
    );
  }

  static String? _directOffer(String input) {
    final value = input.trim();
    if (value.toLowerCase().startsWith('lno1')) return value;

    Uri uri;
    try {
      final normalizedValue = value.toLowerCase().startsWith('bitcoin?')
          ? 'bitcoin:${value.substring('bitcoin'.length)}'
          : value;
      uri = Uri.parse(normalizedValue);
    } on FormatException {
      return null;
    }
    if (uri.scheme.toLowerCase() != 'bitcoin') return null;

    for (final entry in uri.queryParameters.entries) {
      if (entry.key.toLowerCase() == 'lno' && entry.value.isNotEmpty) {
        return entry.value;
      }
    }
    return null;
  }

  static String? _bip353Address(String input) {
    var value = input.trim();
    if (value.startsWith('₿')) value = value.substring(1);
    final parts = value.split('@');
    if (parts.length != 2 ||
        parts[0].isEmpty ||
        parts[1].isEmpty ||
        value.contains(RegExp(r'\s'))) {
      return null;
    }
    return value;
  }

  @override
  Wallet createWallet({
    required String id,
    required String name,
    required Set<String> supportedUnits,
    required Map<String, dynamic> metadata,
  }) {
    final offer = metadata['offer'] as String?;
    if (offer == null || offer.isEmpty) {
      throw ArgumentError(
        'Bolt12Wallet requires resolved metadata from resolveInput()',
      );
    }

    final validated = _validate(
      offer: offer,
      source: metadata['source'] as String? ?? offer,
      bip353Address: metadata['bip353Address'] as String?,
    );
    final resolvedMetadata = {
      ...metadata,
      ...validated.toMetadata(),
    };

    return Bolt12Wallet(
      id: id,
      name: name,
      supportedUnits: supportedUnits,
      offer: validated.offer,
      source: validated.source,
      bip353Address: validated.bip353Address,
      description: resolvedMetadata['description'] as String?,
      nodeId: resolvedMetadata['nodeId'] as String?,
      offerId: resolvedMetadata['offerId'] as String?,
      amount: resolvedMetadata['amount']?.toString(),
      issuer: resolvedMetadata['issuer'] as String?,
      currency: resolvedMetadata['currency'] as String?,
      expiresAt: Bolt12ResolvedOffer._intValue(
        resolvedMetadata['expiresAt'],
      ),
      quantityMax: Bolt12ResolvedOffer._intValue(
        resolvedMetadata['quantityMax'],
      ),
      hasBlindedPaths: resolvedMetadata['hasBlindedPaths'] == true,
      metadata: resolvedMetadata,
    );
  }

  @override
  Future<Wallet?> initialize(Wallet wallet) async {
    final bolt12Wallet = wallet as Bolt12Wallet;
    _validate(offer: bolt12Wallet.offer, source: bolt12Wallet.source);
    return null;
  }

  @override
  Future<void> removeWallet(Wallet wallet) async {}

  @override
  Stream<List<WalletBalance>> getBalances(Wallet wallet) => Stream.value([]);

  @override
  Stream<List<WalletTransaction>> getPendingTransactions(Wallet wallet) =>
      Stream.value([]);

  @override
  Stream<List<WalletTransaction>> getRecentTransactions(Wallet wallet) =>
      Stream.value([]);

  @override
  Future<PayInvoiceResponse> send(
    Wallet wallet,
    String invoice, {
    Duration? timeout,
  }) {
    throw UnsupportedError(
      'BOLT12 wallet is receive-only and cannot pay invoices',
    );
  }

  @override
  Future<String> receive(Wallet wallet, int amountSats) async =>
      (wallet as Bolt12Wallet).offer;

  @override
  Future<PayResponse> payBip321(
    Wallet wallet, {
    required String payment,
    int? amountMsat,
    String? payerNote,
    Map<String, dynamic>? metadata,
    Duration? timeout,
  }) {
    throw UnsupportedError(
      'BOLT12 wallet is receive-only and cannot pay BIP-321 instructions',
    );
  }

  @override
  Future<ReceiveResponse> receiveBip321(
    Wallet wallet, {
    int? amountMsat,
    String? description,
    Map<String, dynamic>? metadata,
    Duration? timeout,
  }) async {
    if (description?.isNotEmpty == true) {
      throw UnsupportedError(
        'A BOLT12 offer controls its own payment description',
      );
    }
    final offer = (wallet as Bolt12Wallet).offer;
    return ReceiveResponse(
      resultType: 'receive',
      bip321: Uri(
        scheme: 'bitcoin',
        queryParameters: {'lno': offer},
      ).toString(),
    );
  }

  @override
  Stream<List<Wallet>> get discoveredWallets => Stream.value([]);
}

class _Bolt12OfferEnvelope {
  static const _alphabet = 'qpzry9x8gf2tvdw0s3jn54khce6mua7l';
  static const _knownOfferTypes = <int>{2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22};

  final String canonicalOffer;
  final Map<int, List<int>> fields;
  final Map<String, dynamic> details;

  const _Bolt12OfferEnvelope({
    required this.canonicalOffer,
    required this.fields,
    required this.details,
  });

  bool get isSupportedByDetailDecoder =>
      !fields.containsKey(16) &&
      fields.containsKey(10) &&
      fields.containsKey(22);

  static _Bolt12OfferEnvelope parse(String input) {
    final withoutContinuations = input.trim().replaceAll(
          RegExp(r'\+\s*'),
          '',
        );
    final letters = withoutContinuations.replaceAll(RegExp('[^A-Za-z]'), '');
    if (letters != letters.toLowerCase() && letters != letters.toUpperCase()) {
      throw const FormatException(
        'BOLT12 strings must not mix uppercase and lowercase',
      );
    }

    final canonical = withoutContinuations.toLowerCase();
    if (!canonical.startsWith('lno1')) {
      throw const FormatException('BOLT12 offers must start with lno1');
    }
    final encoded = canonical.substring(4);
    if (encoded.isEmpty) {
      throw const FormatException('BOLT12 offer has no encoded data');
    }

    final values = <int>[];
    for (final codeUnit in encoded.codeUnits) {
      final value = _alphabet.indexOf(String.fromCharCode(codeUnit));
      if (value < 0) {
        throw const FormatException('Invalid character in BOLT12 offer');
      }
      values.add(value);
    }

    final bytes = _convertFiveToEightBits(values);
    final fields = <int, List<int>>{};
    var offset = 0;
    var previousType = -1;
    while (offset < bytes.length) {
      final typeResult = _readBigSize(bytes, offset);
      final type = typeResult.value;
      offset = typeResult.nextOffset;
      final lengthResult = _readBigSize(bytes, offset);
      final length = lengthResult.value;
      offset = lengthResult.nextOffset;

      if (type <= previousType) {
        throw const FormatException(
          'BOLT12 TLV fields must be unique and ordered',
        );
      }
      if (!((type >= 1 && type <= 79) ||
          (type >= 1000000000 && type <= 1999999999))) {
        throw FormatException('Invalid BOLT12 offer field type $type');
      }
      if (type <= 79 && type.isEven && !_knownOfferTypes.contains(type)) {
        throw FormatException('Unknown required BOLT12 offer field $type');
      }
      if (length < 0 || length > bytes.length - offset) {
        throw const FormatException('Truncated BOLT12 offer field');
      }

      fields[type] = bytes.sublist(offset, offset + length);
      offset += length;
      previousType = type;
    }

    _validateOfferFields(fields);
    return _Bolt12OfferEnvelope(
      canonicalOffer: canonical,
      fields: Map.unmodifiable(fields),
      details: Map.unmodifiable(_basicDetails(fields)),
    );
  }

  static void _validateOfferFields(Map<int, List<int>> fields) {
    final paths = fields[16];
    final issuerId = fields[22];
    if ((paths == null || paths.isEmpty) && issuerId == null) {
      throw const FormatException(
        'BOLT12 offer requires offer_paths or offer_issuer_id',
      );
    }
    if (issuerId != null && issuerId.length != 33) {
      throw const FormatException('Invalid BOLT12 offer_issuer_id');
    }

    final chains = fields[2];
    if (chains != null && (chains.isEmpty || chains.length % 32 != 0)) {
      throw const FormatException('Invalid BOLT12 offer_chains');
    }
    final currency = fields[6];
    if (currency != null && currency.length != 3) {
      throw const FormatException('Invalid BOLT12 offer_currency');
    }

    final amountBytes = fields[8];
    if (amountBytes != null) {
      _readTu64(amountBytes);
      if (!fields.containsKey(10)) {
        throw const FormatException(
          'BOLT12 offer_amount requires offer_description',
        );
      }
    } else if (currency != null) {
      throw const FormatException(
        'BOLT12 offer_currency requires offer_amount',
      );
    }

    final expiryBytes = fields[14];
    if (expiryBytes != null) {
      final expiry = _readTu64(expiryBytes);
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      if (expiry < now) {
        throw const FormatException('BOLT12 offer has expired');
      }
    }
  }

  static Map<String, dynamic> _basicDetails(Map<int, List<int>> fields) {
    final details = <String, dynamic>{'type': 'offer', 'valid': true};
    final currency = fields[6];
    if (currency != null) {
      try {
        details['offer_currency'] = utf8.decode(currency);
      } on FormatException {
        throw const FormatException('Invalid UTF-8 in BOLT12 currency');
      }
    }
    final amount = fields[8];
    if (amount != null) details['offer_amount'] = _readTu64(amount).toString();
    final description = fields[10];
    if (description != null) {
      try {
        details['offer_description'] = utf8.decode(description);
      } on FormatException {
        throw const FormatException('Invalid UTF-8 in BOLT12 description');
      }
    }
    final issuer = fields[18];
    if (issuer != null) {
      try {
        details['offer_issuer'] = utf8.decode(issuer);
      } on FormatException {
        throw const FormatException('Invalid UTF-8 in BOLT12 issuer');
      }
    }
    final expiry = fields[14];
    if (expiry != null) {
      details['offer_absolute_expiry'] = _readTu64(expiry);
    }
    final paths = fields[16];
    if (paths != null && paths.isNotEmpty) {
      details['has_blinded_paths'] = true;
    }
    final quantityMax = fields[20];
    if (quantityMax != null) {
      details['offer_quantity_max'] = _readTu64(quantityMax);
    }
    final issuerId = fields[22];
    if (issuerId != null) {
      details['offer_node_id'] =
          issuerId.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
    }
    return details;
  }

  static List<int> _convertFiveToEightBits(List<int> values) {
    const maxAccumulator = (1 << 12) - 1;
    var accumulator = 0;
    var bits = 0;
    final result = <int>[];
    for (final value in values) {
      accumulator = ((accumulator << 5) | value) & maxAccumulator;
      bits += 5;
      while (bits >= 8) {
        bits -= 8;
        result.add((accumulator >> bits) & 0xff);
      }
    }
    if (bits >= 5 || ((accumulator << (8 - bits)) & 0xff) != 0) {
      throw const FormatException('Invalid BOLT12 data padding');
    }
    return result;
  }

  static _BigSizeResult _readBigSize(List<int> bytes, int offset) {
    if (offset >= bytes.length) {
      throw const FormatException('Truncated BOLT12 bigsize');
    }
    final first = bytes[offset++];
    if (first < 0xfd) return _BigSizeResult(first, offset);

    final byteCount = first == 0xfd
        ? 2
        : first == 0xfe
            ? 4
            : 8;
    if (offset + byteCount > bytes.length) {
      throw const FormatException('Truncated BOLT12 bigsize');
    }
    var value = 0;
    for (var index = 0; index < byteCount; index++) {
      value = value * 256 + bytes[offset + index];
      if (value > 1999999999 && byteCount == 8) {
        throw const FormatException('BOLT12 bigsize is too large');
      }
    }
    final minimum = byteCount == 2
        ? 0xfd
        : byteCount == 4
            ? 0x10000
            : 0x100000000;
    if (value < minimum) {
      throw const FormatException('Non-canonical BOLT12 bigsize');
    }
    return _BigSizeResult(value, offset + byteCount);
  }

  static int _readTu64(List<int> bytes) {
    if (bytes.length > 8 || (bytes.isNotEmpty && bytes.first == 0)) {
      throw const FormatException('Invalid BOLT12 truncated integer');
    }
    var value = 0;
    for (final byte in bytes) {
      value = value * 256 + byte;
    }
    return value;
  }
}

class _BigSizeResult {
  final int value;
  final int nextOffset;

  const _BigSizeResult(this.value, this.nextOffset);
}
