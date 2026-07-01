import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:ndk/domain_layer/repositories/wallets_repo.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk/shared/helpers/relay_helper.dart';

import 'cli_accounts_store.dart';
import 'cli_command.dart';

class ReqCliCommand implements CliCommand {
  @override
  String get name => 'req';

  @override
  String get description => 'Query relays for events';

  @override
  String get usage => 'ndk req [options] <relay1> [relay2 ...]\n'
      'Options:\n'
      '  -k, --kind <kind>          Event kind (repeatable)\n'
      '  -a, --author <hex|npub>    Author pubkey (repeatable)\n'
      '  -i, --id <hex|nevent>      Event id (repeatable)\n'
      '  -e, --e <hex>              #e tag value (repeatable)\n'
      '  -p, --p <hex|npub>         #p tag value (repeatable)\n'
      '  -d, --d <value>            #d tag value (repeatable)\n'
      '  -T, --hashtag <value>      #t tag value (repeatable)\n'
      '      --tag <k=v>            Arbitrary single-char tag, e.g. --tag r=wss://x (repeatable)\n'
      '      --search <query>       NIP-50 search\n'
      '      --since <unix|iso|dur> created_at >= (e.g. 1h, 2d, 2024-01-01)\n'
      '      --until <unix|iso|dur> created_at <=\n'
      '  -l, --limit <n>            Max events to emit (default 10)\n'
      '      --timeout <sec>        Query timeout (default 12)\n'
      '      --stream               Live subscription: keep receiving until Ctrl+C\n'
      '  -o, --output <json|summary> Output mode (default json)\n'
      '  -h, --help                 Show this help';

  @override
  Future<int> run(
    List<String> args,
    Ndk ndk,
    WalletsRepo walletsRepo,
    CliAccountsStore accountsStore,
  ) async {
    if (_isHelp(args)) {
      _printUsage();
      return 0;
    }

    final parseResult = _parseArgs(args);
    if (parseResult.error != null) {
      stderr.writeln(parseResult.error);
      stderr.writeln('Usage: ndk req [options] <relay> [relay ...]');
      return 2;
    }

    final filter = Filter(
      kinds: parseResult.kinds.isEmpty ? null : parseResult.kinds,
      ids: parseResult.ids.isEmpty ? null : parseResult.ids,
      authors: parseResult.authors.isEmpty ? null : parseResult.authors,
      search: parseResult.search,
      eTags: parseResult.eTags.isEmpty ? null : parseResult.eTags,
      pTags: parseResult.pTags.isEmpty ? null : parseResult.pTags,
      dTags: parseResult.dTags.isEmpty ? null : parseResult.dTags,
      tTags: parseResult.tTags.isEmpty ? null : parseResult.tTags,
      since: parseResult.since,
      until: parseResult.until,
      limit: parseResult.limit,
    );
    if (parseResult.extraTags.isNotEmpty) {
      filter.tags ??= {};
      filter.tags!.addAll(parseResult.extraTags);
    }

    if (parseResult.stream) {
      return _runStream(parseResult, filter, ndk);
    }

    final response = ndk.requests.query(
      filter: filter,
      explicitRelays: parseResult.relays,
      cacheRead: false,
      cacheWrite: false,
      timeout: Duration(seconds: parseResult.timeoutSeconds),
    );

    var emitted = 0;
    try {
      await for (final event in response.stream) {
        _emitEvent(event, parseResult);
        emitted++;
        if (emitted >= parseResult.limit) {
          break;
        }
      }
    } finally {
      await ndk.requests.closeSubscription(
        response.requestId,
        debugLabel: 'req CLI done',
      );
    }

    return 0;
  }

