import 'dart:io';

import 'package:ndk/domain_layer/repositories/wallets_repo.dart';
import 'package:ndk/entities.dart';
import 'package:ndk/ndk.dart';

import '../cli_accounts_store.dart';
import '../cli_command.dart';

class WalletsCliCommand implements CliCommand {
  @override
  String get name => 'wallets';

  @override
  String get description =>
      'Wallet operations (list, add, remove, receive, send, balance, budget)';

  @override
  String get usage =>
      'wallets <list|add|remove|receive|send|balance|budget> [args]';

  @override
  Future<int> run(
    List<String> args,
    Ndk ndk,
    WalletsRepo walletsRepo,
    CliAccountsStore accountsStore,
  ) async {
    if (args.isEmpty || _isHelp(args.first)) {
      _printHelp();
      return 0;
    }

    try {
      final subCommand = args.first.toLowerCase();
      final subArgs = args.sublist(1);
      final walletsUsecase = ndk.wallets;

      if (subCommand == 'list') {
        await _handleList(walletsRepo, walletsUsecase);
        return 0;
      }

      if (subCommand == 'add') {
        await _handleAdd(subArgs, walletsRepo, walletsUsecase, ndk);
        return 0;
      }

      if (subCommand == 'remove') {
        await _handleRemove(subArgs, walletsRepo, walletsUsecase);
        return 0;
      }

      if (subCommand == 'receive') {
        await _handleReceive(subArgs, walletsUsecase);
        return 0;
      }

      if (subCommand == 'send') {
        await _handleSend(subArgs, walletsUsecase);
        return 0;
      }

      if (subCommand == 'balance') {
        await _handleBalance(subArgs, walletsRepo, walletsUsecase);
        return 0;
      }

      if (subCommand == 'budget') {
        await _handleBudget(subArgs, walletsRepo, walletsUsecase, ndk);
        return 0;
      }

      if (subCommand == 'set-default') {
        await _handleSetDefault(subArgs, walletsRepo, walletsUsecase);
        return 0;
      }

      if (subCommand == 'melt') {
        await _handleMelt(subArgs, walletsRepo, walletsUsecase, ndk);
        return 0;
      }

      if (subCommand == 'mint') {
        await _handleMint(subArgs, walletsRepo, walletsUsecase, ndk);
        return 0;
      }

      if (subCommand == 'swap-receive') {
        await _handleSwapReceive(subArgs, ndk);
        return 0;
      }

      if (subCommand == 'swap-spend') {
        await _handleSwapSpend(subArgs, walletsRepo, walletsUsecase, ndk);
        return 0;
      }

      if (subCommand == 'pay-stats') {
        await _handlePayStats(subArgs, walletsRepo, walletsUsecase, ndk);
        return 0;
      }

      stderr.writeln('Unknown wallets sub-command: "$subCommand"');
      _printHelp(stderr);
      return 2;
    } catch (e) {
      stderr.writeln('Wallets command failed: $e');
      return 1;
    }
  }

  Future<void> _handleList(
    WalletsRepo walletsRepo,
    Wallets walletsUsecase,
  ) async {
    final wallets = await walletsRepo.getWallets();
    _printWallets(wallets, walletsUsecase);
  }

  Future<void> _handleAdd(
    List<String> args,
    WalletsRepo walletsRepo,
    Wallets walletsUsecase,
    Ndk ndk,
  ) async {
    if (args.length < 2) {
      stderr.writeln('Usage: ndk wallets add <nwc|cashu> <connection> [name]');
      throw ArgumentError('Missing required arguments for wallets add');
    }

    final walletType = args[0].toLowerCase();
    if (walletType == 'nwc') {
      await _handleAddNwc(args, walletsRepo, walletsUsecase);
      return;
    }

    if (walletType == 'cashu') {
      await _handleAddCashu(args, walletsRepo, walletsUsecase, ndk);
      return;
    }

    throw ArgumentError(
      'Unsupported wallet type: "$walletType" (supported: "nwc", "cashu")',
    );
  }

