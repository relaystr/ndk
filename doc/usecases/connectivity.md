---
icon: rss
---

[!badge variant="primary" text="high level"]

## Example

```dart
/// Stream<Map<String, RelayConnectivity>>
/// key: relay url/identifier
/// value: relay connectivity
ndkInstance.connectivity.relayConnectivityChanges;

/// NIP-11 info of a relay, fetched on first call and then cached
await ndkInstance.connectivity.getRelayInfo(relayConnectivity.url);

/// forces all relays to reconnect \
/// use this for faster reconnects based on your application/os connectivity \
tryReconnect();

```

```dart example in a flutter app
  // listen to lifecycle changes
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
 
    switch (state) {
      case AppLifecycleState.resumed:
        // reconnect instantly when resuming
        ndkInstance.connectivity.tryReconnect();
        break;
      case AppLifecycleState.inactive:
        break;
      case AppLifecycleState.paused:
        break;
      case AppLifecycleState.detached:
        break;
      case AppLifecycleState.hidden:
        break;
    }
  }
```

## When to use

Ndk uses exponential backoff to reconnect to relays.\
The reconnect interval might be too long when the app is in the background and then resumed. \
You can instantly reconnect using the `tryReconnect()` method, as shown in the example above.

`relayConnectivityChanges` can be used to display connectivity status in the UI. 

### Migrating from `RelayConnectivity.relayInfo`

`RelayConnectivity.relayInfo` and `ndk.relays.doesRelaySupportNip` are removed, so `relayConnectivityChanges` no longer carries NIP-11 info. NDK used to fetch it for every relay it connected to, whether the app read it or not. Ask for it where you need it:

```dart
// before
final info = relayConnectivity.relayInfo;
final supportsSearch = ndk.relays.doesRelaySupportNip(url, '50');

// after
final info = await ndk.connectivity.getRelayInfo(relayConnectivity.url);
final supportsSearch = info?.supportsNip('50') ?? false;
```