  Future<int> _runStream(
    _ReqArgsParseResult parseResult,
    Filter filter,
    Ndk ndk,
  ) async {
    stderr.writeln('Streaming (Ctrl+C to stop)...');

    final response = ndk.requests.subscription(
      filter: filter,
      explicitRelays: parseResult.relays,
      cacheRead: false,
      cacheWrite: false,
    );

    var received = 0;
    final done = Completer<void>();

    final sigintSub = ProcessSignal.sigint.watch().listen((_) {
      stderr.writeln('\nStopping...');
      if (!done.isCompleted) {
        done.complete();
      }
    });

    final eventSub = response.stream.listen(
      (event) {
        _emitEvent(event, parseResult);
        received++;
      },
      onDone: () {
        if (!done.isCompleted) {
          done.complete();
        }
      },
      onError: (e) {
        stderr.writeln('Subscription error: $e');
        if (!done.isCompleted) {
          done.complete();
        }
      },
    );

    try {
      await done.future;
    } finally {
      await eventSub.cancel();
      await sigintSub.cancel();
      await ndk.requests.closeSubscription(
        response.requestId,
        debugLabel: 'req CLI stream done',
      );
    }

    stderr.writeln('Received $received event(s).');
    return 0;
  }

  void _emitEvent(Nip01Event event, _ReqArgsParseResult parseResult) {
    if (parseResult.output == _OutputMode.summary) {
      stdout.writeln(_eventSummary(event));
    } else {
      stdout.writeln(jsonEncode(_eventToJson(event)));
    }
  }

  bool _isHelp(List<String> args) {
    return args.contains('--help') || args.contains('-h');
  }

  void _printUsage() {
    stdout.writeln(description);
    stdout.writeln(usage);
  }

