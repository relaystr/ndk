import 'dart:io';

import 'package:ndk/domain_layer/repositories/wallets_repo.dart';
import 'package:ndk/ndk.dart';

import '../cli_accounts_store.dart';
import '../cli_command.dart';

/// `ndk accounts` - manage local identities.
///
/// Identities are persisted in plaintext at [CliAccountsStore.defaultPath].
/// See [CliAccountRecord] for the security trade-off.
class AccountsCliCommand implements CliCommand {
  @override
  String get name => 'accounts';

  @override
  String get description =>
      'Manage local identities (login, logout, list, switch, whoami)';

  @override
  String get usage => _help;

  static const String _help = '''ndk accounts <sub-command> [args]
Sub-commands:
  login nsec <hex|nsec>           Login with private key
  login npub <hex|npub>           Read-only login (public key)
  login bunker <bunkerUrl>        Connect to a NIP-46 bunker
  login generate [name]           Generate a fresh keypair and login
  logout [pubkey]                 Logout current (or specific) account
  list                            List persisted accounts
  switch <pubkey|npub>            Set the active account
  whoami                          Show the active account
Options:
  -h, --help                      Show this help
Environment:
  NDK_ACCOUNTS_FILE               Override store path (default ~/.ndk/accounts.json)''';

  @override
  Future<int> run(
    List<String> args,
    Ndk ndk,
    WalletsRepo walletsRepo,
    CliAccountsStore accountsStore,
  ) async {
    if (args.isEmpty || _isHelp(args.first)) {
      stdout.writeln(_help);
      return 0;
    }

    try {
      final sub = args.first.toLowerCase();
      final rest = args.sublist(1);
      switch (sub) {
        case 'login':
          return await _handleLogin(rest, ndk, accountsStore);
        case 'logout':
          return await _handleLogout(rest, ndk, accountsStore);
        case 'list':
          return _handleList(accountsStore);
        case 'switch':
          return await _handleSwitch(rest, ndk, accountsStore);
        case 'whoami':
          return _handleWhoami(ndk, accountsStore);
        default:
          stderr.writeln('Unknown accounts sub-command: "$sub"');
          stdout.writeln(_help);
          return 2;
      }
    } catch (e) {
      stderr.writeln('Accounts command failed: $e');
      return 1;
    }
  }

  // ---- login ---------------------------------------------------------------

  Future<int> _handleLogin(
    List<String> args,
    Ndk ndk,
    CliAccountsStore store,
  ) async {
    if (args.isEmpty || _isHelp(args.first)) {
      stdout
          .writeln('Usage: ndk accounts login <nsec|npub|bunker|generate> ...');
      return 0;
    }
    final kind = args.first.toLowerCase();
    final rest = args.sublist(1);
    switch (kind) {
      case 'nsec':
        return await _loginNsec(rest, ndk, store);
      case 'npub':
        return await _loginNpub(rest, ndk, store);
      case 'bunker':
        return await _loginBunker(rest, ndk, store);
      case 'generate':
        return await _loginGenerate(rest, ndk, store);
      default:
        stderr.writeln('Unknown login kind: "$kind"');
        return 2;
    }
  }

  Future<int> _loginNsec(
      List<String> args, Ndk ndk, CliAccountsStore store) async {
    if (args.isEmpty) {
      stderr.writeln('Usage: ndk accounts login nsec <hex|nsec>');
      return 2;
    }
    final privkey = _resolvePrivateKey(args.first);
    if (privkey == null) {
      stderr.writeln('Invalid private key: ${args.first}');
      return 2;
    }
    final pubkey = _derivePubkey(privkey);
    if (pubkey == null) {
      stderr.writeln('Failed to derive pubkey from private key');
      return 1;
    }
    _doLogin(
        ndk,
        pubkey,
        () => ndk.accounts.loginPrivateKey(
              pubkey: pubkey,
              privkey: privkey,
            ));
    store.upsert(
      CliAccountRecord(
        pubkey: pubkey,
        type: CliAccountType.privateKey,
        privkey: privkey,
      ),
      setDefault: true,
    );
    return await _persistAndAnnounce(store, pubkey, 'private-key');
  }

