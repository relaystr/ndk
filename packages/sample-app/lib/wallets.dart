import 'package:flutter/material.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk_demo/main.dart';
import 'package:ndk_flutter/ndk_flutter.dart';

class WalletsPage extends StatelessWidget {

  const WalletsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NWallets(ndkFlutter: ndkFlutter),
    );
  }
}