  _ReqArgsParseResult _parseArgs(List<String> args) {
    final result = _ReqArgsParseResult();
    int i = 0;
    while (i < args.length) {
      final raw = args[i];

      // split "--flag=value" form
      String flag;
      String? inlineValue;
      final eq = raw.indexOf('=');
      if (eq > 0 && raw.startsWith('-')) {
        flag = raw.substring(0, eq);
        inlineValue = raw.substring(eq + 1);
      } else {
        flag = raw;
        inlineValue = null;
      }

      String? takeValue() {
        if (inlineValue != null) {
          i += 1;
          return inlineValue;
        }
        if (i + 1 >= args.length) {
          return null;
        }
        final v = args[i + 1];
        i += 2;
        return v;
      }

      if (flag == '-k' || flag == '--kind') {
        final v = takeValue();
        if (v == null) {
          return _ReqArgsParseResult(error: 'Missing value for $flag');
        }
        final kind = int.tryParse(v);
        if (kind == null) {
          return _ReqArgsParseResult(error: 'Invalid kind value "$v"');
        }
        result.kinds.add(kind);
        continue;
      }

      if (flag == '-a' || flag == '--author') {
        final v = takeValue();
        if (v == null) {
          return _ReqArgsParseResult(error: 'Missing value for $flag');
        }
        final hex = _resolvePubkey(v);
        if (hex == null) {
          return _ReqArgsParseResult(error: 'Invalid author value "$v"');
        }
        result.authors.add(hex);
        continue;
      }

      if (flag == '-i' || flag == '--id') {
        final v = takeValue();
        if (v == null) {
          return _ReqArgsParseResult(error: 'Missing value for $flag');
        }
        result.ids.add(_resolveEventId(v));
        continue;
      }

      if (flag == '-e' || flag == '--e') {
        final v = takeValue();
        if (v == null) {
          return _ReqArgsParseResult(error: 'Missing value for $flag');
        }
        result.eTags.add(_resolveEventId(v));
        continue;
      }

      if (flag == '-p' || flag == '--p') {
        final v = takeValue();
        if (v == null) {
          return _ReqArgsParseResult(error: 'Missing value for $flag');
        }
        final hex = _resolvePubkey(v);
        if (hex == null) {
          return _ReqArgsParseResult(error: 'Invalid p-tag value "$v"');
        }
        result.pTags.add(hex);
        continue;
      }

      if (flag == '-d' || flag == '--d') {
        final v = takeValue();
        if (v == null) {
          return _ReqArgsParseResult(error: 'Missing value for $flag');
        }
        result.dTags.add(v);
        continue;
      }

      if (flag == '-T' || flag == '--hashtag') {
        final v = takeValue();
        if (v == null) {
          return _ReqArgsParseResult(error: 'Missing value for $flag');
        }
        result.tTags.add(v);
        continue;
      }

      if (flag == '--tag') {
        final v = takeValue();
        if (v == null) {
          return _ReqArgsParseResult(error: 'Missing value for $flag');
        }
        final parsed = _parseTagAssignment(v);
        if (parsed == null) {
          return _ReqArgsParseResult(
            error: 'Invalid --tag "$v" (expected key=value)',
          );
        }
        final key = parsed.key;
        if (key.length != 1) {
          return _ReqArgsParseResult(
            error: '--tag key must be a single char (got "$key")',
          );
        }
        final mapKey = '#$key';
        result.extraTags
            .putIfAbsent(mapKey, () => <String>[])
            .add(parsed.value);
        continue;
      }

      if (flag == '--search') {
        final v = takeValue();
        if (v == null) {
          return _ReqArgsParseResult(error: 'Missing value for $flag');
        }
        result.search = v;
        continue;
      }

      if (flag == '--since') {
        final v = takeValue();
        if (v == null) {
          return _ReqArgsParseResult(error: 'Missing value for $flag');
        }
        final ts = _parseTime(v, upperBound: false);
        if (ts == null) {
          return _ReqArgsParseResult(error: 'Invalid --since value "$v"');
        }
        result.since = ts;
        continue;
      }

      if (flag == '--until') {
        final v = takeValue();
        if (v == null) {
          return _ReqArgsParseResult(error: 'Missing value for $flag');
        }
        final ts = _parseTime(v, upperBound: true);
        if (ts == null) {
          return _ReqArgsParseResult(error: 'Invalid --until value "$v"');
        }
        result.until = ts;
        continue;
      }

      if (flag == '-l' || flag == '--limit') {
        final v = takeValue();
        if (v == null) {
          return _ReqArgsParseResult(error: 'Missing value for $flag');
        }
        final n = int.tryParse(v);
        if (n == null || n <= 0) {
          return _ReqArgsParseResult(error: 'Invalid limit value "$v"');
        }
        result.limit = n;
        continue;
      }

      if (flag == '--timeout' || flag == '-t') {
        final v = takeValue();
        if (v == null) {
          return _ReqArgsParseResult(error: 'Missing value for $flag');
        }
        final n = int.tryParse(v);
        if (n == null || n <= 0) {
          return _ReqArgsParseResult(error: 'Invalid timeout value "$v"');
        }
        result.timeoutSeconds = n;
        continue;
      }

      if (flag == '--stream') {
        result.stream = true;
        i += 1;
        continue;
      }

      if (flag == '-o' || flag == '--output') {
        final v = takeValue();
        if (v == null) {
          return _ReqArgsParseResult(error: 'Missing value for $flag');
        }
        switch (v) {
          case 'json':
            result.output = _OutputMode.json;
            break;
          case 'summary':
            result.output = _OutputMode.summary;
            break;
          default:
            return _ReqArgsParseResult(
              error: 'Invalid --output "$v" (json|summary)',
            );
        }
        continue;
      }

      if (flag.startsWith('-') && flag != '-') {
        return _ReqArgsParseResult(error: 'Unknown option: $flag');
      }

      final cleanedRelay = _parseRelay(raw);
      if (cleanedRelay == null) {
        return _ReqArgsParseResult(error: 'Invalid relay URL: $raw');
      }
      result.relays.add(cleanedRelay);
      i++;
    }

    if (result.relays.isEmpty) {
      return _ReqArgsParseResult(error: 'At least one relay URL is required.');
    }

    return result;
  }

