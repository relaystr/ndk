// ignore_for_file: avoid_print

import 'dart:io';

import 'package:ndk/ndk.dart';

void main() async {
  final ndk = Ndk.emptyBootstrapRelaysConfig();

  // Provide an NWC connection URI. Omit AMOUNT_MSAT for a variable amount.
  final nwcUri = Platform.environment['NWC_URI']!;
  final amountMsat = int.tryParse(
    Platform.environment['AMOUNT_MSAT'] ?? '',
  );

  final connection = await ndk.nwc.connect(nwcUri);
  final response = await ndk.nwc.receive(
    connection,
    amountMsat: amountMsat,
    description: Platform.environment['DESCRIPTION'],
  );

  // For now, use a wallet whose `receive` implementation returns a BOLT11
  // `lightning` instruction in this BIP-321 URI.
  print('BIP-321 URI: ${response.bip321}');
  print('transaction id: ${response.transactionId}');

  await ndk.destroy();
}