  Future<void> _handleAddNwc(
    List<String> args,
    WalletsRepo walletsRepo,
    Wallets walletsUsecase,
  ) async {
    final nwcUri = args[1];
    NostrWalletConnectUri.parseConnectionUri(nwcUri);

    final wallets = await walletsRepo.getWallets();
    final defaultName = 'NWC ${wallets.length + 1}';
    final walletName =
        args.length > 2 ? args.sublist(2).join(' ') : defaultName;

    final wallet = walletsUsecase.createWallet(
      id: _buildWalletId(),
      name: walletName,
      type: WalletType.NWC,
      supportedUnits: {'sat'},
      metadata: {'nwcUrl': nwcUri},
    );

    await walletsUsecase.addWallet(wallet);

    stdout
        .writeln('Added wallet: id=${wallet.id} name=${wallet.name} type=nwc');
    final updatedWallets = await walletsRepo.getWallets();
    _printWallets(updatedWallets, walletsUsecase);
  }

  Future<void> _handleAddCashu(
    List<String> args,
    WalletsRepo walletsRepo,
    Wallets walletsUsecase,
    Ndk ndk,
  ) async {
    final mintUrl = args[1].trim();
    if (mintUrl.isEmpty) {
      throw ArgumentError('mintUrl must not be empty');
    }

    final mintInfo = await ndk.cashu.getMintInfoNetwork(mintUrl: mintUrl);
    final wallets = await walletsRepo.getWallets();
    final defaultName = 'Cashu ${wallets.length + 1}';
    final walletName =
        args.length > 2 ? args.sublist(2).join(' ') : defaultName;
    final supportedUnits = mintInfo.supportedUnits.isEmpty
        ? <String>{'sat'}
        : mintInfo.supportedUnits;

    final wallet = walletsUsecase.createWallet(
      id: _buildWalletId(),
      name: walletName,
      type: WalletType.CASHU,
      supportedUnits: supportedUnits,
      metadata: {
        'mintUrl': mintUrl,
        'mintInfo': mintInfo.toJson(),
      },
    );

    await walletsUsecase.addWallet(wallet);

    stdout.writeln(
      'Added wallet: id=${wallet.id} name=${wallet.name} type=cashu mint=$mintUrl',
    );
    final updatedWallets = await walletsRepo.getWallets();
    _printWallets(updatedWallets, walletsUsecase);
  }

  Future<void> _handleRemove(
    List<String> args,
    WalletsRepo walletsRepo,
    Wallets walletsUsecase,
  ) async {
    if (args.length != 1) {
      stderr.writeln('Usage: ndk wallets remove <walletId>');
      throw ArgumentError('Missing wallet id for wallets remove');
    }

    final walletId = args[0];
    final wallets = await walletsRepo.getWallets();
    final exists = wallets.any((wallet) => wallet.id == walletId);
    if (!exists) {
      throw ArgumentError('Wallet not found: $walletId');
    }

    await walletsUsecase.removeWallet(walletId);

    stdout.writeln('Removed wallet: $walletId');
    final updatedWallets = await walletsRepo.getWallets();
    _printWallets(updatedWallets, walletsUsecase);
  }

  Future<void> _handleReceive(
    List<String> args,
    Wallets walletsUsecase,
  ) async {
    if (args.isEmpty || args.length > 2) {
      stderr.writeln('Usage: ndk wallets receive <amountSats> [walletId]');
      throw ArgumentError('Invalid arguments for wallets receive');
    }

    final amountSats = int.tryParse(args[0]);
    if (amountSats == null || amountSats <= 0) {
      throw ArgumentError('amountSats must be a positive integer');
    }

    final walletId = args.length == 2 ? args[1] : null;
    final invoice = await walletsUsecase.receive(
      walletId: walletId,
      amountSats: amountSats,
    );

    stdout.writeln('Invoice ($amountSats sats):');
    stdout.writeln(invoice);
  }

  Future<void> _handleSend(
    List<String> args,
    Wallets walletsUsecase,
  ) async {
    if (args.isEmpty || args.length > 2) {
      stderr.writeln('Usage: ndk wallets send <bolt11> [walletId]');
      throw ArgumentError('Invalid arguments for wallets send');
    }

    final invoice = args[0].trim();
    if (invoice.isEmpty) {
      throw ArgumentError('bolt11 invoice must not be empty');
    }

    final walletId = args.length == 2 ? args[1] : null;
    final response = await walletsUsecase.send(
      walletId: walletId,
      invoice: invoice,
    );

    stdout.writeln('Payment sent:');
    stdout.writeln('- preimage: ${response.preimage}');
    stdout.writeln('- fees paid: ${response.feesPaid} msats');
    if (response.errorCode != null || response.errorMessage != null) {
      stdout.writeln('- error code: ${response.errorCode}');
      stdout.writeln('- error message: ${response.errorMessage}');
    }
  }

