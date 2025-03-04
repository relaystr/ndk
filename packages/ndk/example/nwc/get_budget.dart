// ignore_for_file: avoid_print

import 'dart:io';

import 'package:ndk/domain_layer/usecases/nwc/responses/get_budget_response.dart';
import 'package:ndk/ndk.dart';
import 'package:logger/logger.dart' as lib_logger;

void main() async {
  // We use an empty bootstrap relay list,
  // since NWC will provide the relay we connect to so we don't need default relays
  final ndk = Ndk.emptyBootstrapRelaysConfig();

  Logger.setLogLevel(lib_logger.Level.warning);

  // You need an NWC_URI env var or to replace with your NWC uri connection
  final nwcUri = Platform.environment['NWC_URI']!;
  final connection = await ndk.nwc.connect(nwcUri);

  GetBudgetResponse response = await ndk.nwc.getBudget(connection);

  print("Used budget: ${response.userBudgetSats} sats");
  print("Total budget: ${response.totalBudgetSats} sats");
  if (response.renewsAt != null) {
    final renewsAtDate =
        DateTime.fromMillisecondsSinceEpoch(response.renewsAt! * 1000);
    final formattedDate =
        "${renewsAtDate.year}-${renewsAtDate.month.toString().padLeft(2, '0')}-${renewsAtDate.day.toString().padLeft(2, '0')} "
        "${renewsAtDate.hour.toString().padLeft(2, '0')}:${renewsAtDate.minute.toString().padLeft(2, '0')}:${renewsAtDate.second.toString().padLeft(2, '0')}";
    print("Renews at: $formattedDate");
  }
  print("Renewal period: ${response.renewalPeriod.plaintext}");

  await ndk.destroy();
}
