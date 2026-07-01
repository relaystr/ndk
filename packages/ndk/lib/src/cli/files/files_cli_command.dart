import 'dart:io';

import 'package:ndk/domain_layer/repositories/wallets_repo.dart';
import 'package:ndk/ndk.dart';

import '../cli_accounts_store.dart';
import '../cli_command.dart';

/// `ndk files` - high-level file management (Blossom-backed, transparent
/// mirror of [Ndk.files]).
///
/// Sub-commands: `upload`, `download`, `delete`, `check`.
class FilesCliCommand implements CliCommand {
  @override
  String get name => 'files';

  @override
  String get description => 'Manage files (upload, download, delete, check)';

  @override
  String get usage => _help;

  static const String _help = '''ndk files <sub-command> [args]
Sub-commands:
  upload <filePath> [options]                            Upload a local file
  download <url> <outputPath> [options]                  Download to disk
  delete <sha256> [options]                              Delete a blob
  check <url> [options]                                  Check if URL resolves
Options:
  --server <url> (repeatable)                            Blossom server(s)
  --pubkey <hex|npub>                                    Server-list owner
  --content-type <mime>                                  Override mime type (upload)
  --media                                                Server-side media optimisation (upload)
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
        case 'check':
          return await _handleCheck(rest, ndk);
        default:
          stderr.writeln('Unknown files sub-command: "$sub"');
          stdout.writeln(_help);
          return 2;
      }
    } catch (e) {
      stderr.writeln('Files command failed: $e');
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
    final stream = ndk.files.uploadFromFile(
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
    final url = parsed.positional[0];
    final outPath = parsed.positional[1];

    stdout.writeln('Downloading $url -> $outPath ...');
    await ndk.files.downloadToFile(
      url: url,
      outputPath: outPath,
      serverUrls: parsed.servers.isEmpty ? null : parsed.servers,
      pubkey: parsed.pubkey,
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
    final sha = parsed.positional[0].toLowerCase();
    if (!RegExp(r'^[0-9a-f]{64}$').hasMatch(sha)) {
      stderr.writeln('Invalid sha256: $sha');
      return 2;
    }

    stdout.writeln('Deleting $sha ...');
    final results = await ndk.files.delete(
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

  // ---- check --------------------------------------------------------------

  Future<int> _handleCheck(List<String> args, Ndk ndk) async {
    final parsed = _parseArgs(args, requirePositional: 1);
    if (parsed.error != null) {
      stderr.writeln(parsed.error);
      return 2;
    }
    final url = parsed.positional[0];

    stdout.writeln('Checking $url ...');
    final alive = await ndk.files.checkUrl(
      url: url,
      serverUrls: parsed.servers.isEmpty ? null : parsed.servers,
      pubkey: parsed.pubkey,
    );
    stdout.writeln('Alive URL: $alive');
    return 0;
  }

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

  String _humanSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KiB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MiB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GiB';
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

  _FilesArgs _parseArgs(List<String> args, {required int requirePositional}) {
    final result = _FilesArgs();
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
        if (v == null) return _FilesArgs(error: 'Missing value for --server');
        result.servers.add(v);
        continue;
      }
      if (flag == '--pubkey') {
        final v = nextOrInline();
        if (v == null) return _FilesArgs(error: 'Missing value for --pubkey');
        result.pubkey = _resolvePubkey(v) ?? v;
        continue;
      }
      if (flag == '--content-type') {
        final v = nextOrInline();
        if (v == null) {
          return _FilesArgs(error: 'Missing value for --content-type');
        }
        result.contentType = v;
        continue;
      }
      if (flag == '--media') {
        result.media = true;
        i += 1;
        continue;
      }
      if (flag == '-h' || flag == '--help') {
        i += 1;
        continue;
      }
      if (flag.startsWith('-')) {
        return _FilesArgs(error: 'Unknown option: $flag');
      }
      result.positional.add(raw);
      i += 1;
    }

    if (result.positional.length < requirePositional) {
      return _FilesArgs(
          error: 'Expected $requirePositional positional argument(s), '
              'got ${result.positional.length}.');
    }
    return result;
  }
}

class _FilesArgs {
  final List<String> positional = [];
  final List<String> servers = [];
  String? pubkey;
  String? contentType;
  bool media = false;
  String? error;

  _FilesArgs({this.error});
}
