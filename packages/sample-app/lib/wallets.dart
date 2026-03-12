import 'package:flutter/material.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk_flutter/ndk_flutter.dart';

class WalletsPage extends StatelessWidget {
  final Ndk ndk;

  const WalletsPage({super.key, required this.ndk});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NWallets(ndk: ndk),
    );
  }
}