  Future<void> _handleBalance(
    List<String> args,
    WalletsRepo walletsRepo,
    Wallets walletsUsecase,
  ) async {
    if (args.length > 1) {
      stderr.writeln('Usage: ndk wallets balance [walletId]');
      throw ArgumentError('Invalid arguments for wallets balance');
    }

    final wallets = await walletsRepo.getWallets();
    if (wallets.isEmpty) {
      throw StateError('No wallets available');
    }

    String walletId;
    if (args.isNotEmpty) {
      walletId = args[0];
      final exists = wallets.any((wallet) => wallet.id == walletId);
      if (!exists) {
        throw ArgumentError('Wallet not found: $walletId');
      }
    } else {
      walletId =
          walletsUsecase.defaultWalletForReceiving?.id ?? wallets.first.id;
    }

    final balances = await walletsUsecase
        .getBalancesStream(walletId)
        .first
        .timeout(const Duration(seconds: 12));

    if (balances.isEmpty) {
      stdout.writeln('No balances available for wallet: $walletId');
      return;
    }

    stdout.writeln('Balances for $walletId:');
    for (final balance in balances) {
      stdout.writeln('- ${balance.amount} ${balance.unit}');
    }
  }

  Future<void> _handleBudget(
    List<String> args,
    WalletsRepo walletsRepo,
    Wallets walletsUsecase,
    Ndk ndk,
  ) async {
    if (args.length > 1) {
      stderr.writeln('Usage: ndk wallets budget [walletId]');
      throw ArgumentError('Invalid arguments for wallets budget');
    }

    final wallets = await walletsRepo.getWallets();
    if (wallets.isEmpty) {
      throw StateError('No wallets available');
    }

    final walletId = args.isNotEmpty
        ? args[0]
        : (walletsUsecase.defaultWalletForReceiving?.id ?? wallets.first.id);

    final wallet = wallets.firstWhere(
      (w) => w.id == walletId,
      orElse: () => throw ArgumentError('Wallet not found: $walletId'),
    );

    if (wallet.type != WalletType.NWC) {
      throw ArgumentError(
        'Budget is only supported for NWC wallets (got ${wallet.type.value})',
      );
    }

    final nwcUrl = wallet.metadata['nwcUrl'] as String?;
    if (nwcUrl == null || nwcUrl.isEmpty) {
      throw StateError('NWC wallet is missing metadata["nwcUrl"]');
    }

    final connection = await ndk.nwc.connect(nwcUrl, doGetInfoMethod: false);
    try {
      final budget = await ndk.nwc.getBudget(connection);
      final remainingSats = budget.totalBudgetSats - budget.userBudgetSats;

      stdout.writeln('Budget for ${wallet.id}:');
      stdout.writeln('- used: ${budget.userBudgetSats} sats');
      stdout.writeln('- total: ${budget.totalBudgetSats} sats');
      stdout.writeln('- remaining: $remainingSats sats');
      stdout.writeln('- renewal period: ${budget.renewalPeriod.plaintext}');
      if (budget.renewsAt != null) {
        final renewsAt =
            DateTime.fromMillisecondsSinceEpoch(budget.renewsAt! * 1000);
        stdout.writeln('- renews at: ${renewsAt.toIso8601String()}');
      }
    } finally {
      await ndk.nwc.disconnect(connection);
    }
  }

