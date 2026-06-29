import 'dart:convert';
import 'dart:io';

import 'package:ndk/domain_layer/repositories/wallets_repo.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk/shared/helpers/relay_helper.dart';
import 'package:ndk/shared/nips/nip19/nip19.dart' as nip19;

import '../cli_accounts_store.dart';
import '../cli_command.dart';

/// `ndk broadcast` - publish a signed event to relays.
///
/// Accepts pre-signed events (sent as-is) or unsigned events that are signed
/// with either `--privkey` or the active account from `ndk accounts login`.
class BroadcastCliCommand implements CliCommand {
  @override
  String get name => 'broadcast';

  @override
  String get description => 'Publish events to relays';

  @override
  String get usage => _help;

  static const String _help = '''ndk broadcast [options] <relay> [relay ...]
Event source (one required):
  --event <json>                 Inline event JSON
  --file <path>                  Read event JSON from file
  --stdin                        Read event JSON from stdin
  --kind <int> --content <text>  Build a text-note (kind 1) inline
  --kind <int> --content <text> --pubkey <hex|npub>
                                 Build an unsigned event with explicit pubkey
Signing:
  --privkey <hex|nsec>           Sign with this key (overrides active account)
  (none)                         Use the active account from "ndk accounts login"
Output control:
  --relay <url> (repeatable)     Target relays (also accepted positionally)
  --timeout <sec>                Per-event timeout (default 10)
  --consider-done <0..1>         Fraction of OKs to wait for (default 0.5)
  --no-cache                     Don't save event to local cache
  -h, --help                     Show this help''';

  @override
  Future<int> run(
    List<String> args,
    Ndk ndk,
    WalletsRepo walletsRepo,
    CliAccountsStore accountsStore,
  ) async {
    if (args.isEmpty || args.contains('-h') || args.contains('--help')) {
      stdout.writeln(_help);
      return 0;
    }

    final parsed = await _parseArgs(args);
    if (parsed.error != null) {
      stderr.writeln(parsed.error);
      stderr.writeln('Usage: ndk broadcast [options] <relay> [relay ...]');
      return 2;
    }

    // Build the event
    Nip01Event event;
    try {
      event = await _buildEvent(parsed, ndk);
    } catch (e) {
      stderr.writeln('Failed to build event: $e');
      return 2;
    }

    // Resolve signing strategy
    final eventSigner = _resolveSigner(ndk, parsed, event);
    if (eventSigner == null) {
      stderr.writeln(
          'Event is unsigned and no signer available. Pass --privkey or run "ndk accounts login".');
      return 2;
    }

    if (parsed.relays.isEmpty) {
      stderr.writeln('At least one relay URL is required.');
      return 2;
    }

    if (event.pubKey.isEmpty) {
      stderr.writeln('Event is missing a pubkey.');
      return 2;
    }

    stdout.writeln(
        'Broadcasting event ${event.id} to ${parsed.relays.length} relay(s)...');
    final response = ndk.broadcast.broadcast(
      nostrEvent: event,
      specificRelays: parsed.relays,
      customSigner: eventSigner.customSigner,
      timeout: Duration(seconds: parsed.timeoutSeconds),
      considerDonePercent: parsed.considerDonePercent,
      saveToCache: parsed.saveToCache,
    );

    final results = await response.broadcastDoneFuture;
    var okCount = 0;
    for (final r in results) {
      final status = r.broadcastSuccessful
          ? 'OK'
          : (r.okReceived ? 'REJECTED' : 'NO-RESPONSE');
      stdout.writeln(
          '  ${r.relayUrl}: $status ${r.msg.isEmpty ? "" : '(${r.msg})'}');
      if (r.broadcastSuccessful) okCount++;
    }
    stdout.writeln(
        'Done: $okCount/${results.length} relay(s) accepted the event.');
    return okCount == 0 ? 1 : 0;
  }

