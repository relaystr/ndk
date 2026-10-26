import 'dart:math';
import 'dart:typed_data';

import 'package:ndk/domain_layer/entities/nip_01_event.dart';
import 'package:ndk/domain_layer/repositories/event_signer.dart';

import '../control/control_edition.dart';
import '../control/control_fold.dart';
import '../core/concord_constants.dart';
import '../core/concord_time.dart';
import '../core/derivations.dart';
import '../core/encoding.dart';
import '../guestbook/guestbook.dart';
import '../chat/chat.dart';
import '../invite/community_invite.dart';
import '../invite/direct_invite.dart';
import '../keys/concord_keys.dart';
import '../rekey/rekey_blob.dart';
import '../store/concord_store.dart';
import '../stream/stream_envelope.dart';

/// A member's folded view of one Community (CORD-02).
class ConcordCommunity {
  final CommunityKeys keys;
  final ControlState control;
  final GuestbookState guestbook;

  /// Chat folds keyed by `channelId/epoch`.
  final Map<String, ChatChannelFold> chats;

  const ConcordCommunity({
    required this.keys,
    required this.control,
    required this.guestbook,
    required this.chats,
  });

  String get communityId => keys.communityId;

  /// Every channel the fold knows about (from control).
  Iterable<String> get channelIds => control.channels.keys;

  /// The Chat folds for one channel, across the epochs held.
  Iterable<ChatChannelFold> chatFolds(String channelId) => chats.entries
      .where((e) => e.key.startsWith('$channelId/'))
      .map((e) => e.value);

  /// All messages in one channel, oldest first.
  List<ChatMessage> messagesIn(String channelId) {
    final all = <ChatMessage>[];
    for (final fold in chatFolds(channelId)) {
      all.addAll(fold.messages());
    }
    all.sort((a, b) {
      final byTime = a.at.compareTo(b.at);
      return byTime != 0 ? byTime : a.id.compareTo(b.id);
    });
    return all;
  }
}

/// The client-facing facade over the Concord primitives: it holds an
/// [EventSigner] (the member's real key) plus a [ConcordStore], and turns
/// app-level actions into sealed, wrapped events — and back.
///
/// It deliberately does **no** relay I/O: [publishRumor] returns the signed
/// wrap and queues it in the store's outbox, and the app (or a
/// [ConcordStore] implementation) does the broadcasting. Incoming wraps are
/// handed to [openAndStore], which unwraps, verifies and appends the rumor.
class ConcordClient {
  /// Signs the Seal layer (every plane's seal is the member's real key).
  final EventSigner signer;

  final ConcordStore store;

  static final Random _random = Random.secure();

  ConcordClient({required this.signer, ConcordStore? store})
    : store = store ?? InMemoryConcordStore();

  // --- community lifecycle --------------------------------------------------

  /// Creates a brand-new Community owned by [signer]. Generates a
  /// `community_root` (member access), a `control_root` (staff write) and an
  /// `owner_salt`; all may be supplied for deterministic tests.
  Future<CommunityKeys> createCommunity({
    required String name,
    List<String> relays = const [],
    Uint8List? communityRoot,
    Uint8List? controlRoot,
    Uint8List? ownerSalt,
    int rootEpoch = 0,
  }) async {
    final owner = signer.getPublicKey();
    checkHex32(owner, 'owner');
    final salt = ownerSalt ?? _random32();
    final root = communityRoot ?? _random32();
    final control = controlRoot ?? _random32();
    final cid = communityId(ownerXonly: owner, ownerSalt: salt);
    final controlPk = Planes.controlSignerPk(
      controlRoot: control,
      communityId: cid,
      epoch: rootEpoch,
    );
    final keys = CommunityKeys(
      communityId: cid,
      owner: owner,
      ownerSalt: salt,
      rootEpoch: rootEpoch,
      communityRoot: root,
      controlPk: controlPk,
      controlEpoch: rootEpoch,
      controlRoot: control,
      relays: relays.take(Caps.communityRelays).toList(),
      name: name,
    );
    await store.putCommunity(keys);
    return keys;
  }

  Future<void> saveCommunity(CommunityKeys keys) => store.putCommunity(keys);

  Future<CommunityKeys?> community(String communityId) =>
      store.getCommunity(communityId);

  Future<List<CommunityKeys>> communities() => store.allCommunities();

