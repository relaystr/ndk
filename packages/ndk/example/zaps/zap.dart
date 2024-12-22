// ignore_for_file: avoid_print

import 'dart:io';

import 'package:ndk/config/bootstrap_relays.dart';
import 'package:ndk/domain_layer/usecases/zaps/zap_receipt.dart';
import 'package:ndk/domain_layer/usecases/zaps/zaps.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/bip340.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';

void main() async {
  // We use an empty bootstrap relay list,
  // since NWC will provide the relay we connect to so we don't need default relays
  final ndk = Ndk(NdkConfig(
      eventVerifier: Bip340EventVerifier(),
      cache: MemCacheManager(),
      logLevel: Logger.logLevels.info));

      // You need an NWC_URI env var or to replace with your NWC uri connection
  final nwcUri = Platform.environment['NWC_URI']!;
  final connection = await ndk.nwc.connect(nwcUri);
  KeyPair key = Bip340.generatePrivateKey();
  final amount = 21;
  final lnurl = "fmar@getalby.com";
  final comment = "enjoy this zap from NDK";

  ZapResponse response = await ndk.zaps.zap(
    nwcConnection: connection,
    lnurl: lnurl,
    comment: comment,
    amountSats: amount,
    fetchZapReceipt: true,
    signer: Bip340EventSigner(privateKey: key.privateKey, publicKey: key.publicKey),
    relays: ["wss://relay.damus.io"],
    pubKey: "30782a8323b7c98b172c5a2af7206bb8283c655be6ddce11133611a03d5f1177",
    eventId: "d7bc29fa3c55ac525a3d5f2021211edb672b58565225dec423479a0875feea9d"
  );

  if (response.payInvoiceResponse!=null && response.payInvoiceResponse!.preimage.isNotEmpty) {
    print("Payed $amount to $lnurl, preimage = ${response.payInvoiceResponse!
        .preimage}");

    print("Waiting for Zap Receipt...");
    ZapReceipt? receipt = await response.zapReceipt;
    if (receipt!=null) {
      print("Receipt : $receipt");
    } else {
      print("No Receipt");
    }
  }

  await ndk.destroy();
}