  Future<int> _loginNpub(
      List<String> args, Ndk ndk, CliAccountsStore store) async {
    if (args.isEmpty) {
      stderr.writeln('Usage: ndk accounts login npub <hex|npub>');
      return 2;
    }
    final pubkey = _resolvePubkey(args.first);
    if (pubkey == null) {
      stderr.writeln('Invalid public key: ${args.first}');
      return 2;
    }
    _doLogin(ndk, pubkey, () => ndk.accounts.loginPublicKey(pubkey: pubkey));
    store.upsert(
      CliAccountRecord(pubkey: pubkey, type: CliAccountType.publicKey),
      setDefault: true,
    );
    return await _persistAndAnnounce(store, pubkey, 'read-only');
  }

  Future<int> _loginBunker(
    List<String> args,
    Ndk ndk,
    CliAccountsStore store,
  ) async {
    if (args.isEmpty) {
      stderr.writeln('Usage: ndk accounts login bunker <bunkerUrl>');
      return 2;
    }
    final bunkerUrl = args.first;
    stdout.writeln(
        'Connecting to bunker... (auth URL will be printed if the bunker requires it)');
    final connection = await ndk.accounts.loginWithBunkerUrl(
      bunkerUrl: bunkerUrl,
      bunkers: ndk.bunkers,
      authCallback: (authUrl) {
        stdout.writeln('Bunker auth required. Open this URL in your signer:');
        stdout.writeln('  $authUrl');
      },
    );
    if (connection == null) {
      stderr.writeln('Bunker connection failed for: $bunkerUrl');
      return 1;
    }
    final pubkey = ndk.accounts.getPublicKey();
    if (pubkey == null) {
      stderr.writeln('Bunker connected but no pubkey returned');
      return 1;
    }
    store.upsert(
      CliAccountRecord(
        pubkey: pubkey,
        type: CliAccountType.bunker,
        bunker: connection.toJson(),
      ),
      setDefault: true,
    );
    return await _persistAndAnnounce(store, pubkey, 'bunker');
  }

  Future<int> _loginGenerate(
      List<String> args, Ndk ndk, CliAccountsStore store) async {
    final (privkey, pubkey) =
        (ndk.accounts.eventSignerFactory as Bip340EventSignerFactory)
            .generateKeyPair();
    ndk.accounts.loginPrivateKey(pubkey: pubkey, privkey: privkey);
    store.upsert(
      CliAccountRecord(
        pubkey: pubkey,
        type: CliAccountType.privateKey,
        privkey: privkey,
      ),
      setDefault: true,
    );
    stdout.writeln('Generated new keypair:');
    stdout.writeln('  npub: ${Nip19.encodePubKey(pubkey)}');
    stdout.writeln('  nsec: ${Nip19.encodePrivateKey(privkey)}');
    stdout.writeln(
        '  (nsec has been stored in plaintext at ${CliAccountsStore.defaultPath()})');
    return await _persistAndAnnounce(store, pubkey, 'private-key (generated)');
  }

  /// Login, but if the account already exists in the live `Accounts` map
  /// (e.g. restored at startup), just switch to it.
  void _doLogin(Ndk ndk, String pubkey, void Function() login) {
    if (ndk.accounts.hasAccount(pubkey)) {
      ndk.accounts.switchAccount(pubkey: pubkey);
    } else {
      login();
    }
  }
  // ---- logout --------------------------------------------------------------

  Future<int> _handleLogout(
    List<String> args,
    Ndk ndk,
    CliAccountsStore store,
  ) async {
    final target = args.isNotEmpty ? _resolvePubkey(args.first) : null;
    final pubkey = target ?? ndk.accounts.getPublicKey();
    if (pubkey == null) {
      stderr.writeln('No active account to logout.');
      return 1;
    }
    if (ndk.accounts.hasAccount(pubkey)) {
      ndk.accounts.removeAccount(pubkey: pubkey);
    }
    store.remove(pubkey);
    await store.save();
    stdout.writeln('Logged out and removed: ${Nip19.encodePubKey(pubkey)}');
    return 0;
  }

