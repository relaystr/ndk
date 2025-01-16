import 'package:amberflutter/amberflutter.dart';
import 'package:flutter/material.dart';
import 'package:ndk/domain_layer/entities/read_write_marker.dart';
import 'package:ndk/domain_layer/entities/user_relay_list.dart';
import 'package:ndk/shared/nips/nip19/nip19.dart';

import 'main.dart';

class RelaysPage extends StatefulWidget {
  const RelaysPage({super.key});

  @override
  State<RelaysPage> createState() => _RelaysPageState();
}

class _RelaysPageState extends State<RelaysPage> {
  final amber = Amberflutter();
  // ignore: unused_field
  String _text = '';
  UserRelayList? relays;

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
                  amber.getPublicKey(
                    permissions: [
                      const Permission(
                        type: "nip04_encrypt",
                      ),
                      const Permission(
                        type: "nip04_decrypt",
                      ),
                    ],
                  ).then((value) async {
                    UserRelayList? list = await ndk.userRelayLists
                        .getSingleUserRelayList(Nip19.decode(value['signature']));
                    setState(() {
                      relays = list;
                    });
                  });
                },
                child: const Text("Fetch relay list"))
          ],
        )));
    if (relays!=null) {
      relays!.relays.keys.forEach((url) {
        ReadWriteMarker? marker = relays!.relays[url];
        widgets.add(Row(children: [Text(url), const Text(" "), Text((marker!.isRead?"Read ":" ")+(marker.isWrite?"Write":""))],));
      });
    }
    return Column(
        mainAxisAlignment: MainAxisAlignment.start, children: widgets);
  }
}
