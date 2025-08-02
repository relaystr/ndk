import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ndk/ndk.dart';
import 'package:nip46_event_signer/nip46_event_signer.dart';

const globalConnectionSettings = {
  "privateKey":
      "7a8317f947fff0526749e9fe53f79def8eb0afd378c01058f37140cc8732fecc",
  "remotePubkey":
      "b836aab8e635e41e62b832d68dc0f1857b717689df248290be9efa02f02de672",
  "relays": ["wss://relay.nsec.app"],
};

const relays = ["wss://relay.nsec.app"];

void main() {
  final ndk = Ndk.defaultConfig();
  Get.put(ndk);

  Get.put(TextEditingController());

  final nostrConnectLogin = NostrConnectLogin(
    relays: relays,
    appName: "Demo app",
  );
  nostrConnectLogin.stream.listen((event) {
    print(event.toJson());
  });
  Get.put(nostrConnectLogin);

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(child: SizedBox(width: 500, child: Nip46LoginView())),
      ),
    );
  }
}

class Nip46LoginView extends StatelessWidget {
  const Nip46LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: Get.find<TextEditingController>(),
          decoration: InputDecoration(
            hintText: "bunker://",
            suffixIcon: TextButton(
              onPressed: () async {
                final bunkerLogin = BunkerLogin(
                  bunkerUrl: Get.find<TextEditingController>().text,
                );
                bunkerLogin.stream.listen((event) {
                  print(event.toJson());
                });
              },
              child: Text("Connect"),
            ),
          ),
        ),
        SizedBox(height: 8),
        SelectableText(Get.find<NostrConnectLogin>().nostrConnectURL),
        SizedBox(height: 8),
        FilledButton(
          onPressed: () async {
            final ndk = Get.find<Ndk>();

            final signer = Nip46EventSigner(
              connectionSettings: ConnectionSettings.fromJson(
                globalConnectionSettings,
              ),
            );

            await signer.getPublicKeyAsync();

            ndk.accounts.loginExternalSigner(signer: signer);

            print(ndk.accounts.getPublicKey());
          },
          child: Text("Use global account"),
        ),
      ],
    );
  }
}
