import 'dart:convert';

import '../repositories/event_signer.dart';
import 'nip_01_event.dart';

class WalletCashuEvent {
  static const int kWalletKind = 17375;

  final String walletPrivkey;
  final Set<String> mints;

  final String userPubkey;

  late final Nip01Event? nostrEvent;

  WalletCashuEvent({
    required this.walletPrivkey,
    required this.mints,
    required this.userPubkey,
    Nip01Event? nostrEvent,
  }) {
    if (nostrEvent != null) {
      this.nostrEvent = nostrEvent;
      return;
    }
  }

  Future createNostrEvent(EventSigner signer) async {
    final encryptedContent = await signer.encryptNip44(
        plaintext: jsonEncode(toCashuEventContent),
        recipientPubKey: userPubkey);

    if (encryptedContent == null) {
      throw Exception("could not encrypt cashu wallet event");
    }

    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    nostrEvent = Nip01Event(
      pubKey: userPubkey,
      tags: [],
      kind: kWalletKind,
      createdAt: now,
      content: encryptedContent,
    );
  }

  List<List<String>> toCashuEventContent() {
    final jsonList = [
      ["privkey", "walletPrivkey"]
    ];

    jsonList.addAll(mints.map((mint) => ["mint", mint]));

    return jsonList;
  }
}
