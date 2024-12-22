// ignore_for_file: avoid_print

import 'package:ndk/ndk.dart';

void main() async {
  final ndk = Ndk.defaultConfig();

  print("fetching zap receipts for single event ");
  final receipts = await ndk.zaps.fetchZappedReceipts(
      pubKey:
          "787338757fc25d65cd929394d5e7713cf43638e8d259e8dcf5c73b834eb851f2",
      eventId:
          "906a0c5920b59e5754d0df5164bfea2a8d48ce5d73beaa1e854b3e6725e3288a");

  // Sort eventReceipts by amountSats in descending order
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
