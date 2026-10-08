import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk/entities.dart' show Bolt12Wallet;
import 'package:ndk_flutter/l10n/app_localizations.dart';
import 'package:ndk_flutter/ndk_flutter.dart';

class _UnavailableNdk implements Ndk {
  @override
  final Wallets wallets = _UnavailableWallets();

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('Wallet backend unavailable');
}

class _UnavailableWallets implements Wallets {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('Wallet backend unavailable');
}

class _CardHost extends StatefulWidget {
  const _CardHost({super.key, required this.ndkFlutter});

  final NdkFlutter ndkFlutter;

  @override
  State<_CardHost> createState() => _CardHostState();
}

class _CardHostState extends State<_CardHost> {
  bool showCard = true;

  void removeCard() => setState(() => showCard = false);

  @override
  Widget build(BuildContext context) => showCard
      ? NWalletCard(
          wallet: Bolt12Wallet(
            id: 'wallet',
            name: 'Phone wallet',
            supportedUnits: const {'sat'},
            offer: 'lno1test',
            source: 'lno1test',
          ),
          ndkFlutter: widget.ndkFlutter,
          isSelected: false,
          onTap: () {},
        )
      : const SizedBox.shrink();
}

void main() {
  testWidgets('delete dialog survives wallet card deactivation', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final hostKey = GlobalKey<_CardHostState>();
    late AppLocalizations l10n;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) {
              l10n = AppLocalizations.of(context)!;
              return _CardHost(
                key: hostKey,
                ndkFlutter: NdkFlutter(ndk: _UnavailableNdk()),
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    // Existing popup rows exceed Material's fixed menu width in English.
    // Clear that unrelated overflow before exercising dialog lifecycle.
    tester.takeException();
    await tester.tap(find.text(l10n.deleteWallet));
    await tester.pumpAndSettle();
    expect(find.text(l10n.deleteWalletConfirmation), findsOneWidget);

    hostKey.currentState!.removeCard();
    await tester.pumpAndSettle();

    expect(find.text(l10n.deleteWalletConfirmation), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text(l10n.cancel));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
