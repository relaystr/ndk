import 'dart:convert';
import 'dart:io';

import 'package:ndk/ndk.dart';
import 'package:path/path.dart' as p;

/// Persisted CLI account record.
///
/// Private keys and bunker connection secrets are stored in PLAINTEXT at
/// [CliAccountsStore.defaultPath] (`~/.ndk/accounts.json`, file mode 0600).
/// This is acceptable for a local dev/CLI tool but you should not commit or
/// share this file.
class CliAccountRecord {
  final String pubkey;
  final CliAccountType type;

  /// hex private key. Only set for [CliAccountType.privateKey].
  final String? privkey;

  /// Serialized [BunkerConnection]. Only set for [CliAccountType.bunker].
  final Map<String, dynamic>? bunker;

  CliAccountRecord({
    required this.pubkey,
    required this.type,
    this.privkey,
    this.bunker,
  });

  bool get canSign =>
      type == CliAccountType.privateKey || type == CliAccountType.bunker;

  Map<String, dynamic> toJson() => {
        'pubkey': pubkey,
        'type': type.name,
        if (privkey != null) 'privkey': privkey,
        if (bunker != null) 'bunker': bunker,
      };

  factory CliAccountRecord.fromJson(Map<String, dynamic> json) {
    final type = CliAccountType.values.firstWhere(
      (t) => t.name == json['type'],
      orElse: () => CliAccountType.publicKey,
    );
    return CliAccountRecord(
      pubkey: json['pubkey'] as String,
      type: type,
      privkey: json['privkey'] as String?,
      bunker: json['bunker'] as Map<String, dynamic>?,
    );
  }
}

enum CliAccountType { privateKey, publicKey, bunker }

/// On-disk store of CLI accounts. Single-process safe; not concurrency-locked.
class CliAccountsStore {
  static const String _defaultDirName = '.ndk';
  static const String _defaultFileName = 'accounts.json';

  final File _file;
  final List<CliAccountRecord> _records = [];
  String? defaultPubkey;
  bool _warnedOnCreate = false;

  CliAccountsStore._(this._file);

  /// Default path: `~/.ndk/accounts.json`. Override with the
  /// `NDK_ACCOUNTS_FILE` environment variable.
  static String defaultPath() {
    final fromEnv = Platform.environment['NDK_ACCOUNTS_FILE'];
    if (fromEnv != null && fromEnv.isNotEmpty) return fromEnv;
    final home = Platform.environment['HOME'] ??
        Platform.environment['USERPROFILE'] ??
        '.';
    return p.join(home, _defaultDirName, _defaultFileName);
  }

  /// Load the store from [path] (defaults to [defaultPath]).
  /// Missing file is treated as empty store (not an error).
  static Future<CliAccountsStore> load({String? path}) async {
    final file = File(path ?? defaultPath());
    final store = CliAccountsStore._(file);
    if (await file.exists()) {
      try {
        final raw = await file.readAsString();
        final data = jsonDecode(raw) as Map<String, dynamic>;
        final list = data['accounts'] as List? ?? const [];
        for (final item in list) {
          store._records
              .add(CliAccountRecord.fromJson(item as Map<String, dynamic>));
        }
        store.defaultPubkey = data['defaultPubkey'] as String?;
      } catch (e) {
        stderr.writeln('warning: failed to parse ${file.path}: $e');
      }
    }
    return store;
  }

  List<CliAccountRecord> get records => List.unmodifiable(_records);

  CliAccountRecord? get defaultRecord {
    if (defaultPubkey == null) return null;
    for (final r in _records) {
      if (r.pubkey == defaultPubkey) return r;
    }
    return null;
  }

  CliAccountRecord? find(String pubkey) {
    for (final r in _records) {
      if (r.pubkey == pubkey) return r;
    }
    return null;
  }

  void upsert(CliAccountRecord record, {bool setDefault = true}) {
    final idx = _records.indexWhere((r) => r.pubkey == record.pubkey);
    if (idx >= 0) {
      _records[idx] = record;
    } else {
      _records.add(record);
    }
    if (setDefault || defaultPubkey == null) {
      defaultPubkey = record.pubkey;
    }
  }

  void remove(String pubkey) {
    _records.removeWhere((r) => r.pubkey == pubkey);
    if (defaultPubkey == pubkey) {
      defaultPubkey = _records.isEmpty ? null : _records.first.pubkey;
    }
  }

  void setDefault(String pubkey) {
    if (find(pubkey) == null) {
      throw ArgumentError('Unknown pubkey: $pubkey');
    }
    defaultPubkey = pubkey;
  }

  Future<void> save() async {
    final dir = _file.parent;
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    final alreadyExisted = await _file.exists();
    final data = {
      'defaultPubkey': defaultPubkey,
      'accounts': _records.map((r) => r.toJson()).toList(),
    };
    await _file.writeAsString(jsonEncode(data));
    if (!alreadyExisted) {
      await _file.parent.stat();
    }
    try {
      // best-effort chmod 0600 on POSIX
      if (!Platform.isWindows) {
        final result = await Process.run('chmod', ['600', _file.path]);
        if (result.exitCode != 0 && !_warnedOnCreate) {
          _warnedOnCreate = true;
        }
      }
    } catch (_) {
      // ignore chmod failures
    }
    if (!alreadyExisted) {
      stderr.writeln(
          'warning: wrote plaintext signing material to ${_file.path} (mode 600).');
      stderr.writeln('         Do not commit or share this file.');
    }
  }
}

/// Bridges [CliAccountsStore] -> [Accounts] usecase at startup.
///
/// Returns the list of pubkeys that were restored. The first record becomes the
/// logged-in (active) account, mirroring [CliAccountsStore.defaultPubkey].
Future<List<String>> restoreAccountsIntoNdk({
  required Ndk ndk,
  required CliAccountsStore store,
}) async {
  final restored = <String>[];
  var first = true;
  for (final record in store.records) {
    try {
      switch (record.type) {
        case CliAccountType.privateKey:
          if (record.privkey != null) {
            ndk.accounts.loginPrivateKey(
              pubkey: record.pubkey,
              privkey: record.privkey!,
            );
          }
          break;
        case CliAccountType.publicKey:
          ndk.accounts.loginPublicKey(pubkey: record.pubkey);
          break;
        case CliAccountType.bunker:
          if (record.bunker != null) {
            final connection = BunkerConnection.fromJson(record.bunker!);
            await ndk.accounts.loginWithBunkerConnection(
              connection: connection,
              bunkers: ndk.bunkers,
            );
          }
          break;
      }
      restored.add(record.pubkey);
      if (first) {
        first = false;
      }
    } catch (e) {
      stderr.writeln('warning: failed to restore account ${record.pubkey}: $e');
    }
  }
  final wanted = store.defaultPubkey;
  if (wanted != null && restored.contains(wanted)) {
    try {
      ndk.accounts.switchAccount(pubkey: wanted);
    } catch (_) {
      // ignore
    }
  }
  return restored;
}
