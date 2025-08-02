import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ndk/ndk.dart';

void main() {
  Get.put(Ndk.defaultConfig());

  Get.put(Nip46EventSigner)

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(child: SizedBox(width: 500, child: Nip46Login())),
      ),
    );
  }
}

class Nip46Login extends StatelessWidget {
  const Nip46Login({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          decoration: InputDecoration(
            hintText: "bunker://",
            suffixIcon: TextButton(onPressed: () {}, child: Text("Connect")),
          ),
        ),
        SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: SelectableText("data")),
            IconButton(onPressed: () {}, icon: Icon(Icons.copy)),
          ],
        ),
      ],
    );
  }
}