  // ---- list / switch / whoami ---------------------------------------------

  int _handleList(CliAccountsStore store) {
    if (store.records.isEmpty) {
      stdout.writeln(
          'No persisted accounts. Use "ndk accounts login ..." to add one.');
      return 0;
    }
    stdout.writeln('Accounts (${store.records.length}):');
    for (final r in store.records) {
      final npub = Nip19.encodePubKey(r.pubkey);
      final flag = r.pubkey == store.defaultPubkey ? ' [active]' : '';
      stdout.writeln('  $npub (${r.type.name})$flag');
      stdout.writeln('    hex: ${r.pubkey}');
      if (r.type == CliAccountType.bunker && r.bunker != null) {
        final relays = r.bunker!['relays'];
        stdout.writeln('    bunker relays: $relays');
      }
    }
    return 0;
  }

  Future<int> _handleSwitch(
      List<String> args, Ndk ndk, CliAccountsStore store) async {
    if (args.isEmpty) {
      stderr.writeln('Usage: ndk accounts switch <pubkey|npub>');
      return 2;
    }
    final pubkey = _resolvePubkey(args.first);
    if (pubkey == null) {
      stderr.writeln('Invalid pubkey: ${args.first}');
      return 2;
    }
    if (store.find(pubkey) == null) {
      stderr.writeln('Unknown account: ${Nip19.encodePubKey(pubkey)}');
      return 1;
    }
    store.setDefault(pubkey);
    if (ndk.accounts.hasAccount(pubkey)) {
      ndk.accounts.switchAccount(pubkey: pubkey);
    }
    return await _persistAndAnnounce(store, pubkey, 'switched');
  }

  int _handleWhoami(Ndk ndk, CliAccountsStore store) {
    final pubkey = ndk.accounts.getPublicKey();
    if (pubkey == null) {
      stdout.writeln('No active account.');
      return 0;
    }
    final account = ndk.accounts.getLoggedAccount();
    final record = store.find(pubkey);
    stdout.writeln('Active account:');
    stdout.writeln('  npub: ${Nip19.encodePubKey(pubkey)}');
    stdout.writeln('  hex:  $pubkey');
    stdout.writeln(
        '  type: ${record?.type.name ?? account?.type.name ?? 'unknown'}');
    stdout.writeln('  canSign: ${ndk.accounts.canSign}');
    return 0;
  }

  // ---- helpers -------------------------------------------------------------

  Future<int> _persistAndAnnounce(
    CliAccountsStore store,
    String pubkey,
    String label,
  ) async {
    try {
      await store.save();
    } catch (e) {
      stderr.writeln('warning: failed to persist accounts store: $e');
    }
    stdout.writeln('Active: ${Nip19.encodePubKey(pubkey)} ($label)');
    return 0;
  }

  String? _resolvePrivateKey(String value) {
    final t = value.trim();
    if (RegExp(r'^[0-9a-fA-F]{64}$').hasMatch(t)) return t.toLowerCase();
    if (Nip19.isPrivateKey(t)) {
      try {
        return Nip19.decode(t);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  String? _resolvePubkey(String value) {
    final t = value.trim();
    if (RegExp(r'^[0-9a-fA-F]{64}$').hasMatch(t)) return t.toLowerCase();
    if (Nip19.isPubkey(t)) {
      try {
        return Nip19.decode(t);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  String? _derivePubkey(String privkey) {
    try {
      return (Bip340EventSignerFactory().derivePublicKey(privkey));
    } catch (_) {
      return null;
    }
  }

  bool _isHelp(String value) {
    return value == 'help' || value == '--help' || value == '-h';
  }
}
