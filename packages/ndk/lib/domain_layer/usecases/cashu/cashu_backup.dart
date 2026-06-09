import 'dart:convert';

import '../../../shared/logger/logger.dart';
import '../../entities/cashu/cashu_keyset.dart';
import '../../entities/cashu/cashu_mint_info.dart';
import '../../entities/cashu/cashu_proof.dart';
import '../../entities/wallet/wallet_transaction.dart';
import '../../entities/wallet/wallet_type.dart';
import '../../repositories/wallets_repo.dart';
import 'cashu_cache_decorator.dart';
import 'cashu_seed.dart';

/// Full backup / restore of all local cashu state.
///
/// A backup is a plain JSON document containing everything required to restore
/// a wallet on a fresh device:
///  - the BIP39 seed phrase (controls all funds, derives deterministic secrets)
///  - unspent (and optionally spent/pending) proofs (the actual ecash)
///  - NUT-13 derivation counters (so newly minted secrets don't collide)
///  - cached keysets and mint infos (re-fetchable, kept for offline restore)
///  - transaction history (not recoverable from the network)
///
/// SECURITY: a backup that includes the seed phrase grants full control over
/// the funds. Treat the exported document like a private key. Set
/// [includeSeedPhrase] to false to produce a non-custodial backup that still
/// needs the original seed to spend.
class CashuStateExportImport {
  /// bump when the on-disk format changes incompatibly
  static const int backupVersion = 1;
  static const String backupType = 'ndk-cashu-backup';

  final CashuCacheDecorator _cacheManagerCashu;

  final WalletsRepo _walletsRepo;
  final CashuSeed _cashuSeed;

  CashuStateExportImport({
    required CashuCacheDecorator cacheManagerCashu,
    required WalletsRepo walletsRepo,
    required CashuSeed cashuSeed,
  })  : _cacheManagerCashu = cacheManagerCashu,
        _walletsRepo = walletsRepo,
        _cashuSeed = cashuSeed;

  /// Export all cashu state as a JSON-serializable map.
  ///
  /// [includeSeedPhrase] - include the BIP39 seed phrase (default false). The
  /// seed is a global, wallet-independent secret managed separately (e.g. via
  /// [CashuSeed] / secure storage); it is normally backed up on its own and not
  /// bundled with the per-mint cashu database. Enable only if you explicitly
  /// want a single self-contained backup, and treat the result like a private
  /// key.
  /// [includeTransactions] - include the cashu transaction history (default
  /// true). History is informational and not required to recover funds.
  Future<Map<String, dynamic>> exportToMap({
    bool includeSeedPhrase = false,
    bool includeTransactions = true,
  }) async {
    final mintInfos =
        await _cacheManagerCashu.getMintInfos() ?? <CashuMintInfo>[];
    final keysets = await _cacheManagerCashu.getKeysets();

    // mints we have any local state for: derived from keysets and mint infos
    final mintUrls = <String>{
      ...keysets.map((k) => k.mintUrl),
      ...mintInfos.expand((m) => m.urls),
    };

    // proofs are stored per mint and queried per state; collect all states so
    // pending / spent history survives the round-trip too
    final proofsJson = <Map<String, dynamic>>[];
    for (final mintUrl in mintUrls) {
      for (final state in CashuProofState.values) {
        final proofs = await _cacheManagerCashu.getProofs(
          mintUrl: mintUrl,
          state: state,
        );
        for (final proof in proofs) {
          proofsJson.add({
            'id': proof.keysetId,
            'amount': proof.amount,
            'secret': proof.secret,
            'C': proof.unblindedSig,
            'state': proof.state.value,
            'mintUrl': mintUrl,
          });
        }
      }
    }

    // NUT-13 derivation counters, one per keyset
    final countersJson = <Map<String, dynamic>>[];
    for (final keyset in keysets) {
      final counter = await _cacheManagerCashu.getCashuSecretCounter(
        mintUrl: keyset.mintUrl,
        keysetId: keyset.id,
      );
      countersJson.add({
        'mintUrl': keyset.mintUrl,
        'keysetId': keyset.id,
        'counter': counter,
      });
    }

    final backup = <String, dynamic>{
      'type': backupType,
      'version': backupVersion,
      'createdAt': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'mintInfos': mintInfos.map((m) => m.toJson()).toList(),
      'keysets': keysets.map((k) => k.toJson()).toList(),
      'proofs': proofsJson,
      'counters': countersJson,
    };

    if (includeSeedPhrase) {
      try {
        backup['seedPhrase'] = _cashuSeed.getSeedPhrase().sentence;
      } catch (_) {
        Logger.log.w(() =>
            'Cashu backup: no seed phrase set, exporting without it. The backup will not be restorable on a new device.');
      }
    }

    if (includeTransactions) {
      final transactions = await _walletsRepo.getTransactions(
        walletType: WalletType.CASHU,
      );
      backup['transactions'] = transactions.map(_transactionToJson).toList();
    }

    return backup;
  }

