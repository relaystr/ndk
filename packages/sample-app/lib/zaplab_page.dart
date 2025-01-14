import 'package:flutter/material.dart';
import 'package:zaplab_design/zaplab_design.dart' as zaplab;

class ZaplabPage extends StatefulWidget {
  const ZaplabPage({super.key});

  @override
  State<ZaplabPage> createState() => _ZaplabPageState();
}

class _ZaplabPageState extends State<ZaplabPage> {
  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        zaplab.AppZapSlider(
          profileImageUrl: "",
          otherZaps: [],
        )
      ],
    );
  }
}
