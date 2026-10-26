import 'package:concord/src/control/control_edition.dart';
import 'package:concord/src/control/control_fold.dart';
import 'package:concord/src/core/derivations.dart';
import 'package:concord/src/core/encoding.dart';
import 'package:concord/src/core/permissions.dart';
import 'package:concord/src/model/metadata.dart';
import 'package:concord/src/model/role.dart';
import 'package:concord/src/roster/roster.dart';
import 'package:test/test.dart';

String hex32(int fill) =>
    List.generate(32, (i) => fill.toRadixString(16).padLeft(2, '0')).join();

/// Builds and parses an edition rumor, exercising the parse path too.
ControlEdition edition({
  required String author,
  required int vsk,
  required String eid,
  required int version,
  required String content,
  String? prev,
  String? vacEid,
  int? vacVersion,
  String? vacHash,
  int createdAt = 1700000000,
  int ms = 0,
}) {
  final rumor = ControlEdition.buildRumor(
    author: author,
    vsk: vsk,
    eid: eid,
    version: version,
    content: content,
    prev: prev,
    vacEid: vacEid,
    vacVersion: vacVersion,
    vacHash: vacHash,
    createdAt: createdAt,
    ms: ms,
  );
  final parsed = ControlEdition.tryParse(rumor);
  if (parsed == null) throw StateError('edition failed to parse');
  return parsed;
}

Role roleEntity(String roleId, int position, int perms) => Role(
  roleId: roleId,
  name: 'role-$position',
  position: position,
  permissions: perms,
  scope: const RoleScope.server(),
);

