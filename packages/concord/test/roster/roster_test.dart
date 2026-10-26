import 'package:concord/src/core/permissions.dart';
import 'package:concord/src/model/role.dart';
import 'package:concord/src/roster/roster.dart';
import 'package:test/test.dart';

String hex32(int fill) =>
    List.generate(32, (i) => fill.toRadixString(16).padLeft(2, '0')).join();

void main() {
  final owner = hex32(0x00);
  final admin = hex32(0x11);
  final mod = hex32(0x22);
  final chat = hex32(0x33);

  Role role(String id, int position, int perms, {RoleScope? scope}) => Role(
    roleId: id,
    name: 'r$position',
    position: position,
    permissions: perms,
    scope: scope ?? const RoleScope.server(),
  );

  group('rank (CORD-04 §2/§5)', () {
    test('owner is 0; roleless is last', () {
      final roster = Roster(owner: owner);
      expect(roster.rankOf(owner), 0);
      expect(roster.rankOf(admin), Roster.rolelessRank);
    });

    test('rank is the lowest position among roles held', () {
      final roster = Roster(
        owner: owner,
        roles: {
          'a': role('a', 1, Permissions.manageRoles),
          'b': role('b', 5, Permissions.kick),
        },
        grants: {
          admin: Grant(member: admin, roleIds: const ['b', 'a']),
        },
      );
      expect(roster.rankOf(admin), 1);
    });

    test('unknown role ids in a grant are dropped', () {
      final roster = Roster(
        owner: owner,
        grants: {
          admin: Grant(member: admin, roleIds: const ['ghost']),
        },
      );
      expect(roster.rolesOf(admin), isEmpty);
      expect(roster.rankOf(admin), Roster.rolelessRank);
    });
  });

  group('permission union and scoping', () {
    test(
      'server roles apply everywhere; channel roles only in their channel',
      () {
        final roster = Roster(
          owner: owner,
          roles: {
            'srv': role('srv', 1, Permissions.kick),
            'c1': role(
              'c1',
              2,
              Permissions.manageMessages,
              scope: RoleScope.channel(hex32(0xaa)),
            ),
          },
          grants: {
            mod: Grant(member: mod, roleIds: const ['srv', 'c1']),
          },
        );
        expect(
          roster.holds(mod, Permissions.kick),
          isTrue,
        ); // server, any scope
        expect(
          roster.holds(mod, Permissions.kick, channelId: hex32(0xbb)),
          isTrue,
        );
        expect(
          roster.holds(mod, Permissions.manageMessages, channelId: hex32(0xaa)),
          isTrue,
        );
        expect(
          roster.holds(mod, Permissions.manageMessages, channelId: hex32(0xbb)),
          isFalse,
        );
        // Without a channel scope, channel roles do not count.
        expect(roster.holds(mod, Permissions.manageMessages), isFalse);
      },
    );

    test('owner holds every bit', () {
      final roster = Roster(owner: owner);
      expect(roster.holds(owner, Permissions.ban), isTrue);
      expect(roster.holds(owner, Permissions.mentionEveryone), isTrue);
    });
  });

  group('strict outranking (CORD-04 §5)', () {
    final roster = Roster(
      owner: owner,
      roles: {
        'a': role(
          'a',
          1,
          Permissions.kick | Permissions.ban | Permissions.manageRoles,
        ),
        'b': role('b', 5, Permissions.kick),
      },
      grants: {
        admin: Grant(member: admin, roleIds: const ['a']),
        mod: Grant(member: mod, roleIds: const ['b']),
        chat: Grant(member: chat, roleIds: const []),
      },
    );

    test('a higher rank may act on a lower one', () {
      expect(roster.can(admin, Permissions.kick, target: mod), isTrue);
    });

    test('equal rank can never act', () {
      final peer = hex32(0x44);
      final withPeer = roster.copyWith(
        grants: {
          ...roster.grants,
          peer: Grant(member: peer, roleIds: const ['a']),
        },
      );
      expect(withPeer.can(admin, Permissions.kick, target: peer), isFalse);
    });

    test('no one may act on the owner', () {
      expect(roster.can(admin, Permissions.kick, target: owner), isFalse);
      expect(roster.can(owner, Permissions.kick, target: owner), isFalse);
    });

    test('missing the bit blocks the action even when outranking', () {
      // mod outranks chat but holds only KICK; banning needs BAN.
      expect(roster.can(mod, Permissions.ban, target: chat), isFalse);
      expect(roster.can(mod, Permissions.kick, target: chat), isTrue);
    });

    test('roleless members hold nothing and rank last', () {
      expect(roster.can(chat, Permissions.kick, target: mod), isFalse);
      expect(roster.rankOf(chat), Roster.rolelessRank);
    });

    test('owner can act on anyone but themselves', () {
      expect(roster.can(owner, Permissions.ban, target: admin), isTrue);
    });
  });

  group('permission parsing and serialization (CORD-04 §3)', () {
    test('permissions serialize as decimal strings, never numbers', () {
      expect(Permissions.serialize(Permissions.kick), '8');
      expect(Permissions.serialize(0), '0');
      expect(Permissions.parse('8'), 8);
      // A JSON number is accepted on read but a string is what we write.
      expect(Permissions.parse(8), 8);
    });

    test('malformed permissions fail closed', () {
      expect(Permissions.parse('abc'), 0);
      expect(Permissions.parse('01'), 0); // leading zero: malformed
      expect(Permissions.parse(null), 0);
      expect(Permissions.parse(-1), 0);
      expect(Permissions.parse('1.5'), 0);
    });

    test('the staff set is exactly the six normative bits plus the owner', () {
      expect(
        Permissions.staffBits,
        Permissions.manageRoles |
            Permissions.manageChannels |
            Permissions.manageMetadata |
            Permissions.ban |
            Permissions.createInvite |
            Permissions.pinMessages,
      );
      expect(Permissions.isStaff(Permissions.createInvite), isTrue);
      expect(Permissions.isStaff(Permissions.kick), isFalse);
      // The retired bit is burned, never part of the staff set.
      expect(Permissions.staffBits & Permissions.retiredManageInvites, 0);
    });

    test('bit positions are frozen', () {
      expect(Permissions.manageRoles, 1);
      expect(Permissions.manageChannels, 2);
      expect(Permissions.manageMetadata, 4);
      expect(Permissions.kick, 8);
      expect(Permissions.ban, 16);
      expect(Permissions.manageMessages, 32);
      expect(Permissions.createInvite, 64);
      expect(Permissions.retiredManageInvites, 128);
      expect(Permissions.viewAuditLog, 256);
      expect(Permissions.mentionEveryone, 512);
      expect(Permissions.pinMessages, 1 << 11);
    });
  });
}
