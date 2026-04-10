// ignore_for_file: avoid_print

import 'package:ndk/ndk.dart';

String _formatPaidAt(int? paidAt) {
  if (paidAt == null) {
    return "unknown-time";
  }

  final dateTime = DateTime.fromMillisecondsSinceEpoch(paidAt * 1000).toLocal();
  final year = dateTime.year.toString().padLeft(4, '0');
  final month = dateTime.month.toString().padLeft(2, '0');
  final day = dateTime.day.toString().padLeft(2, '0');
  final hour = dateTime.hour.toString().padLeft(2, '0');
  final minute = dateTime.minute.toString().padLeft(2, '0');

  return "$year-$month-$day $hour:$minute";
}

void main() async {
  final ndk = Ndk.defaultConfig();

  print("fetching zap receipts for profile ");
  final profileReceipts = await ndk.zaps
      .fetchZappedReceipts(
        pubKey:
            "30782a8323b7c98b172c5a2af7206bb8283c655be6ddce11133611a03d5f1177",
      )
      .toList();

  // Sort profileReceipts by paidAt (created_at) in descending order
  profileReceipts.sort((a, b) => (b.paidAt ?? 0).compareTo(a.paidAt ?? 0));

  int profileSum = 0;
  for (var receipt in profileReceipts) {
    String? sender;
    if (receipt.sender != null) {
      Metadata? metadata = await ndk.metadata.loadMetadata(receipt.sender!);
      sender = metadata?.name;
    }
    final paidAtFormatted = _formatPaidAt(receipt.paidAt);
    print(
        "$paidAtFormatted ${sender != null ? "from $sender " : ""} ${receipt.amountSats} sats ${receipt.comment}");
    profileSum += receipt.amountSats ?? 0;
  }
  print("${profileReceipts.length} receipts, total of $profileSum sats");

  await ndk.destroy();
}
