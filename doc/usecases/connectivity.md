---
icon: rss
---

[!badge variant="primary" text="high level"]

## Example

```dart
/// Stream<Map<String, RelayConnectivity>>
/// key: relay url/identifier
/// value: relay connectivity
ndk.connectivity.relayConnectivityChanges;


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
        final ndkInstance = _ref.read(ndkProvider);
        // reconnect instantly when resuming
        tryReconnect();
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