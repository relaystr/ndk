import '../../entities/broadcast_state.dart';
import '../../entities/filter.dart';
import '../../entities/nip_01_event.dart';
import '../../repositories/event_signer.dart';
import '../broadcast/broadcast.dart';
import '../requests/requests.dart';
import 'blossom.dart';

class BlossomUserServerList {
  final Requests requests;
  final Broadcast broadcast;
  final EventSigner? signer;

  BlossomUserServerList({
    required this.requests,
    required this.broadcast,
    this.signer,
  });

  /// Get user server list \
  /// returns list of server urls \
  /// returns null if the user has no server list
  Future<List<String>?> getUserServerList({
    required List<String> pubkeys,
  }) async {
    final rsp = requests.query(
      timeout: Duration(seconds: 5),
      filters: [
        Filter(
          authors: pubkeys,
          kinds: [Blossom.kBlossomUserServerList],
        )
      ],
    );

    final data = await rsp.future;
    data.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    if (data.isEmpty) {
      return null;
    }

    final List<String> foundServers = [];

    for (final tag in data.first.tags) {
      if (tag.length > 1 && tag[0] == 'server') {
        foundServers.add(tag[1]);
      }
    }

    return foundServers;
  }

  /// Publish user server list \
  /// order of [serverUrlsOrdered] is important, the first server is the most trusted server
  Future<List<RelayBroadcastResponse>> publishUserServerList({
    required List<String> serverUrlsOrdered,
  }) async {
    if (serverUrlsOrdered.isEmpty) {
      throw "serverUrlsOrdered is empty";
    }

    if (signer == null) {
      throw "Signer is null";
    }

    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    final Nip01Event myServerList = Nip01Event(
      content: "",
      pubKey: signer!.getPublicKey(),
      kind: Blossom.kBlossomUserServerList,
      createdAt: now,
      tags: [
        for (var i = 0; i < serverUrlsOrdered.length; i++)
          ["server", serverUrlsOrdered[i]],
      ],
    );

    final bResponse = broadcast.broadcast(nostrEvent: myServerList);

    return bResponse.broadcastDoneFuture;
  }
}
