import 'package:ndk/data_layer/repositories/signers/nip46_event_signer.dart';

void main() async {
  final bunkerLogin = BunkerLogin(bunkerUrl: "bunker://");
  bunkerLogin.stream.listen((event) {
    if (event is AuthRequired) {
      // user must authenticate using the url in event.url
    }

    if (event is Connected) {
      // successful connection, use event.settings to create the signer
    }
  });

  final nostrConnectLogin = NostrConnectLogin(
    relays: ["wss://relay.nsec.app"], // at least one relay is required
    appName: "My app", // appName is recommended, some apps may require it
  );
  nostrConnectLogin.stream.listen((event) {
    if (event is AuthRequired) {
      // user must authenticate using the url in event.url
    }

    if (event is Connected) {
      // successful connection, use event.settings to create the signer
    }
  });

  // at this point you should have connectionSettings
  final connectionSettings = ConnectionSettings.fromJson({
    "privateKey":
        "7a8317f947fff0526749e9fe53f79def8eb0afd378c01058f37140cc8732fecc",
    "remotePubkey":
        "b836aab8e635e41e62b832d68dc0f1857b717689df248290be9efa02f02de672",
    "relays": ["wss://relay.nsec.app"],
  });
  final nip46EventSigner = Nip46EventSigner(
    connectionSettings: connectionSettings,
  );
  await nip46EventSigner.getPublicKeyAsync(); // you should call this
  // your signer is ready
}
