import 'nwc_response.dart';

/// Represents the result of a NWC-321 `receive` response.
class ReceiveResponse extends NwcResponse {
  /// BIP-321 URI containing one or more receive instructions.
  final String bip321;

  /// Wallet-scoped transaction identifier, when one was allocated.
  final String? transactionId;

  ReceiveResponse({
    required super.resultType,
    required this.bip321,
    this.transactionId,
  });

  factory ReceiveResponse.deserialize(Map<String, dynamic> input) {
    if (!input.containsKey('result')) {
      throw Exception('Invalid input');
    }

    final result = input['result'] as Map<String, dynamic>;

    return ReceiveResponse(
      resultType: input['result_type'] as String,
      bip321: result['bip321'] as String,
      transactionId: result['transaction_id'] as String?,
    );
  }
}
