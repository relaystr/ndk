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
  String get description => 'Wallet operations (list, add, remove, receive)';

  @override
  String get usage => 'wallets <list|add|remove|receive> [args]';

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
        await _handleAdd(subArgs, walletsRepo, walletsUsecase);
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
  ) async {
    if (args.length < 2) {
      stderr.writeln('Usage: ndk wallets add nwc <NWC_URI> [name]');
      throw ArgumentError('Missing required arguments for wallets add');
    }

    final walletType = args[0].toLowerCase();
    if (walletType != 'nwc') {
      throw ArgumentError(
        'Unsupported wallet type: "$walletType" (currently only "nwc")',
      );
    }

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
        'units=$units canSend=${wallet.canSend} canReceive=${wallet.canReceive}$flagsSuffix',
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
    out.writeln('  remove <walletId>');
    out.writeln('  receive <amountSats> [walletId]');
    out.writeln('');
    out.writeln('Examples:');
    out.writeln('  ndk wallets list');
    out.writeln('  ndk wallets add nwc "nostr+walletconnect://..."');
    out.writeln('  ndk wallets remove wallet_123');
    out.writeln('  ndk wallets receive 1000');
    out.writeln('  ndk wallets receive 1000 wallet_123');
  }

  bool _isHelp(String value) {
    return value == 'help' || value == '--help' || value == '-h';
  }

  String _buildWalletId() {
    final now = DateTime.now().microsecondsSinceEpoch;
    return 'wallet_$now';
  }
}
