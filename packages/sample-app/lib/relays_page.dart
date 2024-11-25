import 'dart:convert';

import 'package:amberflutter/amberflutter.dart';
import 'package:flutter/material.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip19/nip19.dart';

import 'main.dart';

class RelaysPage extends StatefulWidget {
  const RelaysPage({super.key});

  @override
  State<RelaysPage> createState() => _RelaysPageState();
}

class _RelaysPageState extends State<RelaysPage> {
  @override
  Widget build(BuildContext context) {
    List<Widget> widgets = [];
    ndk.relays.relays.forEach((url, relay) {
      widgets.add(Container( padding: const EdgeInsets.all(20), child: Row( mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(url, style: const TextStyle(fontSize: 20),),
          const SizedBox(width: 20,),
          Text(ndk.relays.isRelayConnected(url) ? "Connected" : "Disconnected", style: TextStyle(color: ndk.relays.isRelayConnected(url) ? Colors.green: Colors.red),),
          !ndk.relays.isRelayConnected(url)?
          FilledButton(onPressed: () async {
            await ndk.relays.reconnectRelay(url, force: true);
          }, child: const Text("Reconnect"))
              : Container()
        ],
      )));
    });
    return Column(mainAxisAlignment: MainAxisAlignment.start, children: widgets);
  }
}
