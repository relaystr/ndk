import 'dart:convert';

import 'package:amberflutter/amberflutter.dart';
import 'package:flutter/material.dart';
import 'package:ndk/domain_layer/entities/user_relay_list.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip19/nip19.dart';

import 'main.dart';

class RelaysPage extends StatefulWidget {
  const RelaysPage({super.key});

  @override
  State<RelaysPage> createState() => _RelaysPageState();
}

class _RelaysPageState extends State<RelaysPage> {
  final amber = Amberflutter();
  String _text = '';

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
                    UserRelayList? response = await ndk.userRelayLists
                        .getSingleUserRelayList(value['signature']);
                    setState(() {
                      _text = '${response!.relays.toString()}';
                    });
                  });
                },
                child: const Text("Fetch relay list"))
          ],
        )));
    return Column(
        mainAxisAlignment: MainAxisAlignment.start, children: widgets);
  }
}
