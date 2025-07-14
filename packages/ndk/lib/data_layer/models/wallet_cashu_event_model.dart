import 'dart:convert';

import '../../domain_layer/entities/nip_01_event.dart';
import '../../domain_layer/entities/tuple.dart';
import '../../domain_layer/entities/wallet_cashu_event.dart';
import '../../domain_layer/repositories/event_signer.dart';

class WalletCashuEventModel extends WalletCashuEvent {
  WalletCashuEventModel({
    required super.mints,
    required super.walletPrivkey,
    required super.userPubkey,
  });

  /// creates a nostr event based on the WalletCashuEvent data
  Future<Nip01Event> createNostrEvent({
    required EventSigner signer,
  }) async {
    final encryptedContent = await signer.encryptNip44(
        plaintext: jsonEncode(
            toCashuEventContent(privKey: walletPrivkey, mints: mints)),
        recipientPubKey: userPubkey);

    if (encryptedContent == null) {
      throw Exception("could not encrypt cashu wallet event");
    }

    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return Nip01Event(
      pubKey: userPubkey,
      tags: [],
      kind: WalletCashuEvent.kWalletKind,
      createdAt: now,
      content: encryptedContent,
    );
  }

  /// creates a WalletCashuEvent from a nip01Event
  Future<WalletCashuEventModel> fromNip01Event({
    required Nip01Event nostrEvent,
    required EventSigner signer,
  }) async {
    final decryptedContent = await signer.decryptNip44(
      ciphertext: nostrEvent.content,
      senderPubKey: nostrEvent.pubKey,
    );
    if (decryptedContent == null) {
      throw Exception("could not decrypt cashu wallet event");
    }
    final jsonContent = jsonDecode(decryptedContent);

    final extractedContent = fromCashuEventContent(jsonContent);

    return WalletCashuEventModel(
      walletPrivkey: extractedContent.first,
      mints: extractedContent.second,
      userPubkey: nostrEvent.pubKey,
    );
  }

  /// converts to plain list data from WalletCashuEvent
  static List<List<String>> toCashuEventContent({
    required String privKey,
    required Set<String> mints,
  }) {
    final jsonList = [
      ["privkey", privKey]
    ];

    jsonList.addAll(mints.map((mint) => ["mint", mint]));

    return jsonList;
  }

  /// extracts data from plain lists
  static Tuple<String, Set<String>> fromCashuEventContent(
    List<List<String>> jsonList,
  ) {
    String? privKey;
    final Set<String> mints = {};

    for (final item in jsonList) {
      if (item.length == 2) {
        final key = item[0];
        final value = item[1];

        if (key == 'privkey') {
          privKey = value;
        } else if (key == 'mint') {
          mints.add(value);
        }
      }
    }

    if (privKey == null) {
      throw ArgumentError('Input list does not contain a private key.');
    }

    return Tuple(privKey, mints);
  }
}
