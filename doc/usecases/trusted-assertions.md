---
label: Trusted Assertions (NIP-85)
order: 50
icon: agent
---

[!badge variant="primary" text="low level"]


## When to use

Trusted assertions are data events computed by a provider. It's useful when certain operations might be too expensive (bandwidth, compute) on the edge device.

## Usage Example

## 1) Option A: Use NDK default trusted providers

NDK ships `defaultTrustedProviders` preconfigured for NIP-85.

```dart
final metrics = await ndk.ta.getUserMetrics(
  '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef',
  metrics: {Nip85Metric.rank, Nip85Metric.followers},
);

print('rank=${metrics?.rank}, followers=${metrics?.followers}');
```

## 2) Option B: Override providers with your Cipolin instance



```dart
  final NdkConfig ndkConfig = NdkConfig(
    cache: db!,
    eventVerifier: eventVerifier,
    bootstrapRelays: APP_DEFAULT_BOOTSTRAP_RELAYS,
    logLevel: Logger.logLevels.info,
    defaultTrustedProviders: APP_DEFAULT_NIP85_PROVIDERS,
  );
```

or per request

``` dart

final stream = ndk.ta.getUserMetrics(
        <eventId>,
        metrics: <metrics>,
        providers: <providers>,
      );

print('user rank=${user?.rank} postCount=${user?.postCount}');
```

```dart


final user = await ndk.ta.getUserMetrics(
  '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef',
  metrics: {Nip85Metric.rank, Nip85Metric.postCount, Nip85Metric.replyCount},
  providers: providers,
);

print('user rank=${user?.rank} postCount=${user?.postCount}');
```

## 3) Streaming updates (recommended for trust providers that stream their values like cipolin)

Providers like [Cipolin](https://github.com/nogringo/cipolin/) emit progressive updates while syncing, so streaming APIs are the best fit.



```dart
final sub = ndk.ta
    .streamUserMetrics(
      '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef',
      metrics: {Nip85Metric.rank, Nip85Metric.followers, Nip85Metric.reactionsCount},
      providers: providers,
    )
    .listen((m) {
      print('update createdAt=${m.createdAt} rank=${m.rank} followers=${m.followers}');
    });

// Later:
await sub.cancel();
```

## 4) Event and addressable lookups

Event metrics (kind 30383):

```dart
final eventMetrics = await ndk.ta.getEventMetrics(
  '<eventId>',
  metrics: {Nip85Metric.rank, Nip85Metric.commentCount, Nip85Metric.zapAmount},
  providers: providers,
);

print('event rank=${eventMetrics?.rank} comments=${eventMetrics?.commentCount}');
```

Addressable metrics (kind 30384):

```dart
final addressMetrics = await ndk.ta.getAddressableMetrics(
  '30023:0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef:my-article-slug',
  metrics: {Nip85Metric.rank, Nip85Metric.reactionCount, Nip85Metric.zapCount},
  providers: providers,
);

print('address rank=${addressMetrics?.rank} zaps=${addressMetrics?.zapCount}');
```


