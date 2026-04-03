import 'dart:convert';
import 'dart:io';

import 'package:ndk/domain_layer/repositories/wallets_repo.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk/shared/helpers/relay_helper.dart';

import 'cli_command.dart';

class ReqCliCommand implements CliCommand {
  @override
  String get name => 'req';

  @override
  String get description => 'Query relays for events';

  @override
  String get usage =>
      'ndk req [-k <kind>] [-l <limit>] [-t <seconds>] <relay1> [relay2 ...]';

  @override
  Future<int> run(List<String> args, Ndk ndk, WalletsRepo walletsRepo) async {
    if (_isHelp(args)) {
      _printUsage();
      return 0;
    }

    final parseResult = _parseArgs(args);
    if (parseResult.error != null) {
      stderr.writeln(parseResult.error);
      stderr.writeln('Usage: $usage');
      return 2;
    }

    final filter = Filter(
      kinds: parseResult.kind != null ? [parseResult.kind!] : null,
      limit: parseResult.limit,
    );

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
        stdout.writeln(jsonEncode(_eventToJson(event)));
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

  bool _isHelp(List<String> args) {
    return args.contains('--help') || args.contains('-h');
  }

  void _printUsage() {
    stdout.writeln(description);
    stdout.writeln('Usage: $usage');
    stdout.writeln('Options:');
    stdout.writeln('  -k, --kind <kind>    Filter by event kind');
    stdout.writeln('  -l, --limit <limit>  Limit number of events');
    stdout.writeln('  -t, --timeout <sec>  Query timeout in seconds');
    stdout.writeln('  -h, --help           Show this help');
  }

  _ReqArgsParseResult _parseArgs(List<String> args) {
    int? kind;
    int limit = 10;
    int timeoutSeconds = 12;
    final relays = <String>[];

    int i = 0;
    while (i < args.length) {
      final arg = args[i];

      if (arg == '-k' || arg == '--kind') {
        i++;
        if (i >= args.length) {
          return _ReqArgsParseResult(error: 'Missing value for $arg');
        }
        final parsedKind = int.tryParse(args[i]);
        if (parsedKind == null) {
          return _ReqArgsParseResult(
            error: 'Invalid kind value "${args[i]}"',
          );
        }
        kind = parsedKind;
      } else if (arg == '-l' || arg == '--limit') {
        i++;
        if (i >= args.length) {
          return _ReqArgsParseResult(error: 'Missing value for $arg');
        }
        final parsedLimit = int.tryParse(args[i]);
        if (parsedLimit == null || parsedLimit <= 0) {
          return _ReqArgsParseResult(
            error: 'Invalid limit value "${args[i]}"',
          );
        }
        limit = parsedLimit;
      } else if (arg == '-t' || arg == '--timeout') {
        i++;
        if (i >= args.length) {
          return _ReqArgsParseResult(error: 'Missing value for $arg');
        }
        final parsedTimeout = int.tryParse(args[i]);
        if (parsedTimeout == null || parsedTimeout <= 0) {
          return _ReqArgsParseResult(
            error: 'Invalid timeout value "${args[i]}"',
          );
        }
        timeoutSeconds = parsedTimeout;
      } else if (arg.startsWith('-')) {
        return _ReqArgsParseResult(error: 'Unknown option: $arg');
      } else {
        final cleanedRelay = _parseRelay(arg);
        if (cleanedRelay == null) {
          return _ReqArgsParseResult(error: 'Invalid relay URL: $arg');
        }
        relays.add(cleanedRelay);
      }

      i++;
    }

    if (relays.isEmpty) {
      return _ReqArgsParseResult(error: 'At least one relay URL is required.');
    }

    return _ReqArgsParseResult(
      kind: kind,
      limit: limit,
      timeoutSeconds: timeoutSeconds,
      relays: relays,
    );
  }

  String? _parseRelay(String value) {
    final direct = cleanRelayUrl(value);
    if (direct != null) {
      return direct;
    }
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
}

class _ReqArgsParseResult {
  final int? kind;
  final int limit;
  final int timeoutSeconds;
  final List<String> relays;
  final String? error;

  _ReqArgsParseResult({
    this.kind,
    this.limit = 10,
    this.timeoutSeconds = 12,
    this.relays = const [],
    this.error,
  });
}
