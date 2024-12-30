// ignore_for_file: avoid_print

import 'dart:io';

import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/bip340.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';

void main() async {
  // We use an empty bootstrap relay list,
  // since NWC will provide the relay we connect to so we don't need default relays
  final ndk = Ndk(NdkConfig(
      eventVerifier: Bip340EventVerifier(),
      cache: MemCacheManager(),
      logLevel: Logger.logLevels.trace));

  // You need an NWC_URI env var or to replace with your NWC uri connection
  final nwcUri = Platform.environment['NWC_URI']!;
  final connection = await ndk.nwc.connect(nwcUri);
  KeyPair key = Bip340.generatePrivateKey();
  final amount = 21;
  final lnurl = "opensats@vlt.ge";
  final comment = "enjoy this zap from NDK";

  ZapResponse response = await ndk.zaps.zap(
      nwcConnection: connection,
      lnurl: lnurl,
      comment: comment,
      amountSats: amount,
      fetchZapReceipt: true,
      signer: Bip340EventSigner(
          privateKey: key.privateKey, publicKey: key.publicKey),
      relays: ["wss://relay.damus.io"],
      pubKey:
          "787338757fc25d65cd929394d5e7713cf43638e8d259e8dcf5c73b834eb851f2",
      eventId:
          "906a0c5920b59e5754d0df5164bfea2a8d48ce5d73beaa1e854b3e6725e3288a");

  if (response.payInvoiceResponse != null &&
      response.payInvoiceResponse!.preimage.isNotEmpty) {
    print(
        "Payed $amount to $lnurl, preimage = ${response.payInvoiceResponse!.preimage}");

    print("Waiting for Zap Receipt...");
    ZapReceipt? receipt = await response.zapReceipt;
    if (receipt != null) {
      print("Receipt : $receipt");
    } else {
      print("No Receipt");
    }
  }

  await ndk.destroy();
}
