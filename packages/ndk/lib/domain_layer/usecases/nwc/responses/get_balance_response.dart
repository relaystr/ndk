// ignore_for_file: camel_case_types

import 'nwc_response.dart';

/// Represents the result of a 'get_balance' response.
class GetBalanceResponse extends NwcResponse {
  /// The current balance.
  final int balanceMsats;

  int get balanceSats => balanceMsats ~/ 1000;

  /// The maximum amount.
  final int? maxAmount;

  /// The budget renewal information.
  final String? budgetRenewal;

  GetBalanceResponse({
    required super.resultType,
    required this.balanceMsats,
    this.maxAmount,
    this.budgetRenewal,
  });

  factory GetBalanceResponse.deserialize(Map<String, dynamic> input) {
    if (!input.containsKey('result')) {
      throw Exception('Invalid input');
    }

    Map<String, dynamic> result = input['result'] as Map<String, dynamic>;

    return GetBalanceResponse(
      resultType: input['result_type'] as String,
      balanceMsats: result['balance'] as int,
      maxAmount: result['max_amount'],
      budgetRenewal: result['budget_renewal'],
    );
  }
}
