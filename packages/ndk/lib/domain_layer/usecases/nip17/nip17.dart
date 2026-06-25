import '../../entities/filter.dart';
import '../../entities/nip_17_conversation.dart';
import '../../entities/nip_01_event.dart';
import '../../entities/nip_17_message.dart';
import '../../repositories/cache_manager.dart';
import '../accounts/accounts.dart';
import '../broadcast/broadcast.dart';
import '../gift_wrap/gift_wrap.dart';
import '../requests/requests.dart';
import '../user_relay_lists/user_relay_lists.dart';

class Nip17 {
  static const int kMessageKind = 14;

  final Accounts _accounts;
  final Requests _requests;
  final Broadcast _broadcast;
  final GiftWrap _giftWrap;
  final UserRelayLists _userRelayLists;
  final CacheManager _cacheManager;

  Nip17({
    required Accounts accounts,
    required Requests requests,
    required Broadcast broadcast,
    required GiftWrap giftWrap,
    required UserRelayLists userRelayLists,
    required CacheManager cacheManager,
  })  : _accounts = accounts,
        _requests = requests,
        _broadcast = broadcast,
        _giftWrap = giftWrap,
        _userRelayLists = userRelayLists,
        _cacheManager = cacheManager;

  Future<void> sendMessage({
    required String recipientPubKey,
    required String content,
    List<List<String>> additionalTags = const [],
  }) async {
    final senderPubKey = _requireLoggedPubKey();

    final senderDmRelays = await _userRelayLists.getDmRelays(senderPubKey);
    if (senderDmRelays == null || senderDmRelays.isEmpty) {
      throw Exception(
        'Sender has no NIP-17 DM relays (kind 10050). Publish one first.',
      );
    }

    final recipientDmRelays = await _userRelayLists.getDmRelays(
      recipientPubKey,
      forceRefresh: true,
    );
    if (recipientDmRelays == null || recipientDmRelays.isEmpty) {
      throw Exception(
        'Recipient has no NIP-17 DM relays (kind 10050).',
      );
    }

    final rumor = await _giftWrap.createRumor(
      content: content,
      kind: kMessageKind,
      tags: [
        ['p', recipientPubKey],
        ...additionalTags,
      ],
    );

    final recipientWrap = await _giftWrap.toGiftWrap(
      rumor: rumor,
      recipientPubkey: recipientPubKey,
    );
    final senderWrap = await _giftWrap.toGiftWrap(
      rumor: rumor,
      recipientPubkey: senderPubKey,
    );

    final recipientBroadcast = _broadcast.broadcast(
      nostrEvent: recipientWrap,
      specificRelays: recipientDmRelays,
    );
    final senderBroadcast = _broadcast.broadcast(
      nostrEvent: senderWrap,
      specificRelays: senderDmRelays,
    );

    await Future.wait([
      recipientBroadcast.broadcastDoneFuture,
      senderBroadcast.broadcastDoneFuture,
    ]);
  }