  Future<void> forgetCommunity(String communityId) =>
      store.deleteCommunity(communityId);

  // --- invites --------------------------------------------------------------

  /// Builds a Direct Invite (CORD-05 §6) handing [keys] to [recipient].
  Future<Nip01Event> createDirectInvite(
    CommunityKeys keys, {
    required String recipient,
    List<InviteChannel>? channels,
    int? expiresAt,
    String? label,
    int? createdAt,
    String? ephemeralSk,
  }) {
    final invite = CommunityInvite(
      communityId: keys.communityId,
      owner: keys.owner,
      ownerSalt: keys.ownerSalt,
      communityRoot: keys.communityRoot,
      rootEpoch: keys.rootEpoch,
      controlPk: keys.controlPk.isEmpty ? null : keys.controlPk,
      channels: channels ?? _channelsOf(keys),
      relays: keys.relays,
      name: keys.name,
      expiresAt: expiresAt,
      creatorNpub: signer.getPublicKey(),
      label: label,
    );
    return DirectInvites.build(
      invite: invite,
      senderSigner: signer,
      recipientPubkey: recipient,
      rumourCreatedAt: createdAt,
      ephemeralSk: ephemeralSk,
    );
  }

  /// Opens a kind 1059 Direct Invite, validating the bundle and storing the
  /// membership. Returns null when the wrap is not ours or the bundle is
  /// refused; throws nothing on bad input.
  Future<CommunityKeys?> acceptDirectInvite(Nip01Event wrap) async {
    final DirectInvite opened;
    try {
      opened = await DirectInvites.unwrap(wrap: wrap, recipientSigner: signer);
    } catch (_) {
      return null;
    }
    final keys = opened.invite.toKeys();
    await store.putCommunity(keys);
    return keys;
  }

  // --- publishing -----------------------------------------------------------

  /// Seals [rumor] at [plane] and signs the wrap. Returns the publishable
  /// wrap and queues it in the outbox.
  Future<Nip01Event> publishRumor({
    required String communityId,
    required Nip01Event rumor,
    required PlaneKeys plane,
    required SealForm form,
  }) async {
    final wrapped = await StreamEnvelope.wrapRumor(
      rumor: rumor,
      keys: plane,
      form: form,
      signSeal: signer.sign,
    );
    await store.appendRumor(communityId, rumor);
    await store.enqueueWrap(communityId, wrapped.event);
    return wrapped.event;
  }

  /// Unwraps an incoming event at a plane, then appends the rumor to the
  /// store. Returns the rumor, or null when it does not decrypt/verify.
  Future<Nip01Event?> openAndStore({
    required CommunityKeys keys,
    required String streamAddress,
    required Uint8List convKey,
    required Nip01Event wrap,
    SealForm? form,
    bool ephemeral = false,
  }) async {
    final Nip01Event rumor;
    try {
      final opened = await StreamEnvelope.unwrap(
        wrap: wrap,
        expectedStreamPk: streamAddress,
        convKey: convKey,
        expectedForm: form,
        ephemeral: ephemeral,
      );
      rumor = opened.rumor;
    } catch (_) {
      return null;
    }
    await store.appendRumor(keys.communityId, rumor);
    return rumor;
  }

  // --- chat -----------------------------------------------------------------

  /// Sends a Chat Plane rumor (CORD-02 §5). [kind] defaults to a message.
  Future<Nip01Event> sendChat({
    required CommunityKeys keys,
    required String channelId,
    required String content,
    int kind = RumorKinds.message,
    String? target,
    List<List<String>> extraTags = const [],
    int? createdAt,
    int? ms,
  }) {
    final channel = keys.channels[channelId];
    final epoch = channel?.epoch ?? keys.rootEpoch;
    final rumor = StreamEnvelope.makeRumor(
      pubkey: signer.getPublicKey(),
      kind: kind,
      content: content,
      createdAt: createdAt,
      tags: [
        ['channel', channelId],
        ['epoch', decimalTag(epoch)],
        [Millis.tag, decimalTag(ms ?? DateTime.now().millisecond)],
        if (target != null) ['e', target],
        ...extraTags,
      ],
    );
    return publishRumor(
      communityId: keys.communityId,
      rumor: rumor,
      plane: PlaneKeys.fromGroupKey(Planes.channelKey(keys, channelId)),
      form: SealForm.encrypted,
    );
  }

