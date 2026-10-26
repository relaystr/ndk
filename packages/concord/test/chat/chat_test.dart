import 'package:concord/src/chat/chat.dart';
import 'package:concord/src/core/concord_constants.dart';
import 'package:concord/src/core/derivations.dart';
import 'package:concord/src/core/encoding.dart';
import 'package:concord/src/keys/concord_keys.dart';
import 'package:concord/src/stream/stream_envelope.dart';
import 'package:ndk/domain_layer/entities/nip_01_event.dart';
import 'package:ndk/shared/nips/nip01/bip340.dart';
import 'package:test/test.dart';

import '../support/concord_test_support.dart';

CommunityKeys _keys() {
  final owner = Bip340.getPublicKey(bytesToHex(bytes32(0x01)));
  final salt = bytes32(0x02);
  final root = bytes32(0x03);
  return CommunityKeys(
    communityId: communityId(ownerXonly: owner, ownerSalt: salt),
    owner: owner,
    ownerSalt: salt,
    rootEpoch: 0,
    communityRoot: root,
    controlPk: '',
    controlEpoch: 0,
  );
}

void main() {
  final keys = _keys();
  final channelId = hex32(0x70);
  final channelPlane = Planes.channelKey(keys, channelId);
  final author = Bip340.generatePrivateKey();
  final other = Bip340.generatePrivateKey();
  const now = 1700000000;

  Future<Nip01Event> chatRumor({
    required String authorPk,
    required String channel,
    required String epoch,
    required String content,
    int kind = RumorKinds.message,
    List<List<String>> extraTags = const [],
    int createdAt = now,
    int ms = 0,
    int? expiration,
    String? sk,
  }) async {
    final rumor = StreamEnvelope.makeRumor(
      pubkey: authorPk,
      kind: kind,
      content: content,
      createdAt: createdAt,
      tags: [
        ['channel', channel],
        ['epoch', epoch],
        ['ms', '$ms'],
        if (expiration != null) ['expiration', '$expiration'],
        ...extraTags,
      ],
    );
    return rumor;
  }

  ChatChannelFold fold() => ChatChannelFold(channelId: channelId, epoch: 0);

  group('binding (CORD-01)', () {
    test(
      'a message bound to the opened channel and epoch is accepted',
      () async {
        final f = fold();
        final rumor = await chatRumor(
          authorPk: author.publicKey,
          channel: channelId,
          epoch: '0',
          content: 'hello',
        );
        expect(
          f.ingest(rumor, isBanned: (_) => false, nowSeconds: now),
          isTrue,
        );
        expect(f.messages(), hasLength(1));
        expect(f.messages().first.content, 'hello');
      },
    );

    test('a mismatched channel tag is refused', () async {
      final f = fold();
      final rumor = await chatRumor(
        authorPk: author.publicKey,
        channel: hex32(0x71),
        epoch: '0',
        content: 'smuggled',
      );
      expect(f.ingest(rumor, isBanned: (_) => false, nowSeconds: now), isFalse);
      expect(f.messages(), isEmpty);
    });

    test('a mismatched epoch tag is refused', () async {
      final f = fold();
      final rumor = await chatRumor(
        authorPk: author.publicKey,
        channel: channelId,
        epoch: '1',
        content: 'future',
      );
      expect(f.ingest(rumor, isBanned: (_) => false, nowSeconds: now), isFalse);
    });

    test('a malformed ms tag drops the entry (never interpreted)', () async {
      final f = fold();
      final rumor = Nip01Event(
        pubKey: author.publicKey,
        kind: RumorKinds.message,
        content: 'x',
        createdAt: now,
        tags: [
          ['channel', channelId],
          ['epoch', '0'],
          ['ms', '1000'], // out of range
        ],
      );
      expect(f.ingest(rumor, isBanned: (_) => false, nowSeconds: now), isFalse);
    });
  });

  group('moderation and time', () {
    test('a banned author is dropped', () async {
      final f = fold();
      final rumor = await chatRumor(
        authorPk: author.publicKey,
        channel: channelId,
        epoch: '0',
        content: 'spam',
      );
      expect(
        f.ingest(
          rumor,
          isBanned: (a) => a == author.publicKey,
          nowSeconds: now,
        ),
        isFalse,
      );
    });

    test(
      'an already-expired rumor is refused at ingest (CORD-08 §3)',
      () async {
        final f = fold();
        final rumor = await chatRumor(
          authorPk: author.publicKey,
          channel: channelId,
          epoch: '0',
          content: 'ephemeral',
          expiration: now - 1,
        );
        expect(
          f.ingest(rumor, isBanned: (_) => false, nowSeconds: now),
          isFalse,
        );
      },
    );
  });

  group('ordering and edits', () {
    test('messages order by true ms time then lower rumor id', () async {
      final f = fold();
      final a = await chatRumor(
        authorPk: author.publicKey,
        channel: channelId,
        epoch: '0',
        content: 'a',
        createdAt: now,
        ms: 500,
      );
      final b = await chatRumor(
        authorPk: other.publicKey,
        channel: channelId,
        epoch: '0',
        content: 'b',
        createdAt: now,
        ms: 100,
      );
      f.ingest(a, isBanned: (_) => false, nowSeconds: now);
      f.ingest(b, isBanned: (_) => false, nowSeconds: now);
      expect(f.messages().map((m) => m.content).toList(), ['b', 'a']);
    });

    test('a delete removes its target', () async {
      final f = fold();
      final msg = await chatRumor(
        authorPk: author.publicKey,
        channel: channelId,
        epoch: '0',
        content: 'regret',
      );
      f.ingest(msg, isBanned: (_) => false, nowSeconds: now);
      final del = await chatRumor(
        authorPk: author.publicKey,
        channel: channelId,
        epoch: '0',
        content: '',
        kind: RumorKinds.delete,
        extraTags: [
          ['e', msg.id],
        ],
        ms: 1,
      );
      f.ingest(del, isBanned: (_) => false, nowSeconds: now);
      expect(f.messages(), isEmpty);
    });

    test('an edit supersedes the content', () async {
      final f = fold();
      final msg = await chatRumor(
        authorPk: author.publicKey,
        channel: channelId,
        epoch: '0',
        content: 'typo',
      );
      f.ingest(msg, isBanned: (_) => false, nowSeconds: now);
      final edit = await chatRumor(
        authorPk: author.publicKey,
        channel: channelId,
        epoch: '0',
        content: 'fixed',
        kind: RumorKinds.edit,
        extraTags: [
          ['e', msg.id],
        ],
        ms: 5,
      );
      f.ingest(edit, isBanned: (_) => false, nowSeconds: now);
      expect(f.editedContent(msg.id), 'fixed');
    });

    test('reactions count by emoji', () async {
      final f = fold();
      final msg = await chatRumor(
        authorPk: author.publicKey,
        channel: channelId,
        epoch: '0',
        content: 'nice',
      );
      f.ingest(msg, isBanned: (_) => false, nowSeconds: now);
      for (final who in [author, other]) {
        final reaction = await chatRumor(
          authorPk: who.publicKey,
          channel: channelId,
          epoch: '0',
          content: '👍',
          kind: RumorKinds.reaction,
          extraTags: [
            ['e', msg.id],
          ],
          ms: 2,
        );
        f.ingest(reaction, isBanned: (_) => false, nowSeconds: now);
      }
      expect(f.reactions(msg.id), {'👍': 2});
    });
  });

  group('end-to-end through the stream envelope', () {
    test('a wrapped chat message opens and folds', () async {
      final f = fold();
      final rumor = await chatRumor(
        authorPk: author.publicKey,
        channel: channelId,
        epoch: '0',
        content: 'encrypted hello',
      );
      final wrapped = await StreamEnvelope.wrapRumor(
        rumor: rumor,
        keys: PlaneKeys.fromGroupKey(channelPlane),
        form: SealForm.encrypted,
        signSeal: (seal) => signWithLocalKey(seal, author.privateKey!),
      );
      final opened = await StreamEnvelope.unwrap(
        wrap: wrapped.event,
        expectedStreamPk: channelPlane.pk,
        convKey: channelPlane.convKey,
        expectedForm: SealForm.encrypted,
      );
      expect(
        f.ingest(opened.rumor, isBanned: (_) => false, nowSeconds: now),
        isTrue,
      );
      expect(f.messages().first.content, 'encrypted hello');
    });
  });
}
