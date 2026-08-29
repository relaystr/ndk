import '../../entities/filter.dart';
import '../../entities/nip_17_conversation.dart';
import '../../entities/nip_17_file_message.dart';
import '../../entities/nip_01_event.dart';
import '../../entities/nip_01_utils.dart';
import '../../entities/nip_17_message.dart';
import '../../repositories/cache_manager.dart';
import '../accounts/accounts.dart';
import '../broadcast/broadcast.dart';
import '../gift_wrap/gift_wrap.dart';
import '../requests/requests.dart';
import '../user_relay_lists/user_relay_lists.dart';

/// Direct-messages usecase built on NIP-17 gift-wrapped messages.
///
/// This usecase provides app-facing helpers for:
/// - sending a DM to a peer
/// - loading the logged-in user's conversations
/// - loading one conversation with a specific peer
/// - parsing a wrapped event into a DM message model
///
/// Conversation loading uses the logged-in user's DM relay list and can reuse
/// cached decrypted payload sidecars for fast repeated reads.
class Dms {
  /// Message rumor kind used by this DM usecase.
  static const int kMessageKind = 14;

  /// Encrypted file rumor kind defined by NIP-17.
  static const int kFileMessageKind = 15;

  final Accounts _accounts;
  final Requests _requests;
  final Broadcast _broadcast;
  final GiftWrap _giftWrap;
  final UserRelayLists _userRelayLists;
  final CacheManager _cacheManager;

