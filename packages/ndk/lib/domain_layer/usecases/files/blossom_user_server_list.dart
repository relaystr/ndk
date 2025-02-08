import '../../entities/broadcast_state.dart';
import '../../entities/filter.dart';
import '../../entities/nip_01_event.dart';
import '../../repositories/event_signer.dart';
import '../broadcast/broadcast.dart';
import '../requests/requests.dart';
import 'blossom.dart';

/// Blossom User Server List used to manage the blossom servers of a user
class BlossomUserServerList {
  final Requests _requests;
  final Broadcast _broadcast;
  final EventSigner? signer;

  BlossomUserServerList({
    required Requests requests,
    required Broadcast broadcast,
    this.signer,
  })  : _requests = requests,
        _broadcast = broadcast;

  /// Get user server list \
  /// returns list of server urls \
  /// returns null if the user has no server list
  Future<List<String>?> getUserServerList({
    required List<String> pubkeys,
  }) async {
    final rsp = _requests.query(
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
      throw Exception("serverUrlsOrdered is empty");
    }

    if (signer == null) {
      throw Exception("Signer is null");
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

    final bResponse = _broadcast.broadcast(nostrEvent: myServerList);

    return bResponse.broadcastDoneFuture;
  }
}
