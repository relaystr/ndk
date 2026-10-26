import 'package:concord/src/core/concord_constants.dart';
import 'package:concord/src/core/permissions.dart';
import 'package:concord/src/guestbook/guestbook.dart';
import 'package:concord/src/model/role.dart';
import 'package:concord/src/roster/roster.dart';
import 'package:concord/src/stream/stream_envelope.dart';
import 'package:ndk/domain_layer/entities/nip_01_event.dart';
import 'package:ndk/shared/nips/nip01/bip340.dart';
import 'package:test/test.dart';

import '../support/concord_test_support.dart';

void main() {
  final owner = Bip340.generatePrivateKey();
  final mod = Bip340.generatePrivateKey();
  final member = Bip340.generatePrivateKey();
  final stranger = Bip340.generatePrivateKey();
  const now = 1700000000;

  final roster = Roster(
    owner: owner.publicKey,
    roles: {
      'mod-role': Role(
        roleId: hex32(0x0a),
        name: 'Moderator',
        position: 5,
        permissions: Permissions.kick | Permissions.ban,
        scope: const RoleScope.server(),
      ),
    },
    grants: {
      mod.publicKey: Grant(
        member: mod.publicKey,
        roleIds: ['mod-role'],
        version: 1,
        hash: hex32(0xbb),
      ),
    },
  );

  Nip01Event verb(
    String author,
    String content, {
    int at = now,
    List<List<String>> extra = const [],
  }) => StreamEnvelope.makeRumor(
    pubkey: author,
    kind: RumorKinds.joinLeave,
    content: content,
    createdAt: at,
    tags: [
      ['ms', '0'],
      ...extra,
    ],
  );

  Nip01Event kick(String author, String target, {int at = now}) =>
      StreamEnvelope.makeRumor(
        pubkey: author,
        kind: RumorKinds.kick,
        content: '',
        createdAt: at,
        tags: [
          ['p', target],
          ['ms', '0'],
        ],
      );

  Nip01Event snapshot(
    String author,
    List<String> members, {
    String snapId =
        'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc',
    int part = 0,
    int total = 1,
    int at = now,
  }) => StreamEnvelope.makeRumor(
    pubkey: author,
    kind: RumorKinds.snapshot,
    content: '["${members.join('","')}"]',
    createdAt: at,
    tags: [
      ['snap', snapId, '$part', '$total'],
      ['ms', '0'],
    ],
  );

  GuestbookFold fold() => GuestbookFold(owner: owner.publicKey, roster: roster);

  group('verbs (CORD-02 §5)', () {
    test('a Join makes a member present', () {
      final f = fold();
      expect(f.ingest(verb(member.publicKey, 'join'), nowSeconds: now), isTrue);
      final state = f.fold(banned: {});
      expect(state.members, contains(member.publicKey));
    });

    test('a Leave after a Join removes presence; a newer Join restores it', () {
      final f = fold();
      f.ingest(verb(member.publicKey, 'join'), nowSeconds: now);
      f.ingest(
        verb(member.publicKey, 'leave', at: now + 5),
        nowSeconds: now + 5,
      );
      expect(f.fold(banned: {}).members, isNot(contains(member.publicKey)));
      f.ingest(
        verb(member.publicKey, 'join', at: now + 10),
        nowSeconds: now + 10,
      );
      expect(f.fold(banned: {}).members, contains(member.publicKey));
    });

    test('an unknown verb is refused', () {
      final f = fold();
      expect(
        f.ingest(verb(member.publicKey, 'lurk'), nowSeconds: now),
        isFalse,
      );
    });
  });

  group('the one-hour future bound', () {
    test('an entry more than an hour ahead is dropped', () {
      final f = fold();
      expect(
        f.ingest(
          verb(member.publicKey, 'join', at: now + 3601),
          nowSeconds: now,
        ),
        isFalse,
      );
    });

    test('an entry just inside the bound is accepted', () {
      final f = fold();
      expect(
        f.ingest(
          verb(member.publicKey, 'join', at: now + 3600),
          nowSeconds: now,
        ),
        isTrue,
      );
    });
  });

  group('kicks (CORD-04 authority)', () {
    test('an authorized kick removes the target', () {
      final f = fold();
      f.ingest(verb(member.publicKey, 'join'), nowSeconds: now);
      expect(
        f.ingest(
          kick(mod.publicKey, member.publicKey, at: now + 1),
          nowSeconds: now + 1,
        ),
        isTrue,
      );
      expect(f.fold(banned: {}).members, isNot(contains(member.publicKey)));
    });

    test('a kick by a roleless member is refused', () {
      final f = fold();
      f.ingest(verb(member.publicKey, 'join'), nowSeconds: now);
      expect(
        f.ingest(
          kick(stranger.publicKey, member.publicKey, at: now + 1),
          nowSeconds: now + 1,
        ),
        isFalse,
      );
      expect(f.fold(banned: {}).members, contains(member.publicKey));
    });

    test('a kick against the owner is refused even for staff', () {
      final f = fold();
      expect(
        f.ingest(
          kick(mod.publicKey, owner.publicKey, at: now + 1),
          nowSeconds: now + 1,
        ),
        isFalse,
      );
      expect(f.fold(banned: {}).members, contains(owner.publicKey));
    });

    test('the owner may kick anyone', () {
      final f = fold();
      f.ingest(verb(mod.publicKey, 'join'), nowSeconds: now);
      expect(
        f.ingest(
          kick(owner.publicKey, mod.publicKey, at: now + 1),
          nowSeconds: now + 1,
        ),
        isTrue,
      );
      expect(f.fold(banned: {}).members, isNot(contains(mod.publicKey)));
    });
  });

  group('snapshots (seeding)', () {
    test('a snapshot seeds present members', () {
      final f = fold();
      expect(
        f.ingest(
          snapshot(owner.publicKey, [member.publicKey, mod.publicKey]),
          nowSeconds: now,
        ),
        isTrue,
      );
      final state = f.fold(banned: {});
      expect(state.members, contains(member.publicKey));
      expect(state.members, contains(mod.publicKey));
    });

    test('a later Leave still beats an earlier snapshot seed', () {
      final f = fold();
      f.ingest(snapshot(owner.publicKey, [member.publicKey]), nowSeconds: now);
      f.ingest(
        verb(member.publicKey, 'leave', at: now + 5),
        nowSeconds: now + 5,
      );
      expect(f.fold(banned: {}).members, isNot(contains(member.publicKey)));
    });
  });

  group('observation (CORD-02 §5)', () {
    test('an observed author counts as present', () {
      final f = fold();
      f.observe(member.publicKey, now);
      expect(f.fold(banned: {}).members, contains(member.publicKey));
    });

    test('a kick newer than observation wins', () {
      final f = fold();
      f.observe(member.publicKey, now);
      f.ingest(
        kick(mod.publicKey, member.publicKey, at: now + 5),
        nowSeconds: now + 5,
      );
      expect(f.fold(banned: {}).members, isNot(contains(member.publicKey)));
    });
  });

  group('banlist', () {
    test('a banned member never appears', () {
      final f = fold();
      f.ingest(verb(member.publicKey, 'join'), nowSeconds: now);
      expect(
        f.fold(banned: {member.publicKey}).members,
        isNot(contains(member.publicKey)),
      );
    });

    test('the owner survives even if listed (never banned)', () {
      final f = fold();
      expect(
        f.fold(banned: {owner.publicKey}).members,
        contains(owner.publicKey),
      );
    });
  });

  group('parsing', () {
    test('a malformed kick without a target is refused', () {
      final bad = StreamEnvelope.makeRumor(
        pubkey: mod.publicKey,
        kind: RumorKinds.kick,
        content: '',
        createdAt: now,
        tags: const [
          ['ms', '0'],
        ],
      );
      expect(GuestbookEvent.tryParseAny(bad), isNull);
    });

    test('a snapshot chunk references its part and total', () {
      final event = GuestbookEvent.tryParseAny(
        snapshot(owner.publicKey, [member.publicKey], part: 0, total: 2),
      );
      expect(event, isA<GuestbookSnapshot>());
      expect((event as GuestbookSnapshot).total, 2);
    });
  });
}
