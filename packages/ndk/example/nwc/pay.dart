// ignore_for_file: avoid_print

import 'dart:io';

import 'package:ndk/ndk.dart';

void main() async {
  final ndk = Ndk.emptyBootstrapRelaysConfig();

  // Provide an NWC connection URI and either a BIP-321 URI or BOLT11 invoice.
  final nwcUri = Platform.environment['NWC_URI']!;
  final bip321 = Platform.environment['BIP321'];
  final invoice = Platform.environment['INVOICE'];
  final amountMsat = int.tryParse(
    Platform.environment['AMOUNT_MSAT'] ?? '',
  );

  final connection = await ndk.nwc.connect(nwcUri);

  // NWC-321 expects a BIP-321 URI. Accept direct BIP-321 input, including
  // BOLT12 `lno` offers, or wrap a BOLT11 invoice in `lightning`.
  final payment = bip321 ?? Bip321.fromBolt11(invoice!);

  final response = await ndk.nwc.pay(
    connection,
    payment: payment,
    // Required only when the BOLT11 invoice has no amount.
    amountMsat: amountMsat,
    payerNote: Platform.environment['PAYER_NOTE'],
  );

  print('transaction id: ${response.transactionId}');
  print('state: ${response.state}');
  print('instruction type: ${response.instructionType}');
  print('amount: ${response.amountMsat} msats');
  print('fees paid: ${response.feesPaid} msats');
  print('preimage: ${response.preimage}');

  await ndk.destroy();
}
