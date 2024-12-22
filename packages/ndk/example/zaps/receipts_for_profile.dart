// ignore_for_file: avoid_print

import 'package:ndk/ndk.dart';

void main() async {
  final ndk = Ndk.defaultConfig();

  print("fetching zap receipts for profile ");
  final profileReceipts = await ndk.zaps.fetchZappedReceipts(
    pubKey: "30782a8323b7c98b172c5a2af7206bb8283c655be6ddce11133611a03d5f1177",
  );

  // Sort profileReceipts by amountSats in descending order
  profileReceipts
      .sort((a, b) => (b.amountSats ?? 0).compareTo(a.amountSats ?? 0));

  int profileSum = 0;
  for (var receipt in profileReceipts) {
    String? sender;
    if (receipt.sender!=null) {
      Metadata? metadata = await ndk.metadata.loadMetadata(receipt.sender!);
      sender = metadata?.name;
    }
    print("${sender!=null?"from ${sender} ":""} ${receipt.amountSats} sats ${receipt.comment}");
    profileSum += receipt.amountSats ?? 0;
  }
  print("${profileReceipts.length} receipts, total of $profileSum sats");

  await ndk.destroy();
}