  Future<List<Nip17Message>> loadConversation({
    required String peerPubKey,
    bool forceRefresh = false,
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final conversations = await loadConversations(
      forceRefresh: forceRefresh,
      timeout: timeout,
    );
    for (final conversation in conversations) {
      if (conversation.peerPubKey == peerPubKey) {
        return conversation.messages;
      }
    }
    return const [];
  }

  Future<List<Nip17Message>> loadConversationSnapshot({
    required String peerPubKey,
  }) async {
    final conversations = await loadConversationsSnapshot();
    for (final conversation in conversations) {
      if (conversation.peerPubKey == peerPubKey) {
        return conversation.messages;
      }
    }
    return const [];
  }

  Future<List<Nip17Conversation>> loadConversations({
    bool forceRefresh = false,
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final myPubKey = _requireLoggedPubKey();
    final wrappedEvents = await _loadWrappedEvents(
      myPubKey: myPubKey,
      forceRefresh: forceRefresh,
      timeout: timeout,
    );
    final messages = await _parseMessages(
      wrappedEvents: wrappedEvents,
      myPubKey: myPubKey,
      cacheOnly: false,
    );
    return _buildConversations(messages);
  }

  Future<List<Nip17Conversation>> loadConversationsSnapshot() async {
    final myPubKey = _requireLoggedPubKey();
    final wrappedEvents = await _loadWrappedEventsFromCache(myPubKey: myPubKey);
    final messages = await _parseMessages(
      wrappedEvents: wrappedEvents,
      myPubKey: myPubKey,
      cacheOnly: true,
    );
    return _buildConversations(messages);
  }

  Future<List<Nip01Event>> _loadWrappedEvents({
    required String myPubKey,
    required bool forceRefresh,
    required Duration timeout,
  }) async {
    final dmRelays = await _userRelayLists.getDmRelays(
      myPubKey,
      forceRefresh: forceRefresh,
    );

    if (dmRelays == null || dmRelays.isEmpty) {
      throw Exception(
        'Logged in user has no NIP-17 DM relays (kind 10050).',
      );
    }

    final response = _requests.query(
      name: 'nip17-conversations',
      explicitRelays: dmRelays,
      cacheRead: !forceRefresh,
      cacheWrite: true,
      timeout: timeout,
      filter: Filter(
        kinds: [GiftWrap.kGiftWrapEventkind],
        pTags: [myPubKey],
      ),
    );

    return response.future;
  }

  Future<List<Nip01Event>> _loadWrappedEventsFromCache({
    required String myPubKey,
  }) {
    return _cacheManager.loadEvents(
      kinds: const [GiftWrap.kGiftWrapEventkind],
      tags: {
        'p': [myPubKey],
      },
    );
  }

  Future<List<Nip17Message>> _parseMessages({
    required List<Nip01Event> wrappedEvents,
    required String myPubKey,
    required bool cacheOnly,
  }) async {
    final byRumorId = <String, Nip17Message>{};
    final messages = await _mapConcurrent(
      wrappedEvents,
      _parseConcurrencyLimit,
      (wrappedEvent) => _tryParseMessage(
        wrappedEvent: wrappedEvent,
        myPubKey: myPubKey,
        cacheOnly: cacheOnly,
      ),
    );

    for (final message in messages) {
      if (message == null) {
        continue;
      }
      final existing = byRumorId[message.id];
      if (existing == null ||
          existing.createdAt < message.createdAt ||
          (existing.createdAt == message.createdAt &&
              existing.wrappedEvent.createdAt <
                  message.wrappedEvent.createdAt)) {
        byRumorId[message.id] = message;
      }
    }

    return byRumorId.values.toList();
  }

  List<Nip17Conversation> _buildConversations(List<Nip17Message> messages) {
    final byPeer = <String, List<Nip17Message>>{};

    for (final message in messages) {
      byPeer.putIfAbsent(message.peerPubKey, () => []).add(message);
    }

    final conversations = byPeer.entries.map((entry) {
      final peerMessages = entry.value
        ..sort((a, b) {
          final createdAtCompare = a.createdAt.compareTo(b.createdAt);
          if (createdAtCompare != 0) {
            return createdAtCompare;
          }
          return a.id.compareTo(b.id);
        });
      return Nip17Conversation(
        peerPubKey: entry.key,
        messages: List.unmodifiable(peerMessages),
      );
    }).toList()
      ..sort((a, b) => b.latestCreatedAt.compareTo(a.latestCreatedAt));

    return conversations;
  }

  Future<Nip17Message?> parseWrappedMessage({
    required Nip01Event wrappedEvent,
  }) async {
    final myPubKey = _requireLoggedPubKey();
    return _tryParseMessage(
      wrappedEvent: wrappedEvent,
      myPubKey: myPubKey,
      cacheOnly: false,
    );
  }

  Future<Nip17Message?> _tryParseMessage({
    required Nip01Event wrappedEvent,
    required String myPubKey,
    required bool cacheOnly,
  }) async {
    try {
      final cachedRumor = await _giftWrap.tryFromGiftWrapFromCache(
        giftWrap: wrappedEvent,
      );
      final rumor = cacheOnly
          ? cachedRumor
          : cachedRumor ??
              await _giftWrap.fromGiftWrap(
                giftWrap: wrappedEvent,
              );
      if (rumor == null) {
        return null;
      }
      if (rumor.kind != kMessageKind) {
        return null;
      }

      final resolvedPeer = _resolvePeerPubKey(rumor: rumor, myPubKey: myPubKey);
      if (resolvedPeer == null) {
        return null;
      }

      return Nip17Message(
        wrappedEvent: wrappedEvent,
        rumor: rumor,
        peerPubKey: resolvedPeer,
        isOutgoing: rumor.pubKey == myPubKey,
      );
    } catch (_) {
      return null;
    }
  }

  String? _resolvePeerPubKey({
    required Nip01Event rumor,
    required String myPubKey,
  }) {
    final participants = rumor.pTags.toSet();
    if (rumor.pubKey == myPubKey) {
      final others =
          participants.where((pubKey) => pubKey != myPubKey).toList();
      if (others.length != 1) {
        return null;
      }
      return others.first;
    }

    if (rumor.pubKey != myPubKey && participants.contains(myPubKey)) {
      return rumor.pubKey;
    }

    return null;
  }

  String _requireLoggedPubKey() {
    final pubKey = _accounts.getPublicKey();
    if (pubKey == null) {
      throw Exception('NIP-17 requires a logged in account.');
    }
    return pubKey;
  }

  static const int _parseConcurrencyLimit = 8;

  Future<List<R>> _mapConcurrent<T, R>(
    List<T> items,
    int concurrency,
    Future<R> Function(T item) mapper,
  ) async {
    if (items.isEmpty) {
      return <R>[];
    }

    final results = List<R?>.filled(items.length, null);
    var nextIndex = 0;

    Future<void> worker() async {
      while (true) {
        final currentIndex = nextIndex;
        if (currentIndex >= items.length) {
          return;
        }
        nextIndex++;
        results[currentIndex] = await mapper(items[currentIndex]);
      }
    }

    final workerCount = concurrency < items.length ? concurrency : items.length;
    await Future.wait(
      List.generate(workerCount, (_) => worker()),
    );

    return results.cast<R>();
  }
}