  /// Creates the direct-messages usecase.
  Dms({
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

  /// Sends a direct message to [recipientPubKey].
  ///
  /// NDK creates a message rumor, wraps it once for the recipient and once for
  /// the sender, and broadcasts each wrapped copy to the corresponding DM
  /// relays.
  ///
  /// Throws if either side has no published DM relay list.
  Future<void> sendMessage({
    required String recipientPubKey,
    required String content,
    List<List<String>> additionalTags = const [],
  }) async {
    final senderPubKey = _requireLoggedPubKey();

    final rumor = await _giftWrap.createRumor(
      content: content,
      kind: kMessageKind,
      tags: [
        ['p', recipientPubKey],
        ...additionalTags,
      ],
    );

    await _sendRumor(
      rumor: rumor,
      recipientPubKey: recipientPubKey,
      senderPubKey: senderPubKey,
    );
  }

  /// Sends an already-uploaded encrypted file as a NIP-17 kind-15 message.
  ///
  /// The URL, hashes, MIME type, key and nonce are placed only in the encrypted
  /// rumor. Uploading the ciphertext is deliberately separate so applications
  /// can choose the appropriate standard Blossom kind-10063 server list.
  Future<void> sendFileMessage({
    required String recipientPubKey,
    required Nip17FileMetadata metadata,
    List<List<String>> additionalTags = const [],
  }) async {
    final senderPubKey = _requireLoggedPubKey();
    final rumor = await _giftWrap.createRumor(
      content: metadata.url.toString(),
      kind: kFileMessageKind,
      tags: [
        ['p', recipientPubKey],
        ...metadata.toTags(),
        ...additionalTags,
      ],
    );

    await _sendRumor(
      rumor: rumor,
      recipientPubKey: recipientPubKey,
      senderPubKey: senderPubKey,
    );
  }

  Future<void> _sendRumor({
    required Nip01Event rumor,
    required String recipientPubKey,
    required String senderPubKey,
  }) async {
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
      throw Exception('Recipient has no NIP-17 DM relays (kind 10050).');
    }

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

  /// Loads the full conversation with one peer.
  ///
  /// If [forceRefresh] is `false`, cached reads are allowed before or alongside
  /// network refresh. If the peer has no messages, an empty list is returned.
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

  /// Loads the conversation with one peer using cache only.
  ///
  /// This is useful for immediate UI rendering before a background refresh.
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

  /// Loads all conversations for the logged-in user.
  ///
  /// Conversations are grouped by peer pubkey and sorted by newest message
  /// first.
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

  /// Loads all conversations for the logged-in user using cache only.
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
      throw Exception('Logged in user has no NIP-17 DM relays (kind 10050).');
    }

    final response = _requests.query(
      name: 'dm-conversations',
      explicitRelays: dmRelays,
      cacheRead: !forceRefresh,
      cacheWrite: true,
      timeout: timeout,
      filter: Filter(kinds: [GiftWrap.kGiftWrapEventkind], pTags: [myPubKey]),
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

  /// Parses a single wrapped event into a DM message if possible.
  ///
  /// Returns `null` when the event is not a valid or decryptable NIP-17 message
  /// for the logged-in user.
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
      if (cacheOnly) {
        final cachedRumor = await _giftWrap.tryFromGiftWrapFromCache(
          giftWrap: wrappedEvent,
        );
        if (cachedRumor == null) {
          return null;
        }
      }

      final result = await _giftWrap.fromGiftWrapWithInfo(
        giftWrap: wrappedEvent,
      );
      final rumor = result.rumor;

      if (!result.isCryptographicallyValid ||
          !_hasExactlyOneRecipient(
            wrappedEvent,
            expectedRecipient: myPubKey,
          ) ||
          result.seal.kind != GiftWrap.kSealEventKind ||
          result.seal.tags.isNotEmpty ||
          rumor.sig != null ||
          !_hasCanonicalId(rumor) ||
          !_hasValidTimestamps(
            giftWrap: wrappedEvent,
            seal: result.seal,
            rumor: rumor,
          ) ||
          !_hasWellFormedParticipants(rumor)) {
        return null;
      }
      if (rumor.kind != kMessageKind && rumor.kind != kFileMessageKind) {
        return null;
      }
      if (rumor.kind == kFileMessageKind &&
          Nip17FileMetadata.tryParse(rumor) == null) {
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

  bool _hasExactlyOneRecipient(
    Nip01Event giftWrap, {
    required String expectedRecipient,
  }) {
    final recipientTags =
        giftWrap.tags.where((tag) => tag.isNotEmpty && tag[0] == 'p').toList();
    return recipientTags.length == 1 &&
        recipientTags.single.length >= 2 &&
        recipientTags.single[1] == expectedRecipient;
  }

  bool _hasCanonicalId(Nip01Event rumor) {
    final expectedId = Nip01Utils.calculateEventIdSync(
      pubKey: rumor.pubKey,
      createdAt: rumor.createdAt,
      kind: rumor.kind,
      tags: rumor.tags,
      content: rumor.content,
    );
    return rumor.id == expectedId;
  }

  bool _hasValidTimestamps({
    required Nip01Event giftWrap,
    required Nip01Event seal,
    required Nip01Event rumor,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final latestAccepted = now + _maximumFutureSkewSeconds;
    return giftWrap.createdAt > 0 &&
        seal.createdAt > 0 &&
        rumor.createdAt > 0 &&
        giftWrap.createdAt <= latestAccepted &&
        seal.createdAt <= latestAccepted &&
        rumor.createdAt <= latestAccepted;
  }

  bool _hasWellFormedParticipants(Nip01Event rumor) {
    final participantTags =
        rumor.tags.where((tag) => tag.isNotEmpty && tag[0] == 'p').toList();
    return participantTags.isNotEmpty &&
        participantTags.every(
          (tag) => tag.length >= 2 && _hexPubKey.hasMatch(tag[1]),
        );
  }

  String? _resolvePeerPubKey({
    required Nip01Event rumor,
    required String myPubKey,
  }) {
    final orderedParticipants = rumor.tags
        .where((tag) => tag.length >= 2 && tag[0] == 'p')
        .map((tag) => tag[1])
        .toList();
    final participants = orderedParticipants.toSet();
    if (rumor.pubKey == myPubKey) {
      for (final participant in orderedParticipants) {
        if (participant != myPubKey) {
          return participant;
        }
      }
      return null;
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
  static const int _maximumFutureSkewSeconds = 10 * 60;
  static final RegExp _hexPubKey = RegExp(r'^[0-9a-f]{64}$');

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
    await Future.wait(List.generate(workerCount, (_) => worker()));

    return results.cast<R>();
  }
}

/// App-facing alias for the direct-messages usecase.
