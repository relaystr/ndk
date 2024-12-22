// ignore_for_file: avoid_print

import 'package:ndk/ndk.dart';

void main() async {
  final ndk = Ndk.defaultConfig();

  print("fetching zap receipts for single event ");
  final receipts = await ndk.zaps.fetchZappedReceipts(
      pubKey:
          "30782a8323b7c98b172c5a2af7206bb8283c655be6ddce11133611a03d5f1177",
      eventId:
          "d7bc29fa3c55ac525a3d5f2021211edb672b58565225dec423479a0875feea9d");

  // Sort eventReceipts by amountSats in descending order
  receipts
      .sort((a, b) => (b.amountSats ?? 0).compareTo(a.amountSats ?? 0));

  // Sort profileReceipts by amountSats in descending order
  receipts
      .sort((a, b) => (b.amountSats ?? 0).compareTo(a.amountSats ?? 0));

  int eventSum = 0;
  for (var receipt in receipts) {
    String? sender;
    if (receipt.sender!=null) {
      Metadata? metadata = await ndk.metadata.loadMetadata(receipt.sender!);
      sender = metadata?.name;
    }
    print("${sender!=null?"from ${sender} ":""} ${receipt.amountSats} sats ${receipt.comment}");
    eventSum += receipt.amountSats ?? 0;
  }
  print("${receipts.length} receipts, total of $eventSum sats");

  await ndk.destroy();
}
