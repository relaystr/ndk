import 'dart:io';

import 'package:ndk/data_layer/repositories/wallets/sembast_wallets_repo.dart';
import 'package:ndk/domain_layer/repositories/wallets_repo.dart';
import 'package:ndk/ndk.dart';

import 'cli_command.dart';

class NdkCliApp {
  final String appName;
  final String description;
  final List<CliCommand> commands;

  NdkCliApp({
    required this.appName,
    required this.description,
    required this.commands,
  });

  Future<int> run(List<String> args) async {
    final globalOptions = _parseGlobalOptions(args);
    if (globalOptions.error != null) {
      stderr.writeln(globalOptions.error);
      stderr.writeln('');
      printHelp(stderr);
      return 2;
    }

    if (globalOptions.showVersion) {
      stdout.writeln(packageVersion);
      return 0;
    }

    if (globalOptions.commandArgs.isEmpty) {
      printHelp();
      return 0;
    }

    final commandName = globalOptions.commandArgs.first.toLowerCase();
    if (_isHelp(commandName)) {
      printHelp();
      return 0;
    }

    final command = _findCommand(commandName);
    if (command == null) {
      stderr.writeln('Unknown command: "$commandName"');
      stderr.writeln('');
      printHelp(stderr);
      return 2;
    }

    final walletsRepo = await _createWalletsRepo();
    final ndk = _createNdk(walletsRepo, globalOptions.logLevel);
    try {
      return await command.run(
          globalOptions.commandArgs.sublist(1), ndk, walletsRepo);
    } finally {
      await ndk.destroy();
    }
  }

  void printHelp([IOSink? out]) {
    out ??= stdout;
    out.writeln('$appName - $description');
    out.writeln('Usage: ndk [global options] <command> [args]');
    out.writeln('Global options:');
    out.writeln('  --version            Show package version');
    out.writeln('  -v                   Warning-level logging');
    out.writeln('  -vv                  Info-level logging');
    out.writeln('  -vvv                 Debug-level logging');
    out.writeln('  -h, --help           Show this help');
    out.writeln('');
    out.writeln('Commands:');
    for (final command in commands) {
      out.writeln('  ${command.name.padRight(12)} ${command.description}');
    }
    out.writeln('  help         Show this help');
    out.writeln('');
    out.writeln('Use "ndk <command> --help" for command details.');
  }

  bool _isHelp(String value) {
    return value == 'help' || value == '--help' || value == '-h';
  }

  CliCommand? _findCommand(String commandName) {
    for (final command in commands) {
      if (command.name == commandName) {
        return command;
      }
    }
    return null;
  }

  Future<WalletsRepo> _createWalletsRepo() {
    return SembastWalletsRepo.create(
      filename: 'wallets_db.db',
    );
  }

  Ndk _createNdk(WalletsRepo walletsRepo, LogLevel logLevel) {
    Logger.setLogLevel(logLevel);
    return Ndk(
      NdkConfig(
        cache: MemCacheManager(),
        walletsRepo: walletsRepo,
        eventVerifier: _CliEventVerifier(),
        bootstrapRelays: const [],
        logLevel: logLevel,
      ),
    );
  }

  _GlobalCliOptions _parseGlobalOptions(List<String> args) {
    var verbosity = 0;
    var showVersion = false;
    var index = 0;

    while (index < args.length) {
      final value = args[index];
      if (value == '--version' || value == '-V') {
        showVersion = true;
        index++;
        continue;
      }
      if (value == '-v') {
        verbosity = 1;
        index++;
        continue;
      }
      if (value == '-vv') {
        verbosity = 2;
        index++;
        continue;
      }
      if (value == '-vvv') {
        verbosity = 3;
        index++;
        continue;
      }

      break;
    }

    final remaining = args.sublist(index);
    for (final value in remaining) {
      if (value == '--version' || value == '-V') {
        return _GlobalCliOptions(
            error: '--version must be provided before the command name.');
      }
      if (value == '-v' || value == '-vv' || value == '-vvv') {
        return _GlobalCliOptions(
            error: '$value must be provided before the command name.');
      }
    }

    return _GlobalCliOptions(
      showVersion: showVersion,
      logLevel: _logLevelForVerbosity(verbosity),
      commandArgs: remaining,
    );
  }

  LogLevel _logLevelForVerbosity(int verbosity) {
    if (verbosity >= 3) {
      return LogLevel.debug;
    }
    if (verbosity == 2) {
      return LogLevel.info;
    }
    if (verbosity == 1) {
      return LogLevel.warning;
    }
    return LogLevel.error;
  }
}

class _GlobalCliOptions {
  final bool showVersion;
  final LogLevel logLevel;
  final List<String> commandArgs;
  final String? error;

  const _GlobalCliOptions({
    this.showVersion = false,
    this.logLevel = LogLevel.error,
    this.commandArgs = const [],
    this.error,
  });
}

class _CliEventVerifier implements EventVerifier {
  final RustEventVerifier _rustVerifier = RustEventVerifier();
  final Bip340EventVerifier _fallbackVerifier = Bip340EventVerifier();
  bool _useFallback = false;
  bool _loggedFallback = false;

  @override
  Future<bool> verify(Nip01Event event) async {
    if (_useFallback) {
      return _fallbackVerifier.verify(event);
    }

    try {
      return await _rustVerifier.verify(event);
    } on UnsupportedError {
      _enableFallback();
      return _fallbackVerifier.verify(event);
    } on ArgumentError catch (error) {
      if (!_isNativeLibraryLoadError(error)) {
        rethrow;
      }
      _enableFallback();
      return _fallbackVerifier.verify(event);
    }
  }

  bool _isNativeLibraryLoadError(ArgumentError error) {
    final message = error.toString().toLowerCase();
    return message.contains('dynamic library') ||
        message.contains('verify_nostr_event') ||
        message.contains('failed to load');
  }

  void _enableFallback() {
    _useFallback = true;
    if (_loggedFallback) {
      return;
    }
    _loggedFallback = true;
    stderr.writeln(
      'Rust verifier unavailable; falling back to Bip340EventVerifier.',
    );
  }
}
