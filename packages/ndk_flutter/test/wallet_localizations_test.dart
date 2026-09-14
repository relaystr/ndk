import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ndk/entities.dart' show Bolt12Wallet, Wallet;
import 'package:ndk/ndk.dart';
import 'package:ndk_flutter/l10n/app_localizations.dart';
import 'package:ndk_flutter/ndk_flutter.dart';

class _TestNdk implements Ndk {
  _TestNdk(Wallet wallet) : wallets = _TestWallets(wallet);

  @override
  final Wallets wallets;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('Wallet backend must not be used for localization');
}

class _TestWallets implements Wallets {
  _TestWallets(this.wallet);
  final Wallet wallet;

  @override
  Future<Wallet> reconnectWallet(String walletId) async => wallet;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('Unexpected wallet operation during localization test');
}

void main() {
  const walletKeys = {
    'sendToWallet',
    'sendToWalletDescription',
    'noCompatibleReceivingWallets',
    'noCompatibleReceivingWalletsDescription',
    'destinationWallet',
    'walletTransferSubmitted',
    'backup',
    'restore',
    'cashuBackupTitle',
    'cashuBackupWarning',
    'generatingBackup',
    'copyBackup',
    'backupCopiedToClipboard',
    'cashuRestoreTitle',
    'backupJson',
    'backupJsonHint',
    'pleaseEnterBackup',
    'restoringBackup',
    'restoreSuccess',
    'bolt12WalletSubtitle',
    'bolt12PrivateOfferSubtitle',
    'anyAmount',
    'blindedRoute',
    'fromAmountSats',
    'fromAmountMsats',
    'fromCurrencyAmount',
    'bolt12Expires',
    'bolt12WalletTypeSubtitle',
    'invalidBolt12QrCode',
    'bolt12OfferTitle',
    'bolt12OfferInstructions',
  };

  test('every locale defines wallet messages with matching placeholders', () {
    final template =
        jsonDecode(File('lib/l10n/app_en.arb').readAsStringSync())
            as Map<String, dynamic>;
    Set<String> placeholders(String value) => RegExp(
      r'\{(\w+)\}',
    ).allMatches(value).map((match) => match.group(1)!).toSet();

    for (final file in Directory('lib/l10n').listSync().whereType<File>()) {
      if (!file.path.endsWith('.arb')) continue;
      final messages =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      for (final key in walletKeys) {
        expect(messages[key], isA<String>(), reason: '${file.path}: $key');
        expect((messages[key] as String).trim(), isNotEmpty);
        expect(
          placeholders(messages[key] as String),
          placeholders(template[key] as String),
          reason: '${file.path}: $key placeholders',
        );
      }
    }
  }, skip: kIsWeb ? 'ARB source validation requires a filesystem.' : false);

  testWidgets(
    'Polish BOLT12 card and transfer labels do not fall back to English',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final wallet = Bolt12Wallet(
        id: 'wallet',
        name: 'phoenix',
        supportedUnits: const {'sat'},
        offer: 'lno1test',
        source: 'lno1test',
        hasBlindedPaths: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('pl'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Scaffold(
            body: Builder(
              builder: (context) {
                final l10n = AppLocalizations.of(context)!;
                return Column(
                  children: [
                    NWalletCard(
                      wallet: wallet,
                      ndkFlutter: NdkFlutter(ndk: _TestNdk(wallet)),
                      isSelected: false,
                      width: 800,
                      onTap: () {},
                    ),
                    Text(l10n.sendToWallet),
                    Text(l10n.sendToWalletDescription),
                    Text(l10n.destinationWallet),
                    Text(l10n.walletTransferSubmitted('LND')),
                  ],
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Prywatna oferta wielorazowa'), findsOneWidget);
      expect(find.textContaining('Dowolna kwota'), findsOneWidget);
      expect(find.textContaining('Ukryta trasa'), findsOneWidget);
      expect(find.text('Wyślij do portfela'), findsOneWidget);
      expect(find.text('Przelej do innego zgodnego portfela'), findsOneWidget);
      expect(find.text('Portfel docelowy'), findsOneWidget);
      expect(find.text('Płatność wysłana do portfela LND'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