  Future<Nip01Event> _buildEvent(_BroadcastArgs parsed, Ndk ndk) async {
    if (parsed.eventJson != null) {
      final decoded = jsonDecode(parsed.eventJson!);
      if (decoded is! Map) {
        throw ArgumentError(
            'Event JSON must decode to an object, got ${decoded.runtimeType}');
      }
      return Nip01EventModel.fromJson(decoded.cast<String, dynamic>());
    }

    if (parsed.kind != null) {
      // Prefer explicit --pubkey, else fall back to active account.
      var pubKey = parsed.pubkey;
      pubKey ??= ndk.accounts.getPublicKey();
      pubKey ??= (parsed.privkey != null)
          ? _buildSigner(parsed.privkey!)?.publicKey
          : null;
      if (pubKey == null || pubKey.isEmpty) {
        throw ArgumentError(
            'Inline build requires --pubkey, an active account, or --privkey.');
      }
      return Nip01Event(
        pubKey: pubKey,
        kind: parsed.kind!,
        tags: parsed.tags,
        content: parsed.content ?? '',
      );
    }

    throw ArgumentError(
        'No event source. Use --event, --file, --stdin, or --kind + --content.');
  }

  _SignerResolution? _resolveSigner(
    Ndk ndk,
    _BroadcastArgs parsed,
    Nip01Event event,
  ) {
    // Pre-signed event: no signer needed at all.
    if (event.sig != null && event.sig!.isNotEmpty) {
      return _SignerResolution.none();
    }

    // Explicit private key
    if (parsed.privkey != null) {
      final signer = _buildSigner(parsed.privkey!);
      if (signer == null) return null;
      return _SignerResolution.custom(signer);
    }

    // Use the active account.
    if (ndk.accounts.canSign) {
      return _SignerResolution.useActiveAccount();
    }

    return null;
  }

  Bip340EventSigner? _buildSigner(String value) {
    final hex = _resolvePrivateKey(value);
    if (hex == null) return null;
    return Bip340EventSigner(
        privateKey: hex,
        publicKey: Bip340EventSignerFactory().derivePublicKey(hex));
  }