  /// Export all cashu state as a JSON string. See [exportToMap].
  Future<String> exportToJsonString({
    bool includeSeedPhrase = false,
    bool includeTransactions = true,
    bool pretty = true,
  }) async {
    final map = await exportToMap(
      includeSeedPhrase: includeSeedPhrase,
      includeTransactions: includeTransactions,
    );
    if (pretty) {
      return const JsonEncoder.withIndent('  ').convert(map);
    }
    return jsonEncode(map);
  }

  /// Restore cashu state from a backup [json] produced by [exportToMap].
  ///
  /// Restored data is merged into the existing local state (saves overwrite by
  /// key, they do not wipe other mints first).
  ///
  /// [restoreSeedPhrase] - load the backed-up seed phrase into the running
  /// [CashuSeed] (default true). NOTE: this only sets the in-memory seed; the
  /// caller is responsible for persisting it to secure storage. The seed phrase
  /// is also returned in [CashuBackupRestoreResult] for that purpose.
  /// [restoreTransactions] - restore the transaction history (default true).
  Future<CashuBackupRestoreResult> importFromMap(
    Map<String, dynamic> json, {
    bool restoreSeedPhrase = true,
    bool restoreTransactions = true,
  }) async {
    final type = json['type'];
    if (type != backupType) {
      throw ArgumentError(
          'Not a cashu backup: expected type "$backupType", got "$type"');
    }
    final version = json['version'];
    if (version is! int || version > backupVersion) {
      throw ArgumentError(
          'Unsupported backup version: $version (this build supports up to $backupVersion)');
    }

    String? restoredSeedPhrase;
    final seedPhrase = json['seedPhrase'];
    if (seedPhrase is String && seedPhrase.trim().isNotEmpty) {
      restoredSeedPhrase = seedPhrase;
      if (restoreSeedPhrase) {
        await _cashuSeed.setSeedPhrase(seedPhrase: seedPhrase);
      }
    }

    // mint infos
    final mintInfos = (json['mintInfos'] as List?) ?? const [];
    for (final m in mintInfos) {
      await _cacheManagerCashu.saveMintInfo(
        mintInfo: CashuMintInfo.fromJson(m as Map<String, dynamic>),
      );
    }

    // keysets
    final keysets = (json['keysets'] as List?) ?? const [];
    for (final k in keysets) {
      await _cacheManagerCashu.saveKeyset(
        CahsuKeyset.fromJson(k as Map<String, dynamic>),
      );
    }

    // proofs, grouped by mint url (saveProofs is per mint)
    final proofs = (json['proofs'] as List?) ?? const [];
    final proofsByMint = <String, List<CashuProof>>{};
    for (final p in proofs) {
      final map = p as Map<String, dynamic>;
      final mintUrl = map['mintUrl'] as String;
      (proofsByMint[mintUrl] ??= []).add(
        CashuProof(
          keysetId: map['id'] as String,
          amount: map['amount'] as int,
          secret: map['secret'] as String,
          unblindedSig: map['C'] as String,
          state:
              CashuProofState.fromValue(map['state'] as String? ?? 'UNSPENT'),
        ),
      );
    }
    var restoredProofs = 0;
    for (final entry in proofsByMint.entries) {
      await _cacheManagerCashu.saveProofs(
        proofs: entry.value,
        mintUrl: entry.key,
      );
      restoredProofs += entry.value.length;
    }

    // NUT-13 derivation counters
    final counters = (json['counters'] as List?) ?? const [];
    for (final c in counters) {
      final map = c as Map<String, dynamic>;
      await _cacheManagerCashu.setCashuSecretCounter(
        mintUrl: map['mintUrl'] as String,
        keysetId: map['keysetId'] as String,
        counter: map['counter'] as int,
      );
    }

    // transactions
    var restoredTransactions = 0;
    if (restoreTransactions) {
      final transactions = (json['transactions'] as List?) ?? const [];
      final parsed = transactions
          .map((t) => _transactionFromJson(t as Map<String, dynamic>))
          .toList();
      if (parsed.isNotEmpty) {
        await _walletsRepo.saveTransactions(parsed);
        restoredTransactions = parsed.length;
      }
    }

    Logger.log.i(() =>
        'Cashu backup restored: $restoredProofs proofs, ${keysets.length} keysets, ${mintInfos.length} mint infos, $restoredTransactions transactions');

    return CashuBackupRestoreResult(
      seedPhrase: restoredSeedPhrase,
      restoredProofs: restoredProofs,
      restoredKeysets: keysets.length,
      restoredMintInfos: mintInfos.length,
      restoredTransactions: restoredTransactions,
    );
  }