  // --- guestbook ------------------------------------------------------------

  /// Broadcasts a Join or Leave (CORD-02 §5).
  Future<Nip01Event> sendGuestbookVerb({
    required CommunityKeys keys,
    required String verb,
    String? inviteCreator,
    String? inviteLabel,
    int? createdAt,
    int? ms,
  }) {
    assert(verb == 'join' || verb == 'leave');
    final rumor = StreamEnvelope.makeRumor(
      pubkey: signer.getPublicKey(),
      kind: RumorKinds.joinLeave,
      content: verb,
      createdAt: createdAt,
      tags: [
        [Millis.tag, decimalTag(ms ?? DateTime.now().millisecond)],
        if (inviteCreator != null) ['invite', inviteCreator, inviteLabel ?? ''],
      ],
    );
    return publishRumor(
      communityId: keys.communityId,
      rumor: rumor,
      plane: PlaneKeys.fromGroupKey(Planes.guestbookKey(keys)),
      form: SealForm.encrypted,
    );
  }

  /// Signs and sends a Kick (kind 3309).
  Future<Nip01Event> sendKick({
    required CommunityKeys keys,
    required String target,
    String? vacEid,
    int? vacVersion,
    String? vacHash,
    int? createdAt,
    int? ms,
  }) {
    final rumor = StreamEnvelope.makeRumor(
      pubkey: signer.getPublicKey(),
      kind: RumorKinds.kick,
      content: '',
      createdAt: createdAt,
      tags: [
        ['p', target],
        [Millis.tag, decimalTag(ms ?? DateTime.now().millisecond)],
        if (vacEid != null) ['vac', vacEid, decimalTag(vacVersion!), vacHash!],
      ],
    );
    return publishRumor(
      communityId: keys.communityId,
      rumor: rumor,
      plane: PlaneKeys.fromGroupKey(Planes.guestbookKey(keys)),
      form: SealForm.encrypted,
    );
  }

  // --- control --------------------------------------------------------------

  /// Publishes a Control edition (CORD-04). Only staff (holders of
  /// `control_root`) can wrap at the Control address; this throws for a
  /// plain member.
  Future<Nip01Event> sendControlEdition({
    required CommunityKeys keys,
    required int vsk,
    required String eid,
    required String content,
    String? prev,
    int? version,
    int? createdAt,
    int? ms,
  }) {
    final rumor = ControlEdition.buildRumor(
      author: signer.getPublicKey(),
      vsk: vsk,
      eid: eid,
      version: version ?? 1,
      content: content,
      prev: prev,
      createdAt: createdAt,
      ms: ms,
    );
    return publishRumor(
      communityId: keys.communityId,
      rumor: rumor,
      plane: Planes.controlWriteKeys(keys),
      form: SealForm.plaintext,
    );
  }

  // --- rekeys ---------------------------------------------------------------

  /// Rotates a Private Channel's key (CORD-06 §1), wrapping a 72-byte blob
  /// per recipient at the next Channel-epoch rekey address. Returns the
  /// pending wraps, oldest chunk first.
  Future<List<Nip01Event>> rotateChannel({
    required CommunityKeys keys,
    required String channelId,
    required Uint8List newKey,
    required List<String> recipients,
    required int newEpoch,
    int? createdAt,
  }) async {
    final channel = keys.channels[channelId]!;
    final events = await Rekeys.buildChannelRotation(
      rotator: signer,
      scopeId: hexToBytes(channelId),
      newEpoch: newEpoch,
      prevEpoch: channel.epoch,
      prevKey: channel.key!,
      newKey: newKey,
      recipients: recipients,
      createdAt: createdAt,
    );
    // Wrap at the new epoch's rekey address (CORD-06 §2).
    final plane = PlaneKeys.fromGroupKey(
      groupKey(
        secret: keys.communityRoot,
        label: Labels.rekeyPseudonym,
        id: hexToBytes(channelId),
        epoch: newEpoch,
      ),
    );
    return _wrapRekeyEvents(keys, events, plane);
  }

