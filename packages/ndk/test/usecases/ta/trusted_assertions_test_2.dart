import 'package:ndk/ndk.dart';

final relay = "wss://nip85.uid.ovh";
// final relay = "ws://localhost:3334";

final providers = [
  Nip85TrustedProvider(
    kind: Nip85Kind.user,
    metric: Nip85Metric.followers,
    pubkey: "3116ea6afb590a19455d7b39ae3317c62b2bbb236986788b7e0ae12ec2281101",
    relay: relay,
  ),
  Nip85TrustedProvider(
    kind: Nip85Kind.user,
    metric: Nip85Metric.rank,
    pubkey: "cbeb151f3f5c4925c392c2b79936c3acd3c5c73a8ad60173ee6e43ff9112cfe1",
    relay: relay,
  ),
  Nip85TrustedProvider(
    kind: Nip85Kind.user,
    metric: Nip85Metric.firstCreatedAt,
    pubkey: "367afc8744a62f99f0d6aa70b7a5506f57c302aff3ea72cf7cc7346371f82a25",
    relay: relay,
  ),
  Nip85TrustedProvider(
    kind: Nip85Kind.user,
    metric: Nip85Metric.firstSeenAt,
    pubkey: "2c04e8c33beeba6578f2a0b3ba290f8e368a8e267bfa2c5ab5b96a5f60d826ab",
    relay: relay,
  ),
  Nip85TrustedProvider(
    kind: Nip85Kind.user,
    metric: Nip85Metric.postCount,
    pubkey: "c3e5ec4ccddc5b8535dab6dd3db3281923ee280f9aea6295ed68b571fc296fbc",
    relay: relay,
  ),
  Nip85TrustedProvider(
    kind: Nip85Kind.user,
    metric: Nip85Metric.replyCount,
    pubkey: "9527682db2b48a7430fcd08750e2f925fc7b8cc2a2cb324239eb136ff06fe712",
    relay: relay,
  ),
  Nip85TrustedProvider(
    kind: Nip85Kind.user,
    metric: Nip85Metric.reactionsCount,
    pubkey: "971c2269983ff452d945e32168486ff258003d5b778acbfe889bda54fc06a0b5",
    relay: relay,
  ),
  Nip85TrustedProvider(
    kind: Nip85Kind.user,
    metric: Nip85Metric.zapAmountReceived,
    pubkey: "91a82c20fc3f020f990aae0c26b6661a91926cb702d9bd9f8f2a2a1cbf72bc22",
    relay: relay,
  ),
  Nip85TrustedProvider(
    kind: Nip85Kind.user,
    metric: Nip85Metric.zapAmountSent,
    pubkey: "86175feae9b938c8a399680c1be162cd47a9aac00e78ab0069b3f7831793ceb2",
    relay: relay,
  ),
  Nip85TrustedProvider(
    kind: Nip85Kind.user,
    metric: Nip85Metric.zapCountReceived,
    pubkey: "f2066eb230b2fd7937c1e93d98b308de4c1fefa041c17604bd944164cbf8701d",
    relay: relay,
  ),
  Nip85TrustedProvider(
    kind: Nip85Kind.user,
    metric: Nip85Metric.zapCountSent,
    pubkey: "780c6f1e2b531c710bcaf87c25ec9d3e927a2de1a72c3e22ee68077d30430c98",
    relay: relay,
  ),
  Nip85TrustedProvider(
    kind: Nip85Kind.user,
    metric: Nip85Metric.zapAvgAmountDayReceived,
    pubkey: "a30c5ffee52284e21a7acca7aab8d45ed1f1f5461d802a602e887c7a1f680955",
    relay: relay,
  ),
  Nip85TrustedProvider(
    kind: Nip85Kind.user,
    metric: Nip85Metric.zapAvgAmountDaySent,
    pubkey: "3ee65e119f9d0feaaaa18a001ccfe186bd050e2f4c1e679ae0fbeedfd2f53ca3",
    relay: relay,
  ),
  Nip85TrustedProvider(
    kind: Nip85Kind.user,
    metric: Nip85Metric.reportsCountReceived,
    pubkey: "e9229572ed302c073ee1e30834f3d964a809532966c2082302574cfa1638931a",
    relay: relay,
  ),
  Nip85TrustedProvider(
    kind: Nip85Kind.user,
    metric: Nip85Metric.reportsCountSent,
    pubkey: "c7b8bdc6212193586a1a5c5053f0221705a8b9060650b942f0069adbbf77b346",
    relay: relay,
  ),
  Nip85TrustedProvider(
    kind: Nip85Kind.user,
    metric: Nip85Metric.activeHoursStart,
    pubkey: "e9087d8dbdfe211eb9b6e112aa78d313300a2ac48fa5ef0cbc480fd96c1bd558",
    relay: relay,
  ),
  Nip85TrustedProvider(
    kind: Nip85Kind.user,
    metric: Nip85Metric.activeHoursEnd,
    pubkey: "816548ad83107b9adae3074df90a0faa85004559cda47b8d7da2bafebcd79b05",
    relay: relay,
  ),
];

void main() {
  final ndk = Ndk(
    NdkConfig(
      eventVerifier: Bip340EventVerifier(),
      cache: MemCacheManager(),
      defaultTrustedProviders: providers,
    ),
  );

  final npub =
      "npub1s5yq6wadwrxde4lhfs56gn64hwzuhnfa6r9mj476r5s4hkunzgzqrs6q7z";

  final pubkey = Nip19.decode(npub);

  print("Start");

  final stream =
      ndk.ta.streamUserMetrics(pubkey, metrics: {Nip85Metric.reactionsCount});

  stream.listen((metrics) {
    print('postCount: ${metrics.reactionsCount}');
  });
}