  /// Restore cashu state from a backup JSON string. See [importFromMap].
  Future<CashuBackupRestoreResult> importFromJsonString(
    String jsonString, {
    bool restoreSeedPhrase = true,
    bool restoreTransactions = true,
  }) {
    final decoded = jsonDecode(jsonString);
    if (decoded is! Map<String, dynamic>) {
      throw ArgumentError('Backup JSON must be an object');
    }
    return importFromMap(
      decoded,
      restoreSeedPhrase: restoreSeedPhrase,
      restoreTransactions: restoreTransactions,
    );
  }

  Map<String, dynamic> _transactionToJson(WalletTransaction tx) {
    return {
      'id': tx.id,
      'walletId': tx.walletId,
      'changeAmount': tx.changeAmount,
      'unit': tx.unit,
      'walletType': tx.walletType.value,
      'state': tx.state.value,
      'completionMsg': tx.completionMsg,
      'transactionDate': tx.transactionDate,
      'initiatedDate': tx.initiatedDate,
      'metadata': tx.metadata,
    };
  }

  WalletTransaction _transactionFromJson(Map<String, dynamic> json) {
    return WalletTransaction.toTransactionType(
      id: json['id'] as String,
      walletId: json['walletId'] as String,
      changeAmount: json['changeAmount'] as int,
      unit: json['unit'] as String,
      walletType: WalletType.fromValue(json['walletType'] as String),
      state: WalletTransactionState.fromValue(json['state'] as String),
      metadata: (json['metadata'] as Map?)?.cast<String, dynamic>() ?? {},
      completionMsg: json['completionMsg'] as String?,
      transactionDate: json['transactionDate'] as int?,
      initiatedDate: json['initiatedDate'] as int?,
    );
  }
}

/// Summary of what [CashuStateExportImport.importFromMap] restored.
class CashuBackupRestoreResult {
  /// the seed phrase contained in the backup, if any. The caller should
  /// persist this to secure storage to complete the restore.
  final String? seedPhrase;
  final int restoredProofs;
  final int restoredKeysets;
  final int restoredMintInfos;
  final int restoredTransactions;

  CashuBackupRestoreResult({
    required this.seedPhrase,
    required this.restoredProofs,
    required this.restoredKeysets,
    required this.restoredMintInfos,
    required this.restoredTransactions,
  });
}