  /// Rolls the base keys at a Refounding (CORD-06 §3): a 104-byte blob for
  /// members, 136 for staff.
  Future<List<Nip01Event>> refound({
    required CommunityKeys keys,
    required Uint8List newRoot,
    required Uint8List newControlRoot,
    required int newEpoch,
    required List<String> members,
    required Set<String> staff,
    int? createdAt,
  }) async {
    final newControlPk = hexToBytes(
      Planes.controlSignerPk(
        controlRoot: newControlRoot,
        communityId: keys.communityId,
        epoch: newEpoch,
      ),
    );
    final events = await Rekeys.buildBaseRotation(
      rotator: signer,
      newEpoch: newEpoch,
      prevEpoch: keys.rootEpoch,
      prevRoot: keys.communityRoot,
      newRoot: newRoot,
      newControlPk: newControlPk,
      newControlRoot: newControlRoot,
      members: members,
      staffRecipients: staff,
      createdAt: createdAt,
    );
    // Wrap at the root's next-epoch base rekey address (CORD-06 §2).
    final plane = PlaneKeys.fromGroupKey(
      groupKey(
        secret: keys.communityRoot,
        label: Labels.baseRekeyPseudonym,
        id: hexToBytes(keys.communityId),
        epoch: newEpoch,
      ),
    );
    return _wrapRekeyEvents(keys, events, plane);
  }

  Future<List<Nip01Event>> _wrapRekeyEvents(
    CommunityKeys keys,
    List<RekeyEvent> events,
    PlaneKeys plane,
  ) async {
    final wraps = <Nip01Event>[];
    for (final event in events) {
      wraps.add(
        await publishRumor(
          communityId: keys.communityId,
          rumor: event.rumor,
          plane: plane,
          form: SealForm.encrypted,
        ),
      );
    }
    return wraps;
  }

  // --- folding --------------------------------------------------------------

  /// Rebuilds the whole folded view of a Community from the store: the
  /// Control Plane fold (metadata, channels, roster, banlist), the Guestbook
  /// fold (the Complete Memberlist) and one Chat fold per channel-epoch.
  Future<ConcordCommunity> openCommunity(
    CommunityKeys keys, {
    bool allowReanchor = true,
    int? nowSeconds,
  }) async {
    final now = nowSeconds ?? DateTime.now().millisecondsSinceEpoch ~/ 1000;

    final controlFold = ControlFold(owner: keys.owner);
    final guestbookRumors = <Nip01Event>[];
    final chatRumors = <Nip01Event>[];

    for (final rumor in await store.rumors(keys.communityId)) {
      if (rumor.kind == RumorKinds.controlEdition) {
        controlFold.ingestRumor(rumor);
      } else if (_isGuestbook(rumor.kind)) {
        guestbookRumors.add(rumor);
      } else {
        chatRumors.add(rumor);
      }
    }

    final control = controlFold.build(allowReanchor: allowReanchor);

    final guestbookFold = GuestbookFold(
      owner: keys.owner,
      roster: control.roster,
    );
    for (final rumor in guestbookRumors) {
      guestbookFold.ingest(rumor, nowSeconds: now);
    }

    final chats = <String, ChatChannelFold>{};
    final banned = control.banlist.toSet();
    for (final rumor in chatRumors) {
      final message = ChatMessage.tryParse(rumor);
      if (message == null) continue;
      final channelId = message.channelId;
      final epochTag = message.epochTag;
      if (channelId == null || epochTag == null) continue;
      final epoch = tryParseDecimal(epochTag);
      if (epoch == null) continue;
      final fold = chats.putIfAbsent(
        '$channelId/$epoch',
        () => ChatChannelFold(channelId: channelId, epoch: epoch),
      );
      fold.ingest(rumor, isBanned: banned.contains, nowSeconds: now);
    }

    return ConcordCommunity(
      keys: keys,
      control: control,
      guestbook: guestbookFold.fold(banned: banned),
      chats: chats,
    );
  }

  static bool _isGuestbook(int kind) =>
      kind == RumorKinds.joinLeave ||
      kind == RumorKinds.kick ||
      kind == RumorKinds.snapshot;

  static Uint8List _random32() =>
      Uint8List.fromList(List.generate(32, (_) => _random.nextInt(256)));

  static List<InviteChannel> _channelsOf(CommunityKeys keys) => [
    for (final c in keys.channels.values)
      InviteChannel(
        id: c.channelId,
        key: c.private ? bytesToHex(c.key!) : null,
        epoch: c.epoch,
      ),
  ];
}
