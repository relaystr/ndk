// ignore_for_file: camel_case_types

import '../consts/budget_renewal_period.dart';
import 'nwc_response.dart';

/// Represents the result of a 'get_budget' response.
class GetBudgetResponse extends NwcResponse {

  final int usedBudget; // msats
  final int totalBudget; // msats
  final int? renewsAt; // timestamp
  final BudgetRenewalPeriod renewalPeriod;

  int get userBudgetSats => usedBudget ~/ 1000;

  int get totalBudgetSats => totalBudget ~/ 1000;

  GetBudgetResponse({
    required super.resultType,
    required this.usedBudget,
    required this.totalBudget,
    this.renewsAt,
    required this.renewalPeriod
  });

  factory GetBudgetResponse.deserialize(Map<String, dynamic> input) {
    if (!input.containsKey('result')) {
      throw Exception('Invalid input');
    }

    Map<String, dynamic> result = input['result'] as Map<String, dynamic>;

    return GetBudgetResponse(
      resultType: input['result_type'] as String,
      usedBudget: (result['used_budget'] as num?)?.toInt() ?? 0,
      totalBudget: (result['total_budget'] as num?)?.toInt() ?? 0,
      renewsAt: result['renews_at'],
      renewalPeriod: BudgetRenewalPeriod.fromPlaintext(
          result['renewal_period'] as String? ?? 'none'),
    );
  }
}
