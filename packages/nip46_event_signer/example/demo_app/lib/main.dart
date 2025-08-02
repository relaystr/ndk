import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ndk/ndk.dart';
import 'package:nip46_event_signer/nip46_event_signer.dart';

const globalConnectionSettings = {
  "privateKey":
      "f03fcf8f65409b454721dd02f6ca24012c56f8bf0842d6e79d247db895f6e85c",
  "remotePubkey":
      "b836aab8e635e41e62b832d68dc0f1857b717689df248290be9efa02f02de672",
  "relays": ["wss://relay.nsec.app"],
};

const relays = ["wss://relay.nsec.app"];

void main() {
  final ndk = Ndk.defaultConfig();
  Get.put(ndk);

  Get.put(TextEditingController());

  Get.put(Repository());

  final nostrConnectLogin = NostrConnectLogin(
    relays: relays,
    appName: "Demo app",
  );
  nostrConnectLogin.stream.listen((event) {
    print(event);
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
        body: Center(
          child: SizedBox(
            width: 500,
            child: GetBuilder<Repository>(
              builder: (c) {
                final ndk = Get.find<Ndk>();
                if (ndk.accounts.isLoggedIn) return HomeView();
                return Nip46LoginView();
              },
            ),
          ),
        ),
      ),
    );
  }
}

class Repository extends GetxController {
  static Repository get to => Get.find();
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
                  print(event);
                });
              },
              child: Text("Connect"),
            ),
          ),
        ),
        SizedBox(height: 8),
        SelectableText(Get.find<NostrConnectLogin>().nostrConnectURL),
        // SizedBox(height: 8),
        // FilledButton(
        //   onPressed: () async {
        //     final signer = Nip46EventSigner(
        //       connectionSettings: ConnectionSettings.fromJson(
        //         globalConnectionSettings,
        //       ),
        //     );

        //     await signer.getPublicKeyAsync();

        //     ndk.accounts.loginExternalSigner(signer: signer);

        //     print(ndk.accounts.isLoggedIn);

        //     Repository.to.update();
        //   },
        //   child: Text("Use global account"),
        // ),
      ],
    );
  }
}

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: () async {
        final ndk = Get.find<Ndk>();
        print(
          await (ndk.accounts.getLoggedAccount()!.signer as Nip46EventSigner)
              .getPublicKeyAsync(),
        );
      },
      child: Text("Get pubkey"),
    );
  }
}
