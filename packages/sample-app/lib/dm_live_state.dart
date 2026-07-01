import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:ndk/ndk.dart';

class DmLiveState extends ChangeNotifier {
  final Ndk ndk;

  StreamSubscription<Account?>? _authSubscription;
  StreamSubscription<Nip01Event>? _dmSubscription;
  String? _activeRequestId;
  String? _activePubKey;
  final Set<String> _seenRumorIds = <String>{};
  final Map<String, Set<String>> _unreadRumorIdsByPeer =
      <String, Set<String>>{};
  final Map<String, int> _latestUnreadCreatedAtByPeer = <String, int>{};

  int _eventVersion = 0;

  DmLiveState({
    required this.ndk,
  });

  int get unreadCount =>
      _unreadRumorIdsByPeer.values.fold(0, (sum, ids) => sum + ids.length);
  int get unreadPeerCount => _unreadRumorIdsByPeer.length;
  int get eventVersion => _eventVersion;
  String? get latestUnreadPeerPubKey {
    if (_latestUnreadCreatedAtByPeer.isEmpty) {
      return null;
    }
    return _latestUnreadCreatedAtByPeer.entries
        .reduce((a, b) => a.value >= b.value ? a : b)
        .key;
  }

  int unreadCountForPeer(String peerPubKey) =>
      _unreadRumorIdsByPeer[peerPubKey]?.length ?? 0;

  void start() {
    _authSubscription ??= ndk.accounts.authStateChanges.listen((_) {
      _restart();
    });
    _restart();
  }

  Future<void> _restart() async {
    await _stopDmSubscription();

    _seenRumorIds.clear();
    _unreadRumorIdsByPeer.clear();
    _latestUnreadCreatedAtByPeer.clear();
    _activePubKey = ndk.accounts.getPublicKey();
    notifyListeners();

    final pubKey = _activePubKey;
    if (pubKey == null) {
      return;
    }

    try {
      final existingConversations = await ndk.dms.loadConversations();
      if (pubKey != _activePubKey) {
        return;
      }
      for (final conversation in existingConversations) {
        for (final message in conversation.messages) {
          _seenRumorIds.add(message.id);
        }
      }
    } catch (_) {
      // If the initial snapshot fails, continue with the live subscription.
    }

    final dmRelays = await ndk.userRelayLists.getDmRelays(pubKey);
    if (pubKey != _activePubKey || dmRelays == null || dmRelays.isEmpty) {
      return;
    }

    final response = ndk.requests.subscription(
      name: 'sample-app-dm-live',
      explicitRelays: dmRelays,
      cacheRead: false,
      cacheWrite: true,
      filter: Filter(
        kinds: [GiftWrap.kGiftWrapEventkind],
        pTags: [pubKey],
      ),
    );

    _activeRequestId = response.requestId;
    _dmSubscription = response.stream.listen(
      (wrappedEvent) async {
        try {
          final message = await ndk.dms.parseWrappedMessage(
            wrappedEvent: wrappedEvent,
          );
          if (message == null) {
            return;
          }

          final isNewMessage = _seenRumorIds.add(message.id);
          if (!isNewMessage) {
            return;
          }

          if (!message.isOutgoing) {
            _unreadRumorIdsByPeer
                .putIfAbsent(message.peerPubKey, () => <String>{})
                .add(message.id);
            _latestUnreadCreatedAtByPeer[message.peerPubKey] =
                message.createdAt;
          }
          _eventVersion++;
          notifyListeners();
        } catch (_) {
          // Ignore malformed or undecryptable incoming gift wraps.
        }
      },
    );
  }

  void clearUnread() {
    if (_unreadRumorIdsByPeer.isEmpty) {
      return;
    }
    _unreadRumorIdsByPeer.clear();
    _latestUnreadCreatedAtByPeer.clear();
    notifyListeners();
  }

  void clearUnreadForPeer(String peerPubKey) {
    final removedUnread = _unreadRumorIdsByPeer.remove(peerPubKey);
    _latestUnreadCreatedAtByPeer.remove(peerPubKey);
    if (removedUnread == null) {
      return;
    }
    notifyListeners();
  }

  Future<void> _stopDmSubscription() async {
    await _dmSubscription?.cancel();
    _dmSubscription = null;

    final requestId = _activeRequestId;
    _activeRequestId = null;
    if (requestId != null) {
      await ndk.requests.closeSubscription(
        requestId,
        debugLabel: 'sample-app-dm-live',
      );
    }
  }

  @override
  void dispose() {
    unawaited(_authSubscription?.cancel());
    _authSubscription = null;
    unawaited(_stopDmSubscription());
    super.dispose();
  }
}