  Future<void> _handleSetDefault(
    List<String> args,
    WalletsRepo walletsRepo,
    Wallets walletsUsecase,
  ) async {
    if (args.isEmpty || args.length > 2) {
      stderr.writeln('Usage: ndk wallets set-default <walletId> '
          '[receive|send|both] (default: both)');
      throw ArgumentError('Invalid arguments for wallets set-default');
    }
    final walletId = args[0];
    final scope = args.length == 2 ? args[1].toLowerCase() : 'both';
    final wallets = await walletsRepo.getWallets();
    final exists = wallets.any((w) => w.id == walletId);
    if (!exists) {
      throw ArgumentError('Wallet not found: $walletId');
    }
    switch (scope) {
      case 'both':
        walletsUsecase.setDefaultWallet(walletId);
        break;
      case 'receive':
        walletsUsecase.setDefaultWalletForReceiving(walletId);
        break;
      case 'send':
        walletsUsecase.setDefaultWalletForSending(walletId);
        break;
      default:
        throw ArgumentError('Scope must be receive|send|both (got "$scope")');
    }
    stdout.writeln('Default ($scope) set to $walletId');
    final updated = await walletsRepo.getWallets();
    _printWallets(updated, walletsUsecase);
  }

  Future<void> _handleMelt(
    List<String> args,
    WalletsRepo walletsRepo,
    Wallets walletsUsecase,
    Ndk ndk,
  ) async {
    final parsed = _parseCashuOpArgs(
      args,
      usageLine: 'ndk wallets melt <bolt11> [walletId] [--seed <mnemonic>]',
      requireValue: true,
      valueName: 'bolt11',
    );
    if (parsed.error != null) {
      stderr.writeln(parsed.error);
      return;
    }
    final wallet = await _resolveCashuWallet(
      parsed.walletId,
      walletsRepo,
      walletsUsecase,
    );
    await _ensureSeed(ndk, parsed.seed);
    final mintUrl = wallet.metadata['mintUrl'] as String;

    stdout.writeln('Getting melt quote from $mintUrl ...');
    final draft = await ndk.cashu.initiateRedeem(
      mintUrl: mintUrl,
      request: parsed.value!,
      unit: 'sat',
      method: 'bolt11',
    );
    final meltQuote = draft.qouteMelt;
    if (meltQuote != null) {
      final fee = meltQuote.feeReserve ?? 0;
      stdout.writeln('Quote: amount=${meltQuote.amount} fee=$fee '
          'total=${meltQuote.amount + fee} sat');
    }
    stdout.writeln('Melting ...');
    await for (final tx in ndk.cashu.redeem(draftRedeemTransaction: draft)) {
      stdout.writeln('  state: ${tx.state.value}');
      if (tx.completionMsg != null) {
        stdout.writeln('  msg: ${tx.completionMsg}');
      }
      if (tx.state.isDone) break;
    }
  }

  Future<void> _handleMint(
    List<String> args,
    WalletsRepo walletsRepo,
    Wallets walletsUsecase,
    Ndk ndk,
  ) async {
    final parsed = _parseCashuOpArgs(
      args,
      usageLine: 'ndk wallets mint <amountSats> [walletId] '
          '[--seed <mnemonic>] [--wait]',
      requireValue: true,
      valueName: 'amountSats',
      allowWait: true,
    );
    if (parsed.error != null) {
      stderr.writeln(parsed.error);
      return;
    }
    final amount = int.tryParse(parsed.value!);
    if (amount == null || amount <= 0) {
      throw ArgumentError('amountSats must be a positive integer');
    }
    final wallet = await _resolveCashuWallet(
      parsed.walletId,
      walletsRepo,
      walletsUsecase,
    );
    await _ensureSeed(ndk, parsed.seed);
    final mintUrl = wallet.metadata['mintUrl'] as String;

    stdout.writeln('Requesting mint quote from $mintUrl for $amount sat ...');
    final draft = await ndk.cashu.initiateFund(
      mintUrl: mintUrl,
      amount: amount,
      unit: 'sat',
      method: 'bolt11',
    );
    final invoice = draft.qoute?.request;
    stdout.writeln('Pay this invoice to mint tokens:');
    stdout.writeln('  $invoice');
    if (!parsed.wait) {
      stdout.writeln('(quote saved; run again with --wait to poll and mint '
          'once paid)');
      return;
    }
    stdout.writeln('Polling until paid ... (Ctrl+C to abort)');
    await for (final tx in ndk.cashu.retrieveFunds(draftTransaction: draft)) {
      stdout.writeln('  state: ${tx.state.value}');
      if (tx.completionMsg != null) {
        stdout.writeln('  msg: ${tx.completionMsg}');
      }
      if (tx.state.isDone) break;
    }
  }

