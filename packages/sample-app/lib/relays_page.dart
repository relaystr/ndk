import 'package:flutter/material.dart';
import 'package:ndk/data_layer/repositories/nostr_transport/websocket_client_nostr_transport.dart';
import 'package:ndk/entities.dart';

import 'main.dart';

class RelaysPage extends StatefulWidget {
  const RelaysPage({super.key});

  @override
  State<RelaysPage> createState() => _RelaysPageState();
}

class _RelaysPageState extends State<RelaysPage> {
  // final amber = Amberflutter();
  // ignore: unused_field
  String _text = '';
  UserRelayList? relays;


  @override
  void initState() {
    ndk.connectivity.relayConnectivityChanges.listen((data) {
      setState(() {
        print("Relay connectivity changed for ${data}");
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> widgets = [];
    widgets.add(Container(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 20,
            ),
            FilledButton(
                onPressed: () async {
                  UserRelayList? list = await ndk.userRelayLists
                      .getSingleUserRelayList(ndk.accounts.getPublicKey()!);

                  for (var url in list!.relays.keys) {
                    await ndk.relays.connectRelay(dirtyUrl: url, connectionSource: ConnectionSource.unknown);
                  }
                  setState(() {
                    relays = list;
                  });
                },
                child: const Text("Fetch relay list"))
          ],
        )));
    if (relays!=null) {
      for (var url in relays!.relays.keys) {
        ReadWriteMarker? marker = relays!.relays[url];
        WebSocketClientNostrTransport? t = ndk.relays.getRelayConnectivity(url)?.relayTransport as WebSocketClientNostrTransport?;
        final stateColor = t!=null ?
          t.isConnecting()? Colors.orange :
          t.isOpen()? Colors.green : Colors.red
          : Colors.grey;

        widgets.add(Row(children: [
          const Text(" "),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: stateColor,
            ),
          ),
          const Text(" "),
          Text(url),
          const Text(" "),
          Text((marker!.isRead?"Read ":" ")+(marker.isWrite?"Write":"")),
          const Text(" "),
        ],));
      }
    }
    return Column(
        mainAxisAlignment: MainAxisAlignment.start, children: widgets);
  }
}
