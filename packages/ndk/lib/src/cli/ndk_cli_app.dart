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
    if (args.isEmpty) {
      printHelp();
      return 0;
    }

    final commandName = args.first.toLowerCase();
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
    final ndk = _createNdk(walletsRepo);
    try {
      return await command.run(args.sublist(1), ndk, walletsRepo);
    } finally {
      await ndk.destroy();
    }
  }

  void printHelp([IOSink? out]) {
    out ??= stdout;
    out.writeln('$appName - $description');
    out.writeln('Usage: ndk <command> [args]');
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

  Ndk _createNdk(WalletsRepo walletsRepo) {
    Logger.setLogLevel(LogLevel.error);
    return Ndk(
      NdkConfig(
        cache: MemCacheManager(),
        walletsRepo: walletsRepo,
        eventVerifier: _CliEventVerifier(),
        bootstrapRelays: const [],
        logLevel: LogLevel.error,
      ),
    );
  }
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
