import 'dart:io';

import 'package:ndk/domain_layer/repositories/wallets_repo.dart';
import 'package:ndk/ndk.dart';

import '../cli_accounts_store.dart';
import '../cli_command.dart';

/// `ndk blossom` - low-level Blossom (BUD-*) operations + user server list.
///
/// Sub-commands:
///   upload, download, delete, list, mirror, check, servers
class BlossomCliCommand implements CliCommand {
  @override
  String get name => 'blossom';

  @override
  String get description =>
      'Blossom ops (upload, download, delete, list, mirror, check, servers)';

  @override
  String get usage => _help;

  static const String _help = '''ndk blossom <sub-command> [args]
Sub-commands:
  upload <filePath> [options]                            Upload a local file
  download <sha256> <outputPath> [options]               Download a blob to disk
  delete <sha256> [options]                              Delete a blob
  list [pubkey] [options]                                List blobs for a pubkey
  mirror <sourceUrl> --server <url> [--server url ...]   Mirror an existing blob
  check <sha256> [options]                               Check blob existence
  servers list [pubkey]                                  Get a user's server list
  servers publish <url> [url ...]                        Publish your server list
Options:
  --server <url> (repeatable)                            Blossom server(s)
  --pubkey <hex|npub>                                    Server-list owner
  --content-type <mime>                                  Override mime type (upload)
  --media                                                Server-side media optimisation (upload)
  --auth                                                 Use signed GET (download/check/list)
  --since <iso|unix>                                     list: only blobs after this date
  --until <iso|unix>                                     list: only blobs before this date
  -h, --help                                             Show this help''';

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
        case 'upload':
          return await _handleUpload(rest, ndk);
        case 'download':
          return await _handleDownload(rest, ndk);
        case 'delete':
          return await _handleDelete(rest, ndk);
        case 'list':
          return await _handleList(rest, ndk);
        case 'mirror':
          return await _handleMirror(rest, ndk);
        case 'check':
          return await _handleCheck(rest, ndk);
        case 'servers':
          return await _handleServers(rest, ndk);
        default:
          stderr.writeln('Unknown blossom sub-command: "$sub"');
          stdout.writeln(_help);
          return 2;
      }
    } catch (e) {
      stderr.writeln('Blossom command failed: $e');
      return 1;
    }
  }

  // ---- upload -------------------------------------------------------------

  Future<int> _handleUpload(List<String> args, Ndk ndk) async {
    final parsed = _parseArgs(args, requirePositional: 1);
    if (parsed.error != null) {
      stderr.writeln(parsed.error);
      return 2;
    }
    final filePath = parsed.positional[0];
    if (!await File(filePath).exists()) {
      stderr.writeln('File not found: $filePath');
      return 2;
    }

    stdout.writeln('Uploading $filePath ...');
    final stream = ndk.blossom.uploadBlobFromFile(
      filePath: filePath,
      serverUrls: parsed.servers.isEmpty ? null : parsed.servers,
      contentType: parsed.contentType,
      serverMediaOptimisation: parsed.media,
    );

    List<BlobUploadResult>? finalResults;
    await for (final progress in stream) {
      final phase = progress.phase.name;
      final pct = progress.percentage.toStringAsFixed(1);
      stdout.writeln(
          '  [$phase] ${progress.currentServer.isEmpty ? "-" : progress.currentServer} '
                  '$pct% '
                  '${progress.mirrorsTotal > 0 ? "(${progress.mirrorsCompleted}/${progress.mirrorsTotal} mirrors)" : ""}'
              .trimRight());
      if (progress.completedUploads.isNotEmpty) {
        finalResults = progress.completedUploads;
      }
    }
    if (finalResults == null || finalResults.isEmpty) {
      stderr.writeln('Upload produced no results.');
      return 1;
    }
    stdout.writeln('Upload done:');
    _printUploadResults(finalResults);
    return finalResults.every((r) => r.success) ? 0 : 1;
  }

  // ---- download -----------------------------------------------------------

  Future<int> _handleDownload(List<String> args, Ndk ndk) async {
    final parsed = _parseArgs(args, requirePositional: 2);
    if (parsed.error != null) {
      stderr.writeln(parsed.error);
      return 2;
    }
    final sha = _requireSha256(parsed.positional[0]);
    if (sha == null) return 2;
    final outPath = parsed.positional[1];

    stdout.writeln('Downloading $sha -> $outPath ...');
    await ndk.blossom.downloadBlobToFile(
      sha256: sha,
      outputPath: outPath,
      useAuth: parsed.auth,
      serverUrls: parsed.servers.isEmpty ? null : parsed.servers,
      pubkeyToFetchUserServerList: parsed.pubkey,
    );
    final size = await File(outPath).length();
    stdout.writeln('Done: $outPath (${_humanSize(size)}).');
    return 0;
  }

  // ---- delete -------------------------------------------------------------

  Future<int> _handleDelete(List<String> args, Ndk ndk) async {
    final parsed = _parseArgs(args, requirePositional: 1);
    if (parsed.error != null) {
      stderr.writeln(parsed.error);
      return 2;
    }
    final sha = _requireSha256(parsed.positional[0]);
    if (sha == null) return 2;

    stdout.writeln('Deleting $sha ...');
    final results = await ndk.blossom.deleteBlob(
      sha256: sha,
      serverUrls: parsed.servers.isEmpty ? null : parsed.servers,
    );
    for (final r in results) {
      final status = r.success ? 'OK' : 'FAILED';
      stdout.writeln('  ${r.serverUrl}: $status'
          '${r.error == null ? "" : " (${r.error})"}');
    }
    return results.every((r) => r.success) ? 0 : 1;
  }

  // ---- list ---------------------------------------------------------------

  Future<int> _handleList(List<String> args, Ndk ndk) async {
    final parsed = _parseArgs(args, requirePositional: 0);
    if (parsed.error != null) {
      stderr.writeln(parsed.error);
      return 2;
    }
    final pubkey = parsed.pubkey ??
        (parsed.positional.isNotEmpty
            ? _resolvePubkey(parsed.positional[0])
            : null) ??
        ndk.accounts.getPublicKey();
    if (pubkey == null) {
      stderr.writeln('A pubkey is required (positional, --pubkey, or login).');
      return 2;
    }

    stdout.writeln('Listing blobs for ${Nip19.encodePubKey(pubkey)} ...');
    final blobs = await ndk.blossom.listBlobs(
      pubkey: pubkey,
      serverUrls: parsed.servers.isEmpty ? null : parsed.servers,
      useAuth: parsed.auth,
      since: parsed.since,
      until: parsed.until,
    );
    if (blobs.isEmpty) {
      stdout.writeln('(no blobs)');
      return 0;
    }
    for (final b in blobs) {
      stdout.writeln('  sha256=${b.sha256} '
          'size=${_humanSize(b.size ?? 0)} '
          'type=${b.type ?? "?"} '
          'uploaded=${b.uploaded.toIso8601String()}');
      stdout.writeln('    url=${b.url}');
    }
    stdout.writeln('Total: ${blobs.length} blob(s).');
    return 0;
  }

  // ---- mirror -------------------------------------------------------------

  Future<int> _handleMirror(List<String> args, Ndk ndk) async {
    final parsed = _parseArgs(args, requirePositional: 1);
    if (parsed.error != null) {
      stderr.writeln(parsed.error);
      return 2;
    }
    if (parsed.servers.isEmpty) {
      stderr.writeln('mirror requires at least one --server target.');
      return 2;
    }
    final source = Uri.parse(parsed.positional[0]);
    stdout
        .writeln('Mirroring $source -> ${parsed.servers.length} server(s) ...');
    final results = await ndk.blossom.mirrorToServers(
      blossomUrl: source,
      targetServerUrls: parsed.servers,
    );
    _printUploadResults(results);
    return results.every((r) => r.success) ? 0 : 1;
  }

  // ---- check --------------------------------------------------------------

  Future<int> _handleCheck(List<String> args, Ndk ndk) async {
    final parsed = _parseArgs(args, requirePositional: 1);
    if (parsed.error != null) {
      stderr.writeln(parsed.error);
      return 2;
    }
    final sha = _requireSha256(parsed.positional[0]);
    if (sha == null) return 2;

    stdout.writeln('Checking $sha ...');
    final url = await ndk.blossom.checkBlob(
      sha256: sha,
      useAuth: parsed.auth,
      serverUrls: parsed.servers.isEmpty ? null : parsed.servers,
      pubkeyToFetchUserServerList: parsed.pubkey,
    );
    stdout.writeln('Alive URL: $url');
    return 0;
  }

  // ---- servers ------------------------------------------------------------

  Future<int> _handleServers(List<String> args, Ndk ndk) async {
    if (args.isEmpty || _isHelp(args.first)) {
      stdout.writeln(_serversHelp);
      return 0;
    }
    final sub = args.first.toLowerCase();
    final rest = args.sublist(1);
    switch (sub) {
      case 'list':
        return await _handleServersList(rest, ndk);
      case 'publish':
        return await _handleServersPublish(rest, ndk);
      default:
        stderr.writeln('Unknown blossom servers sub-command: "$sub"');
        stdout.writeln(_serversHelp);
        return 2;
    }
  }

  Future<int> _handleServersList(List<String> args, Ndk ndk) async {
    String? pubkey;
    if (args.isNotEmpty && !args.first.startsWith('-')) {
      pubkey = _resolvePubkey(args.first);
      if (pubkey == null) {
        stderr.writeln('Invalid pubkey: ${args.first}');
        return 2;
      }
    }
    pubkey ??= ndk.accounts.getPublicKey();
    if (pubkey == null) {
      stderr.writeln('A pubkey is required (positional or login).');
      return 2;
    }

    stdout.writeln('Fetching blossom server list for '
        '${Nip19.encodePubKey(pubkey)} ...');
    final servers = await ndk.blossomUserServerList.getUserServerList(
      pubkeys: [pubkey],
    );
    if (servers == null || servers.isEmpty) {
      stdout.writeln('(no server list published)');
      return 0;
    }
    for (var i = 0; i < servers.length; i++) {
      stdout.writeln('  ${i + 1}. ${servers[i]}');
    }
    return 0;
  }

  Future<int> _handleServersPublish(List<String> args, Ndk ndk) async {
    final servers = args.where((a) => !a.startsWith('-')).toList();
    if (servers.isEmpty) {
      stderr.writeln('Usage: ndk blossom servers publish <url> [url ...]');
      return 2;
    }
    if (ndk.accounts.isNotLoggedIn) {
      stderr.writeln('Login required: use "ndk accounts login ..." first.');
      return 2;
    }
    stdout.writeln('Publishing server list (${servers.length} server(s)) ...');
    final responses = await ndk.blossomUserServerList.publishUserServerList(
      serverUrlsOrdered: servers,
    );
    var ok = 0;
    for (final r in responses) {
      final status = r.broadcastSuccessful ? 'OK' : 'FAILED';
      stdout.writeln('  ${r.relayUrl}: $status');
      if (r.broadcastSuccessful) ok++;
    }
    stdout.writeln('Done: $ok/${responses.length} relay(s) accepted.');
    return ok == 0 ? 1 : 0;
  }

  static const String _serversHelp =
      '''ndk blossom servers <list|publish> [args]
  list [pubkey]                 Show the (kind 10063) server list for a pubkey
  publish <url> [url ...]       Publish your own server list (login required)''';

  // ---- helpers ------------------------------------------------------------

  void _printUploadResults(List<BlobUploadResult> results) {
    for (final r in results) {
      if (r.success && r.descriptor != null) {
        final d = r.descriptor!;
        stdout.writeln('  ${r.serverUrl}: OK '
            'sha256=${d.sha256} '
            'size=${_humanSize(d.size ?? 0)} '
            'type=${d.type ?? "?"}');
      } else {
        stdout.writeln('  ${r.serverUrl}: FAILED '
            '${r.error == null ? "" : "(${r.error})"}');
      }
    }
  }

  String? _requireSha256(String raw) {
    final t = raw.toLowerCase().trim();
    if (!RegExp(r'^[0-9a-f]{64}$').hasMatch(t)) {
      stderr.writeln('Invalid sha256: $raw');
      return null;
    }
    return t;
  }

  String _humanSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KiB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MiB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GiB';
  }

  DateTime? _parseDateTime(String value) {
    final asInt = int.tryParse(value);
    if (asInt != null) {
      return DateTime.fromMillisecondsSinceEpoch(asInt * 1000, isUtc: true);
    }
    try {
      return DateTime.parse(value).toUtc();
    } on FormatException {
      return null;
    }
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

  bool _isHelp(String value) =>
      value == 'help' || value == '--help' || value == '-h';

  _BlossomArgs _parseArgs(List<String> args, {required int requirePositional}) {
    final result = _BlossomArgs();
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

      if (flag == '--server') {
        final v = nextOrInline();
        if (v == null) return _BlossomArgs(error: 'Missing value for --server');
        result.servers.add(v);
        continue;
      }
      if (flag == '--pubkey') {
        final v = nextOrInline();
        if (v == null) return _BlossomArgs(error: 'Missing value for --pubkey');
        result.pubkey = _resolvePubkey(v) ?? v;
        continue;
      }
      if (flag == '--content-type') {
        final v = nextOrInline();
        if (v == null) {
          return _BlossomArgs(error: 'Missing value for --content-type');
        }
        result.contentType = v;
        continue;
      }
      if (flag == '--media') {
        result.media = true;
        i += 1;
        continue;
      }
      if (flag == '--auth') {
        result.auth = true;
        i += 1;
        continue;
      }
      if (flag == '--since') {
        final v = nextOrInline();
        if (v == null) return _BlossomArgs(error: 'Missing value for --since');
        final dt = _parseDateTime(v);
        if (dt == null) {
          return _BlossomArgs(error: 'Invalid --since "$v"');
        }
        result.since = dt;
        continue;
      }
      if (flag == '--until') {
        final v = nextOrInline();
        if (v == null) return _BlossomArgs(error: 'Missing value for --until');
        final dt = _parseDateTime(v);
        if (dt == null) {
          return _BlossomArgs(error: 'Invalid --until "$v"');
        }
        result.until = dt;
        continue;
      }
      if (flag == '-h' || flag == '--help') {
        i += 1;
        continue;
      }
      if (flag.startsWith('-')) {
        return _BlossomArgs(error: 'Unknown option: $flag');
      }
      result.positional.add(raw);
      i += 1;
    }

    if (result.positional.length < requirePositional) {
      return _BlossomArgs(
          error: 'Expected $requirePositional positional argument(s), '
              'got ${result.positional.length}.');
    }
    return result;
  }
}

class _BlossomArgs {
  final List<String> positional = [];
  final List<String> servers = [];
  String? pubkey;
  String? contentType;
  bool media = false;
  bool auth = false;
  DateTime? since;
  DateTime? until;
  String? error;

  _BlossomArgs({this.error});
}