  Future<void> _handleSwapReceive(List<String> args, Ndk ndk) async {
    final parsed = _parseCashuOpArgs(
      args,
      usageLine: 'ndk wallets swap-receive <cashuToken> [--seed <mnemonic>]',
      requireValue: true,
      valueName: 'cashuToken',
    );
    if (parsed.error != null) {
      stderr.writeln(parsed.error);
      return;
    }
    await _ensureSeed(ndk, parsed.seed);
    stdout.writeln('Swapping incoming token ...');
    await for (final tx in ndk.cashu.receive(parsed.value!)) {
      stdout.writeln('  state: ${tx.state.value}');
      if (tx.completionMsg != null) {
        stdout.writeln('  msg: ${tx.completionMsg}');
      }
      if (tx.state.isDone) break;
    }
  }

  Future<void> _handleSwapSpend(
    List<String> args,
    WalletsRepo walletsRepo,
    Wallets walletsUsecase,
    Ndk ndk,
  ) async {
    final parsed = _parseCashuOpArgs(
      args,
      usageLine: 'ndk wallets swap-spend <amountSats> [walletId] '
          '[--seed <mnemonic>]',
      requireValue: true,
      valueName: 'amountSats',
    );
    if (parsed.error != null) {
      stderr.writeln(parsed.error);
      return;
    }
    final amount = int.tryParse(parsed.value!);
    if (amount == null || amount <= 0) {
      throw ArgumentError('amountSats must be a positive integer');
    }
    final wallet = await _resolveCashuWallet(
      parsed.walletId,
      walletsRepo,
      walletsUsecase,
    );
    await _ensureSeed(ndk, parsed.seed);
    final mintUrl = wallet.metadata['mintUrl'] as String;

    final result = await ndk.cashu.initiateSpend(
      mintUrl: mintUrl,
      amount: amount,
      unit: 'sat',
    );
    stdout.writeln('Created spendable token ($amount sat):');
    stdout.writeln(result.token.toV4TokenString());
  }

  Future<void> _handlePayStats(
    List<String> args,
    WalletsRepo walletsRepo,
    Wallets walletsUsecase,
    Ndk ndk,
  ) async {
    int? limit = 20;
    String? walletId;
    for (var i = 0; i < args.length; i++) {
      final a = args[i];
      if (a == '--limit' && i + 1 < args.length) {
        limit = int.tryParse(args[++i]);
        if (limit == null || limit <= 0) {
          throw ArgumentError('Invalid --limit "${args[i]}"');
        }
      } else if (walletId == null && !a.startsWith('-')) {
        walletId = a;
      } else {
        stderr.writeln('Usage: ndk wallets pay-stats [walletId] [--limit N]');
        return;
      }
    }
    final wallets = await walletsRepo.getWallets();
    if (wallets.isEmpty) {
      throw StateError('No wallets available');
    }
    final target = walletId ??
        walletsUsecase.defaultWalletForReceiving?.id ??
        wallets.first.id;
    final wallet = wallets.firstWhere(
      (w) => w.id == target,
      orElse: () => throw ArgumentError('Wallet not found: $target'),
    );

    stdout.writeln('Transactions for ${wallet.id} (${wallet.type.value}):');
    if (wallet.type == WalletType.NWC) {
      await _printNwcTransactions(ndk, wallet, limit);
    } else {
      await _printStoredTransactions(walletsUsecase, wallet.id, limit);
    }
  }

  Future<void> _printNwcTransactions(
    Ndk ndk,
    Wallet wallet,
    int? limit,
  ) async {
    final nwcUrl = wallet.metadata['nwcUrl'] as String?;
    if (nwcUrl == null || nwcUrl.isEmpty) {
      throw StateError('NWC wallet missing metadata["nwcUrl"]');
    }
    final connection = await ndk.nwc.connect(nwcUrl, doGetInfoMethod: false);
    try {
      final resp = await ndk.nwc.listTransactions(
        connection,
        unpaid: true,
        limit: limit,
      );
      if (resp.transactions.isEmpty) {
        stdout.writeln('  (no transactions returned)');
        return;
      }
      for (final tx in resp.transactions) {
        final dir = tx.isIncoming ? 'IN ' : 'OUT';
        final state = (tx.state ?? 'unknown').padRight(8);
        final amt = '${tx.amountSat} sat'.padRight(12);
        final fees = (tx.feesPaid ?? 0) > 0 ? ' fee=${tx.feesPaid}msat' : '';
        final settled = tx.settledAt != null
            ? ' settled=${_formatUnix(tx.settledAt!)}'
            : '';
        stdout.writeln('  $dir $state $amt$fees$settled');
      }
    } finally {
      await ndk.nwc.disconnect(connection);
    }
  }