  String? _resolvePrivateKey(String value) {
    final t = value.trim();
    if (RegExp(r'^[0-9a-fA-F]{64}$').hasMatch(t)) return t.toLowerCase();
    if (nip19.Nip19.isPrivateKey(t)) {
      try {
        return nip19.Nip19.decode(t);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  // ---- arg parsing ---------------------------------------------------------

  Future<_BroadcastArgs> _parseArgs(List<String> args) async {
    final result = _BroadcastArgs();
    int i = 0;
    String? takeValue() {
      if (i + 1 >= args.length) return null;
      final v = args[i + 1];
      i += 2;
      return v;
    }

    while (i < args.length) {
      final raw = args[i];

      String flag;
      String? inline;
      final eq = raw.indexOf('=');
      if (eq > 0 && raw.startsWith('-')) {
        flag = raw.substring(0, eq);
        inline = raw.substring(eq + 1);
      } else {
        flag = raw;
        inline = null;
      }

      String? nextOrInline() {
        if (inline != null) {
          i += 1;
          return inline;
        }
        return takeValue();
      }

      if (flag == '--event') {
        final v = nextOrInline();
        if (v == null) {
          return _BroadcastArgs(error: 'Missing value for --event');
        }
        result.eventJson = v;
        continue;
      }
      if (flag == '--file') {
        final v = nextOrInline();
        if (v == null) {
          return _BroadcastArgs(error: 'Missing value for --file');
        }
        try {
          result.eventJson = File(v).readAsStringSync();
        } catch (e) {
          return _BroadcastArgs(error: 'Failed to read $v: $e');
        }
        continue;
      }
      if (flag == '--stdin') {
        if (!stdin.hasTerminal) {
          // piped stdin: read everything
          final body = await stdin.transform(utf8.decoder).join();
          result.eventJson = body;
        } else {
          // interactive: read a single line
          final line = stdin.readLineSync(encoding: utf8) ?? '';
          result.eventJson = line;
        }
        i += 1;
        continue;
      }
      if (flag == '--kind') {
        final v = nextOrInline();
        if (v == null) {
          return _BroadcastArgs(error: 'Missing value for --kind');
        }
        final k = int.tryParse(v);
        if (k == null) {
          return _BroadcastArgs(error: 'Invalid --kind "$v"');
        }
        result.kind = k;
        continue;
      }
      if (flag == '--content') {
        final v = nextOrInline();
        if (v == null) {
          return _BroadcastArgs(error: 'Missing value for --content');
        }
        result.content = v;
        continue;
      }
      if (flag == '--pubkey') {
        final v = nextOrInline();
        if (v == null) {
          return _BroadcastArgs(error: 'Missing value for --pubkey');
        }
        result.pubkey = _resolvePubkey(v) ?? v;
        continue;
      }
      if (flag == '--privkey') {
        final v = nextOrInline();
        if (v == null) {
          return _BroadcastArgs(error: 'Missing value for --privkey');
        }
        result.privkey = v;
        continue;
      }
      if (flag == '--relay') {
        final v = nextOrInline();
        if (v == null) {
          return _BroadcastArgs(error: 'Missing value for --relay');
        }
        final cleaned = cleanRelayUrl(v) ?? cleanRelayUrl('wss://$v');
        if (cleaned == null) {
          return _BroadcastArgs(error: 'Invalid relay URL: $v');
        }
        result.relays.add(cleaned);
        continue;
      }
      if (flag == '--timeout') {
        final v = nextOrInline();
        if (v == null) {
          return _BroadcastArgs(error: 'Missing value for --timeout');
        }
        final n = int.tryParse(v);
        if (n == null || n <= 0) {
          return _BroadcastArgs(error: 'Invalid --timeout "$v"');
        }
        result.timeoutSeconds = n;
        continue;
      }
      if (flag == '--consider-done') {
        final v = nextOrInline();
        if (v == null) {
          return _BroadcastArgs(error: 'Missing value for --consider-done');
        }
        final d = double.tryParse(v);
        if (d == null || d <= 0 || d > 1) {
          return _BroadcastArgs(
              error: 'Invalid --consider-done "$v" (must be 0 < x <= 1)');
        }
        result.considerDonePercent = d;
        continue;
      }
      if (flag == '--no-cache') {
        result.saveToCache = false;
        i += 1;
        continue;
      }
      if (flag == '-h' || flag == '--help') {
        // already handled by caller
        i += 1;
        continue;
      }
      if (flag.startsWith('-')) {
        return _BroadcastArgs(error: 'Unknown option: $flag');
      }
      // positional relay
      final cleaned = cleanRelayUrl(raw) ?? cleanRelayUrl('wss://$raw');
      if (cleaned == null) {
        return _BroadcastArgs(error: 'Invalid relay URL: $raw');
      }
      result.relays.add(cleaned);
      i += 1;
    }
    return result;
  }

  String? _resolvePubkey(String value) {
    final t = value.trim();
    if (RegExp(r'^[0-9a-fA-F]{64}$').hasMatch(t)) return t.toLowerCase();
    if (nip19.Nip19.isPubkey(t)) {
      try {
        return nip19.Nip19.decode(t);
      } catch (_) {
        return null;
      }
    }
    return null;
  }
}

class _BroadcastArgs {
  String? eventJson;
  int? kind;
  String? content;
  String? pubkey;
  List<List<String>> tags = const [];
  String? privkey;
  final List<String> relays = [];
  int timeoutSeconds = 10;
  double considerDonePercent = 0.5;
  bool saveToCache = true;
  String? error;

  _BroadcastArgs({this.error});
}

class _SignerResolution {
  /// Pass this signer as `customSigner`.
  final Bip340EventSigner? customSigner;

  /// True when the broadcast should rely on the active account (no customSigner).
  final bool useActiveAccount;

  const _SignerResolution._({this.customSigner, this.useActiveAccount = false});

  factory _SignerResolution.custom(Bip340EventSigner signer) =>
      _SignerResolution._(customSigner: signer);

  factory _SignerResolution.useActiveAccount() =>
      const _SignerResolution._(useActiveAccount: true);

  factory _SignerResolution.none() => const _SignerResolution._();
}