void main() {
  final owner = hex32(0x01);
  final alice = hex32(0x0a);
  final bob = hex32(0x0b);
  final cid = hex32(0xcc);

  // Deterministic coordinates for roles/grants we use throughout.
  final rAdmin = hex32(0x21);
  final rMod = hex32(0x22);

  group('owner-rooted bootstrap', () {
    test('owner mints a role and grants it', () {
      final fold = ControlFold(owner: owner);

      // Role at position 1: MANAGE_ROLES | MANAGE_CHANNELS etc.
      fold.ingest(
        edition(
          author: owner,
          vsk: 1,
          eid: rAdmin,
          version: 1,
          content: roleEntity(
            rAdmin,
            1,
            Permissions.manageRoles,
          ).toContentJson(),
        ),
      );

      // Grant role to alice.
      final grantEid = Locators.grant(cid, alice);
      fold.ingest(
        edition(
          author: owner,
          vsk: 3,
          eid: grantEid,
          version: 1,
          content: Grant(member: alice, roleIds: [rAdmin]).toContentJson(),
        ),
      );

      final state = fold.build();
      expect(state.roster.roles.containsKey(rAdmin), isTrue);
      expect(state.roster.rankOf(alice), 1);
      expect(state.roster.holds(alice, Permissions.manageRoles), isTrue);
      expect(state.roster.rankOf(bob), Roster.rolelessRank);
    });

    test('no role may claim position 0', () {
      final fold = ControlFold(owner: owner);
      fold.ingest(
        edition(
          author: owner,
          vsk: 1,
          eid: rAdmin,
          version: 1,
          content: Role(
            roleId: rAdmin,
            name: 'owner',
            position: 0,
            permissions: Permissions.ownerPermissions,
            scope: const RoleScope.server(),
          ).toContentJson(),
        ),
      );
      final state = fold.build();
      expect(state.roster.roles.containsKey(rAdmin), isFalse);
    });
  });

  group('delegated authority', () {
    ControlFold bootstrap() {
      final fold = ControlFold(owner: owner);
      fold.ingest(
        edition(
          author: owner,
          vsk: 1,
          eid: rAdmin,
          version: 1,
          content: roleEntity(
            rAdmin,
            1,
            Permissions.manageRoles,
          ).toContentJson(),
        ),
      );
      fold.ingest(
        edition(
          author: owner,
          vsk: 3,
          eid: Locators.grant(cid, alice),
          version: 1,
          content: Grant(member: alice, roleIds: [rAdmin]).toContentJson(),
        ),
      );
      return fold;
    }

    test('an admin outranking a role may create it (deeper position)', () {
      final fold = bootstrap();
      fold.ingest(
        edition(
          author: alice,
          vsk: 1,
          eid: rMod,
          version: 1,
          content: roleEntity(rMod, 5, Permissions.kick).toContentJson(),
        ),
      );
      final state = fold.build();
      expect(state.roster.roles.containsKey(rMod), isTrue);
    });

    test('an admin may NOT create a role at or above their own position', () {
      final fold = bootstrap();
      fold.ingest(
        edition(
          author: alice,
          vsk: 1,
          eid: rMod,
          version: 1,
          content: roleEntity(rMod, 1, Permissions.kick).toContentJson(),
        ),
      );
      final state = fold.build();
      expect(state.roster.roles.containsKey(rMod), isFalse);
    });

    test('an admin may grant a role that ranks below them', () {
      final fold = bootstrap();
      fold.ingest(
        edition(
          author: alice,
          vsk: 1,
          eid: rMod,
          version: 1,
          content: roleEntity(rMod, 5, Permissions.kick).toContentJson(),
        ),
      );
      fold.ingest(
        edition(
          author: alice,
          vsk: 3,
          eid: Locators.grant(cid, bob),
          version: 1,
          content: Grant(member: bob, roleIds: [rMod]).toContentJson(),
        ),
      );
      final state = fold.build();
      expect(state.roster.rankOf(bob), 5);
    });

    test('an admin may not grant a role at or above their own position', () {
      final fold = bootstrap();
      fold.ingest(
        edition(
          author: alice,
          vsk: 3,
          eid: Locators.grant(cid, bob),
          version: 1,
          content: Grant(member: bob, roleIds: [rAdmin]).toContentJson(),
        ),
      );
      final state = fold.build();
      expect(state.roster.rankOf(bob), Roster.rolelessRank);
    });

    test('an unauthorized author (no MANAGE_ROLES) is dropped', () {
      final fold = bootstrap();
      // bob is roleless and tries to mint a role.
      fold.ingest(
        edition(
          author: bob,
          vsk: 1,
          eid: rMod,
          version: 1,
          content: roleEntity(rMod, 5, Permissions.kick).toContentJson(),
        ),
      );
      final state = fold.build();
      expect(state.roster.roles.containsKey(rMod), isFalse);
    });

    test('revoke removes authority and cascades', () {
      final fold = bootstrap();
      fold.ingest(
        edition(
          author: alice,
          vsk: 1,
          eid: rMod,
          version: 1,
          content: roleEntity(rMod, 5, Permissions.kick).toContentJson(),
        ),
      );
      fold.ingest(
        edition(
          author: alice,
          vsk: 3,
          eid: Locators.grant(cid, bob),
          version: 1,
          content: Grant(member: bob, roleIds: [rMod]).toContentJson(),
        ),
      );
      // Owner revokes alice: chained onto the grant's first edition.
      final aliceGrantV1 = edition(
        author: owner,
        vsk: 3,
        eid: Locators.grant(cid, alice),
        version: 1,
        content: Grant(member: alice, roleIds: [rAdmin]).toContentJson(),
      );
      fold.ingest(
        edition(
          author: owner,
          vsk: 3,
          eid: Locators.grant(cid, alice),
          version: 2,
          prev: aliceGrantV1.hash,
          content: Grant(member: alice, roleIds: const []).toContentJson(),
        ),
      );

      final state = fold.build();
      expect(state.roster.rankOf(alice), Roster.rolelessRank);
      // alice's downstream role and grant no longer resolve.
      expect(state.roster.roles.containsKey(rMod), isFalse);
      expect(state.roster.rankOf(bob), Roster.rolelessRank);
    });
  });

  group('chain discipline', () {
    test('a version with a wrong prev is a gap for a tracking client', () {
      final fold = ControlFold(owner: owner);
      final v1 = edition(
        author: owner,
        vsk: 0,
        eid: cid,
        version: 1,
        content: CommunityMetadata(name: 'V1').toContentJson(),
      );
      fold.ingest(v1);
      // Version 2 cites a hash we never saw.
      fold.ingest(
        edition(
          author: owner,
          vsk: 0,
          eid: cid,
          version: 2,
          prev: hex32(0x99),
          content: CommunityMetadata(name: 'V2').toContentJson(),
        ),
      );

      final tracking = fold.build(allowReanchor: false);
      expect(tracking.suspended.contains(cid), isTrue);
      // Fail closed: the entity is not trusted at all rather than silently
      // used at a lower version.
      expect(tracking.metadata, isNull);
    });

    test(
      'a fresh joiner re-anchors on the highest signature-verified head',
      () {
        final fold = ControlFold(owner: owner);
        fold.ingest(
          edition(
            author: owner,
            vsk: 0,
            eid: cid,
            version: 3,
            prev: hex32(0x99), // dangling: compaction dropped v1..v2
            content: CommunityMetadata(name: 'Refounded').toContentJson(),
          ),
        );
        final fresh = fold.build(allowReanchor: true);
        expect(fresh.metadata?.name, 'Refounded');
        expect(fresh.suspended, isEmpty);
      },
    );

    test('a correct chain resolves to the highest version', () {
      final fold = ControlFold(owner: owner);
      final v1 = edition(
        author: owner,
        vsk: 0,
        eid: cid,
        version: 1,
        content: CommunityMetadata(name: 'One').toContentJson(),
      );
      fold.ingest(v1);
      fold.ingest(
        edition(
          author: owner,
          vsk: 0,
          eid: cid,
          version: 2,
          prev: v1.hash,
          content: CommunityMetadata(name: 'Two').toContentJson(),
        ),
      );
      final state = fold.build();
      expect(state.metadata?.name, 'Two');
      expect(state.heads[cid]!.version, 2);
      expect(state.nextVersion(cid), 3);
      expect(state.prevHash(cid), state.heads[cid]!.hash);
    });

    test('a lower version never displaces a higher intact head', () {
      final fold = ControlFold(owner: owner);
      final v1 = edition(
        author: owner,
        vsk: 0,
        eid: cid,
        version: 1,
        content: CommunityMetadata(name: 'One').toContentJson(),
      );
      final v2 = edition(
        author: owner,
        vsk: 0,
        eid: cid,
        version: 2,
        prev: v1.hash,
        content: CommunityMetadata(name: 'Two').toContentJson(),
      );
      fold.ingest(v1);
      fold.ingest(v2);
      // A replayed v1 (even from another author) does not win.
      fold.ingest(
        edition(
          author: alice,
          vsk: 0,
          eid: cid,
          version: 1,
          content: CommunityMetadata(name: 'Replay').toContentJson(),
        ),
      );
      final state = fold.build();
      expect(state.metadata?.name, 'Two');
    });

    test('same-version ties break by authority, then lower rumor id', () {
      final fold = ControlFold(owner: owner);
      // Two competing v1 metadata editions: owner vs. a roleless member.
      fold.ingest(
        edition(
          author: alice,
          vsk: 0,
          eid: cid,
          version: 1,
          content: CommunityMetadata(name: 'FromAlice').toContentJson(),
        ),
      );
      fold.ingest(
        edition(
          author: owner,
          vsk: 0,
          eid: cid,
          version: 1,
          content: CommunityMetadata(name: 'FromOwner').toContentJson(),
        ),
      );
      final state = fold.build();
      expect(state.metadata?.name, 'FromOwner');
    });
  });

  group('banlist', () {
    test('a banned member\'s control editions are ignored', () {
      final fold = ControlFold(owner: owner);
      // alice (roleless) edits metadata — ignored once banned.
      fold.ingest(
        edition(
          author: owner,
          vsk: 0,
          eid: cid,
          version: 1,
          content: CommunityMetadata(name: 'Base').toContentJson(),
        ),
      );
      // Owner bans alice.
      final banEid = Locators.banlist(cid);
      fold.ingest(
        edition(
          author: owner,
          vsk: 4,
          eid: banEid,
          version: 1,
          content: encodeJson([alice]),
        ),
      );

      final state = fold.build();
      expect(state.banlist, contains(alice));
      expect(state.isBanned(alice), isTrue);
    });
  });

  group('vac block-until-synced', () {
    test('an edition citing a vac we do not hold is not honored', () {
      final fold = ControlFold(owner: owner);
      // alice claims authority via a grant we never received.
      fold.ingest(
        edition(
          author: alice,
          vsk: 1,
          eid: rMod,
          version: 1,
          vacEid: Locators.grant(cid, alice),
          vacVersion: 1,
          vacHash: hex32(0x55),
          content: roleEntity(rMod, 5, Permissions.kick).toContentJson(),
        ),
      );
      final state = fold.build();
      expect(state.roster.roles.containsKey(rMod), isFalse);
    });

    test('once the cited grant is held, the edition resolves', () {
      final fold = ControlFold(owner: owner);
      fold.ingest(
        edition(
          author: owner,
          vsk: 1,
          eid: rAdmin,
          version: 1,
          content: roleEntity(
            rAdmin,
            1,
            Permissions.manageRoles,
          ).toContentJson(),
        ),
      );
      final grantEid = Locators.grant(cid, alice);
      final grantEdition = edition(
        author: owner,
        vsk: 3,
        eid: grantEid,
        version: 1,
        content: Grant(member: alice, roleIds: [rAdmin]).toContentJson(),
      );
      fold.ingest(grantEdition);
      // Now alice cites her exact grant.
      fold.ingest(
        edition(
          author: alice,
          vsk: 1,
          eid: rMod,
          version: 1,
          vacEid: grantEid,
          vacVersion: 1,
          vacHash: grantEdition.hash,
          content: roleEntity(rMod, 5, Permissions.kick).toContentJson(),
        ),
      );
      final state = fold.build();
      expect(state.roster.roles.containsKey(rMod), isTrue);
    });
  });

  group('channels and metadata', () {
    test('owner creates a private channel', () {
      final fold = ControlFold(owner: owner);
      final channelId = hex32(0x77);
      fold.ingest(
        edition(
          author: owner,
          vsk: 2,
          eid: channelId,
          version: 1,
          content: ChannelMetadata(
            name: 'secret',
            private: true,
          ).toContentJson(),
        ),
      );
      final state = fold.build();
      expect(state.channels[channelId]?.name, 'secret');
      expect(state.channels[channelId]?.private, isTrue);
    });
  });
}