  Future<void> _printStoredTransactions(
    Wallets walletsUsecase,
    String walletId,
    int? limit,
  ) async {
    final txs = await walletsUsecase.getTransactions(
      walletId: walletId,
      limit: limit,
    );
    if (txs.isEmpty) {
      stdout.writeln('  (no transactions stored)');
      return;
    }
    for (final tx in txs) {
      final dir = tx.changeAmount >= 0 ? 'IN ' : 'OUT';
      final state = tx.state.value.padRight(8);
      final amt = '${tx.changeAmount.abs()} ${tx.unit}'.padRight(12);
      final date = tx.transactionDate != null
          ? ' date=${_formatUnixMillis(tx.transactionDate!)}'
          : '';
      stdout.writeln('  $dir $state $amt$date');
    }
  }

  String _formatUnix(int seconds) {
    final dt = DateTime.fromMillisecondsSinceEpoch(seconds * 1000, isUtc: true);
    return dt.toIso8601String();
  }

  String _formatUnixMillis(int millis) {
    final dt = DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true);
    return dt.toIso8601String();
  }

  /// Resolves a cashu wallet by id (or default), throwing if it's not cashu.
  Future<Wallet> _resolveCashuWallet(
    String? walletId,
    WalletsRepo walletsRepo,
    Wallets walletsUsecase,
  ) async {
    final wallets = await walletsRepo.getWallets();
    if (wallets.isEmpty) {
      throw StateError('No wallets available');
    }
    String id;
    if (walletId != null) {
      id = walletId;
    } else {
      id = walletsUsecase.defaultWalletForReceiving?.id ?? wallets.first.id;
    }
    final wallet = wallets.firstWhere(
      (w) => w.id == id,
      orElse: () => throw ArgumentError('Wallet not found: $id'),
    );
    if (wallet.type != WalletType.CASHU) {
      throw ArgumentError('Wallet $id is ${wallet.type.value}, expected cashu');
    }
    return wallet;
  }

  Future<void> _ensureSeed(Ndk ndk, String? seedFlag) async {
    if (ndk.cashu.getCashuSeed().isSeedPhraseSet) return;
    final seed = seedFlag ?? Platform.environment['NDK_CASHU_SEED'];
    if (seed == null || seed.trim().isEmpty) {
      throw StateError('Cashu seed phrase not set. '
          'Pass --seed <mnemonic> or set NDK_CASHU_SEED env var.');
    }
    ndk.cashu.setCashuSeedPhrase(CashuUserSeedphrase(seedPhrase: seed.trim()));
  }

  _CashuOpArgs _parseCashuOpArgs(
    List<String> args, {
    required String usageLine,
    required bool requireValue,
    required String valueName,
    bool allowWait = false,
  }) {
    String? value;
    String? walletId;
    String? seed;
    var wait = false;
    var positionalSeen = 0;
    for (var i = 0; i < args.length; i++) {
      final a = args[i];
      if (a == '--seed' && i + 1 < args.length) {
        seed = args[++i];
        continue;
      }
      if (allowWait && a == '--wait') {
        wait = true;
        continue;
      }
      if (a.startsWith('-')) {
        return _CashuOpArgs(error: 'Unknown option: $a\nUsage: $usageLine');
      }
      if (positionalSeen == 0) {
        value = a;
        positionalSeen++;
      } else if (positionalSeen == 1) {
        walletId = a;
        positionalSeen++;
      } else {
        return _CashuOpArgs(error: 'Too many arguments.\nUsage: $usageLine');
      }
    }
    if (requireValue && value == null) {
      return _CashuOpArgs(error: 'Missing $valueName.\nUsage: $usageLine');
    }
    return _CashuOpArgs(
      value: value,
      walletId: walletId,
      seed: seed,
      wait: wait,
    );
  }

  void _printWallets(List<Wallet> wallets, Wallets walletsUsecase) {
    stdout.writeln('');
    if (wallets.isEmpty) {
      stdout.writeln('No wallets available.');
      stdout.writeln('');
      return;
    }

    final defaultReceivingId = walletsUsecase.defaultWalletForReceiving?.id;
    final defaultSendingId = walletsUsecase.defaultWalletForSending?.id;

    stdout.writeln('Wallets (${wallets.length}):');
    for (final wallet in wallets) {
      final flags = <String>[];
      if (wallet.id == defaultReceivingId) {
        flags.add('default-receive');
      }
      if (wallet.id == defaultSendingId) {
        flags.add('default-send');
      }

      final flagsSuffix = flags.isEmpty ? '' : ' [${flags.join(', ')}]';
      final units = wallet.supportedUnits.join(',');
      stdout.writeln(
        '- id=${wallet.id} name=${wallet.name} type=${wallet.type.value} '
        'units=$units '
        // 'canSend=${wallet.canSend} canReceive=${wallet.canReceive}'
        '$flagsSuffix',
      );
    }
    stdout.writeln('');
  }

  void _printHelp([IOSink? out]) {
    out ??= stdout;
    out.writeln('Wallets commands');
    out.writeln('Usage: ndk wallets <sub-command> [args]');
    out.writeln('');
    out.writeln('Sub-commands:');
    out.writeln('  list');
    out.writeln('  add nwc <NWC_URI> [name]');
    out.writeln('  add cashu <MINT_URL> [name]');
    out.writeln('  remove <walletId>');
    out.writeln('  receive <amountSats> [walletId]');
    out.writeln('  send <bolt11> [walletId]');
    out.writeln('  balance [walletId]');
    out.writeln('  budget [walletId]                              (NWC only)');
    out.writeln('  set-default <walletId> [receive|send|both]');
    out.writeln('  melt <bolt11> [walletId] [--seed <mnemonic>]  (cashu only)');
    out.writeln('  mint <amountSats> [walletId] [--seed <mnemonic>] [--wait]');
    out.writeln('  swap-receive <cashuToken> [--seed <mnemonic>]');
    out.writeln('  swap-spend <amountSats> [walletId] [--seed <mnemonic>]');
    out.writeln('  pay-stats [walletId] [--limit N]');
    out.writeln('');
    out.writeln('Examples:');
    out.writeln('  ndk wallets list');
    out.writeln('  ndk wallets add nwc "nostr+walletconnect://..."');
    out.writeln('  ndk wallets add cashu "https://mint.example.com"');
    out.writeln('  ndk wallets remove wallet_123');
    out.writeln('  ndk wallets receive 1000');
    out.writeln('  ndk wallets receive 1000 wallet_123');
    out.writeln('  ndk wallets send "lnbc1..."');
    out.writeln('  ndk wallets send "lnbc1..." wallet_123');
    out.writeln('  ndk wallets balance');
    out.writeln('  ndk wallets balance wallet_123');
    out.writeln('  ndk wallets budget');
    out.writeln('  ndk wallets budget wallet_123');
    out.writeln('  ndk wallets set-default wallet_123 send');
    out.writeln('  ndk wallets mint 100 --wait --seed "word1 word2 ..."');
    out.writeln('  ndk wallets melt "lnbc1..."');
    out.writeln('  ndk wallets swap-receive "cashuA..."');
    out.writeln('  ndk wallets pay-stats --limit 50');
    out.writeln(
        'Cashu operations accept --seed or the NDK_CASHU_SEED env var.');
  }

  bool _isHelp(String value) {
    return value == 'help' || value == '--help' || value == '-h';
  }

  String _buildWalletId() {
    final now = DateTime.now().microsecondsSinceEpoch;
    return 'wallet_$now';
  }
}

class _CashuOpArgs {
  final String? value;
  final String? walletId;
  final String? seed;
  final bool wait;
  final String? error;

  _CashuOpArgs({
    this.value,
    this.walletId,
    this.seed,
    this.wait = false,
    this.error,
  });
}