  String? _resolvePubkey(String value) {
    final trimmed = value.trim();
    if (RegExp(r'^[0-9a-fA-F]{64}$').hasMatch(trimmed)) {
      return trimmed.toLowerCase();
    }
    if (Nip19.isPubkey(trimmed)) {
      try {
        return Nip19.decode(trimmed);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  String _resolveEventId(String value) {
    final trimmed = value.trim();
    if (RegExp(r'^[0-9a-fA-F]{64}$').hasMatch(trimmed)) {
      return trimmed.toLowerCase();
    }
    if (Nip19.isNoteId(trimmed)) {
      try {
        return Nip19.decode(trimmed);
      } catch (_) {
        return trimmed;
      }
    }
    return trimmed;
  }

  MapEntry<String, String>? _parseTagAssignment(String raw) {
    final eq = raw.indexOf('=');
    if (eq <= 0 || eq == raw.length - 1) return null;
    return MapEntry(raw.substring(0, eq), raw.substring(eq + 1));
  }

  /// Parses a time arg. Accepted forms:
  ///  - unix seconds (e.g. 1700000000)
  ///  - ISO 8601 (e.g. 2024-01-01, 2024-01-01T12:00:00Z)
  ///  - duration: digits + unit (s|m|h|d|w). For --since this means "now - dur",
  ///    for --until this means "now + dur" (rarely useful).
  int? _parseTime(String value, {required bool upperBound}) {
    final trimmed = value.trim();
    final asInt = int.tryParse(trimmed);
    if (asInt != null) return asInt;

    final durMatch = RegExp(r'^(\d+)\s*([smhdw])$').firstMatch(trimmed);
    if (durMatch != null) {
      final amount = int.parse(durMatch.group(1)!);
      final unit = durMatch.group(2)!;
      final mult = {
        's': 1,
        'm': 60,
        'h': 3600,
        'd': 86400,
        'w': 604800,
      }[unit]!;
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final delta = amount * mult;
      return upperBound ? now + delta : now - delta;
    }

    try {
      final parsed = DateTime.parse(trimmed);
      return parsed.toUtc().millisecondsSinceEpoch ~/ 1000;
    } on FormatException {
      return null;
    }
  }

  String? _parseRelay(String value) {
    final direct = cleanRelayUrl(value);
    if (direct != null) return direct;
    return cleanRelayUrl('wss://$value');
  }

  Map<String, dynamic> _eventToJson(Nip01Event event) {
    return {
      'id': event.id,
      'pubkey': event.pubKey,
      'created_at': event.createdAt,
      'kind': event.kind,
      'tags': event.tags,
      'content': event.content,
      'sig': event.sig,
    };
  }

  String _eventSummary(Nip01Event event) {
    final created = DateTime.fromMillisecondsSinceEpoch(event.createdAt * 1000,
        isUtc: true);
    final preview = event.content.length > 80
        ? '${event.content.substring(0, 77)}...'
        : event.content;
    final oneLine = preview.replaceAll('\n', ' ');
    return 'kind=${event.kind} ${created.toIso8601String()} '
        'id=${event.id} author=${event.pubKey.substring(0, 12)}... '
        '"$oneLine"';
  }
}

enum _OutputMode { json, summary }

class _ReqArgsParseResult {
  final List<int> kinds = [];
  final List<String> ids = [];
  final List<String> authors = [];
  final List<String> eTags = [];
  final List<String> pTags = [];
  final List<String> dTags = [];
  final List<String> tTags = [];
  final Map<String, List<String>> extraTags = {};
  String? search;
  int? since;
  int? until;
  int limit = 10;
  int timeoutSeconds = 12;
  bool stream = false;
  _OutputMode output = _OutputMode.json;
  final List<String> relays = [];
  String? error;

  _ReqArgsParseResult({this.error});
}
