import '../../entities/filter.dart';
import '../requests/requests.dart';
import 'blossom.dart';

class BlossomUserServerList {
  final Requests requests;

  BlossomUserServerList(
    this.requests,
  );

  /// Get user server list
  /// returns list of server urls
  /// returns null if the user has no server list
  Future<List<String>?> getUserServerList({
    required List<String> pubkeys,
  }) async {
    final rsp = requests.query(
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
}
