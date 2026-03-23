import 'dart:io';

import 'package:ndk/domain_layer/entities/wallet/wallet.dart';
import 'package:ndk/domain_layer/entities/wallet/wallet_type.dart';
import 'package:ndk/domain_layer/repositories/wallets_repo.dart';
import 'package:ndk/ndk.dart';

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
  Future<int> run(List<String> args, Ndk ndk, WalletsRepo walletsRepo) async {
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
    out.writeln('  budget [walletId]');
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
  }

  bool _isHelp(String value) {
    return value == 'help' || value == '--help' || value == '-h';
  }

  String _buildWalletId() {
    final now = DateTime.now().microsecondsSinceEpoch;
    return 'wallet_$now';
  }
}
