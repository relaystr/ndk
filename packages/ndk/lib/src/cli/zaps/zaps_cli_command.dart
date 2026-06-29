import 'dart:io';

import 'package:ndk/domain_layer/repositories/wallets_repo.dart';
import 'package:ndk/entities.dart';
import 'package:ndk/ndk.dart';

import '../cli_accounts_store.dart';
import '../cli_command.dart';

/// `ndk zaps` - NIP-57 zap operations.
///
/// - `invoice`  fetch a lightning/zap invoice (no payment)
/// - `zap`      pay a zap from a stored NWC sending wallet
/// - `receipts` list zap receipts for a recipient pubkey
class ZapsCliCommand implements CliCommand {
  @override
  String get name => 'zaps';

  @override
  String get description => 'Zap operations (invoice, zap, receipts)';

  @override
  String get usage => _help;

  static const String _help = '''ndk zaps <sub-command> [args]
Sub-commands:
  invoice <lud16> <amountSats> [options]
                                  Fetch a zap/lightning invoice (no payment)
  zap <lud16> <amountSats> [options]
                                  Pay a zap using the default NWC sending wallet
  receipts <pubkey> [options]     List zap receipts (kind 9735) for a recipient
Options (common):
  --wallet <walletId>             Override the NWC wallet to use (zap)
  --comment <text>                Zap comment / invoice memo
  --pubkey <hex|npub>             Recipient pubkey (enables true zap encoding)
  --event <id|nevent>             Zap a specific event
  --addressable <aTag>            Zap an addressable event (naddr)
  --relays <url> (repeatable)     Relays to attach to the zap request
  --no-zap                        invoice: force plain LN invoice (skip zap encoding)
  --no-receipt                    zap: don't wait for the zap receipt
  --limit <n>                     receipts: max events (default 50)
  --timeout <sec>                 Per-operation timeout (default 15)
  -h, --help                      Show this help''';

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
        case 'invoice':
          return await _handleInvoice(rest, ndk);
        case 'zap':
          return await _handleZap(rest, ndk, walletsRepo);
        case 'receipts':
          return await _handleReceipts(rest, ndk);
        default:
          stderr.writeln('Unknown zaps sub-command: "$sub"');
          stdout.writeln(_help);
          return 2;
      }
    } catch (e) {
      stderr.writeln('Zaps command failed: $e');
      return 1;
    }
  }

  // ---- invoice ------------------------------------------------------------

  Future<int> _handleInvoice(List<String> args, Ndk ndk) async {
    final parsed = _parseArgs(args, requirePositional: 2);
    if (parsed.error != null) {
      stderr.writeln(parsed.error);
      return 2;
    }
    final lud16 = parsed.positional[0];
    final amount = _parseAmount(parsed.positional[1]);
    if (amount == null) {
      stderr.writeln('Invalid amount: ${parsed.positional[1]}');
      return 2;
    }

    ZapRequest? zapRequest;
    final wantZap = !parsed.noZap;
    final pubKey = parsed.pubkey ?? _resolvePubkeyFromAccount(ndk);
    if (wantZap && pubKey != null && ndk.accounts.canSign) {
      final signer = ndk.accounts.getLoggedAccount()!.signer;
      final relays =
          parsed.relays.isNotEmpty ? parsed.relays : _defaultZapRelays(ndk);
      zapRequest = await ndk.zaps.createZapRequest(
        amountSats: amount,
        signer: signer,
        pubKey: pubKey,
        eventId: parsed.eventId,
        addressableId: parsed.addressable,
        comment: parsed.comment,
        relays: relays,
      );
    }

    stdout.writeln('Fetching invoice from $lud16 for $amount sats ...');
    final invoice = await ndk.zaps.fetchInvoice(
      lud16Link: lud16,
      amountSats: amount,
      zapRequest: zapRequest,
      comment: parsed.comment,
    );
    if (invoice == null) {
      stderr.writeln('Failed to fetch invoice from $lud16');
      return 1;
    }
    stdout.writeln(
        'Invoice ($amount sats${zapRequest != null ? ", zap-encoded" : ""}):');
    stdout.writeln(invoice.invoice);
    return 0;
  }

  // ---- zap ----------------------------------------------------------------

  Future<int> _handleZap(
    List<String> args,
    Ndk ndk,
    WalletsRepo walletsRepo,
  ) async {
    final parsed = _parseArgs(args, requirePositional: 2);
    if (parsed.error != null) {
      stderr.writeln(parsed.error);
      return 2;
    }
    final lud16 = parsed.positional[0];
    final amount = _parseAmount(parsed.positional[1]);
    if (amount == null) {
      stderr.writeln('Invalid amount: ${parsed.positional[1]}');
      return 2;
    }

    final wallet = await _resolveNwcWallet(parsed.walletId, walletsRepo, ndk);
    final nwcUrl = wallet.metadata['nwcUrl'] as String?;
    if (nwcUrl == null || nwcUrl.isEmpty) {
      stderr.writeln('Wallet ${wallet.id} has no nwcUrl metadata.');
      return 2;
    }

    final pubKey = parsed.pubkey ?? _resolvePubkeyFromAccount(ndk);
    final relays =
        parsed.relays.isNotEmpty ? parsed.relays : _defaultZapRelays(ndk);

    stdout.writeln('Connecting to NWC wallet ${wallet.id} ...');
    final connection = await ndk.nwc.connect(nwcUrl, doGetInfoMethod: false);
    try {
      stdout.writeln('Zapping $lud16 ($amount sats) ...');
      final response = await ndk.zaps.zap(
        nwcConnection: connection,
        lnurl: lud16,
        amountSats: amount,
        fetchZapReceipt: !parsed.noReceipt,
        signer: ndk.accounts.canSign
            ? ndk.accounts.getLoggedAccount()!.signer
            : null,
        relays: relays,
        pubKey: pubKey,
        comment: parsed.comment,
        eventId: parsed.eventId,
        addressableId: parsed.addressable,
      );

      if (response.error != null) {
        stderr.writeln('Zap failed: ${response.error}');
        return 1;
      }
      final pay = response.payInvoiceResponse;
      stdout.writeln('Zap paid:');
      stdout.writeln('  preimage: ${pay?.preimage}');
      stdout.writeln('  fees paid: ${pay?.feesPaid ?? 0} msats');

      if (!parsed.noReceipt && pubKey != null) {
        stdout.writeln('Waiting for zap receipt ...');
        final receipt = await response.zapReceipt.timeout(
          Duration(seconds: parsed.timeoutSeconds),
          onTimeout: () => null,
        );
        if (receipt == null) {
          stderr.writeln('  (no zap receipt received within timeout)');
        } else {
          stdout.writeln('  receipt amount: ${receipt.amountSats} sats');
          stdout.writeln('  receipt paidAt: ${_formatUnix(receipt.paidAt)}');
        }
      }
      return 0;
    } finally {
      await ndk.nwc.disconnect(connection);
    }
  }

  // ---- receipts -----------------------------------------------------------

  Future<int> _handleReceipts(List<String> args, Ndk ndk) async {
    final parsed = _parseArgs(args, requirePositional: 1);
    if (parsed.error != null) {
      stderr.writeln(parsed.error);
      return 2;
    }
    final rawPubkey = parsed.positional[0];
    final pubkey = _resolvePubkey(rawPubkey);
    if (pubkey == null) {
      stderr.writeln('Invalid pubkey: $rawPubkey');
      return 2;
    }

    stdout
        .writeln('Fetching zap receipts for ${Nip19.encodePubKey(pubkey)} ...');
    var count = 0;
    await for (final receipt in ndk.zaps.fetchZappedReceipts(
      pubKey: pubkey,
      eventId: parsed.eventId,
      addressableId: parsed.addressable,
      timeout: Duration(seconds: parsed.timeoutSeconds),
    )) {
      final amount = receipt.amountSats ?? 0;
      final sender = receipt.sender != null
          ? Nip19.encodePubKey(receipt.sender!)
          : '(anonymous)';
      final date = _formatUnix(receipt.paidAt) ?? '?';
      final comment = receipt.comment == null || receipt.comment!.isEmpty
          ? ''
          : '  "${receipt.comment}"';
      stdout.writeln('$date  $amount sat  from=$sender$comment');
      if (receipt.eventId != null) {
        stdout.writeln('    event: ${receipt.eventId}');
      }
      count++;
      if (count >= parsed.limit) break;
    }
    stdout.writeln('Done: $count receipt(s).');
    return 0;
  }

  // ---- helpers ------------------------------------------------------------

  Future<Wallet> _resolveNwcWallet(
    String? walletId,
    WalletsRepo walletsRepo,
    Ndk ndk,
  ) async {
    final wallets = await ndk.wallets.getWallets();
    if (wallets.isEmpty) {
      throw StateError(
          'No wallets available. Use "ndk wallets add nwc ..." first.');
    }
    if (walletId != null) {
      final match = wallets.firstWhere(
        (w) => w.id == walletId,
        orElse: () => throw ArgumentError('Wallet not found: $walletId'),
      );
      if (match.type != WalletType.NWC) {
        throw ArgumentError(
            'Wallet $walletId is ${match.type.value}, expected nwc.');
      }
      return match;
    }
    final defaultSending = ndk.wallets.defaultWalletForSending;
    if (defaultSending != null && defaultSending.type == WalletType.NWC) {
      return defaultSending;
    }
    final anyNwc = wallets.firstWhere(
      (w) => w.type == WalletType.NWC,
      orElse: () => throw StateError(
          'No NWC wallet configured. Use "ndk wallets add nwc ..." first.'),
    );
    return anyNwc;
  }

  String? _resolvePubkeyFromAccount(Ndk ndk) => ndk.accounts.getPublicKey();

  List<String> _defaultZapRelays(Ndk ndk) {
    final config = ndk.config;
    final bootstraps = config.bootstrapRelays;
    if (bootstraps.isNotEmpty) return bootstraps.toList();
    return ['wss://relay.damus.io', 'wss://nos.lol'];
  }

  int? _parseAmount(String raw) {
    final v = int.tryParse(raw);
    if (v == null || v <= 0) return null;
    return v;
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

  String? _resolveEventId(String value) {
    final t = value.trim();
    if (RegExp(r'^[0-9a-fA-F]{64}$').hasMatch(t)) return t.toLowerCase();
    if (Nip19.isNoteId(t)) {
      try {
        return Nip19.decode(t);
      } catch (_) {
        return t;
      }
    }
    return t;
  }

  String? _formatUnix(int? secondsSinceEpoch) {
    if (secondsSinceEpoch == null) return null;
    final dt = DateTime.fromMillisecondsSinceEpoch(secondsSinceEpoch * 1000,
        isUtc: true);
    return dt.toIso8601String();
  }

  bool _isHelp(String value) =>
      value == 'help' || value == '--help' || value == '-h';

  _ZapsArgs _parseArgs(List<String> args, {required int requirePositional}) {
    final result = _ZapsArgs();
    var i = 0;
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

      if (flag == '--wallet') {
        final v = nextOrInline();
        if (v == null) return _ZapsArgs(error: 'Missing value for --wallet');
        result.walletId = v;
        continue;
      }
      if (flag == '--comment') {
        final v = nextOrInline();
        if (v == null) return _ZapsArgs(error: 'Missing value for --comment');
        result.comment = v;
        continue;
      }
      if (flag == '--pubkey') {
        final v = nextOrInline();
        if (v == null) return _ZapsArgs(error: 'Missing value for --pubkey');
        result.pubkey = _resolvePubkey(v) ?? v;
        continue;
      }
      if (flag == '--event') {
        final v = nextOrInline();
        if (v == null) return _ZapsArgs(error: 'Missing value for --event');
        result.eventId = _resolveEventId(v);
        continue;
      }
      if (flag == '--addressable') {
        final v = nextOrInline();
        if (v == null) {
          return _ZapsArgs(error: 'Missing value for --addressable');
        }
        result.addressable = v;
        continue;
      }
      if (flag == '--relays') {
        final v = nextOrInline();
        if (v == null) return _ZapsArgs(error: 'Missing value for --relays');
        result.relays.add(v);
        continue;
      }
      if (flag == '--no-zap') {
        result.noZap = true;
        i += 1;
        continue;
      }
      if (flag == '--no-receipt') {
        result.noReceipt = true;
        i += 1;
        continue;
      }
      if (flag == '--limit') {
        final v = nextOrInline();
        if (v == null) return _ZapsArgs(error: 'Missing value for --limit');
        final n = int.tryParse(v);
        if (n == null || n <= 0) {
          return _ZapsArgs(error: 'Invalid --limit "$v"');
        }
        result.limit = n;
        continue;
      }
      if (flag == '--timeout') {
        final v = nextOrInline();
        if (v == null) return _ZapsArgs(error: 'Missing value for --timeout');
        final n = int.tryParse(v);
        if (n == null || n <= 0) {
          return _ZapsArgs(error: 'Invalid --timeout "$v"');
        }
        result.timeoutSeconds = n;
        continue;
      }
      if (flag == '-h' || flag == '--help') {
        i += 1;
        continue;
      }
      if (flag.startsWith('-')) {
        return _ZapsArgs(error: 'Unknown option: $flag');
      }
      result.positional.add(raw);
      i += 1;
    }

    if (result.positional.length < requirePositional) {
      return _ZapsArgs(
          error: 'Expected $requirePositional positional argument(s), '
              'got ${result.positional.length}.');
    }
    return result;
  }
}

class _ZapsArgs {
  final List<String> positional = [];
  String? walletId;
  String? comment;
  String? pubkey;
  String? eventId;
  String? addressable;
  final List<String> relays = [];
  bool noZap = false;
  bool noReceipt = false;
  int limit = 50;
  int timeoutSeconds = 15;
  String? error;

  _ZapsArgs({this.error});
}
