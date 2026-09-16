import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ndk/entities.dart' show Wallet;
import 'package:ndk/ndk.dart';
import 'package:ndk_flutter/l10n/app_localizations.dart';
import 'package:ndk_flutter/ndk_flutter.dart';

class _TestNdk implements Ndk {
  @override
  final Wallets wallets = _TestWallets();

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('Unexpected NDK operation');
}

class _TestWallets implements Wallets {
  @override
  Stream<List<Wallet>> get walletsStream => Stream.value(const []);

  @override
  Wallet? get defaultWalletForReceiving => null;

  @override
  Wallet? get defaultWalletForSending => null;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('Unexpected wallet operation');
}

Widget _buildList({
  required ThemeData theme,
  AddWalletCardBuilder? addWalletCardBuilder,
  VoidCallback? onAddWallet,
}) {
  return MaterialApp(
    theme: theme,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: SizedBox(
        height: 200,
        child: NWalletCardList(
          ndkFlutter: NdkFlutter(ndk: _TestNdk()),
          onWalletSelected: (_) {},
          onAddWallet: onAddWallet,
          addWalletCardBuilder: addWalletCardBuilder,
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('uses custom add-wallet card builder and passes callback', (
    tester,
  ) async {
    var tapped = false;

    await tester.pumpWidget(
      _buildList(
        theme: ThemeData(),
        onAddWallet: () => tapped = true,
        addWalletCardBuilder: (context, onTap) => TextButton(
          onPressed: onTap,
          child: const Text('Custom add wallet'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Custom add wallet'), findsOneWidget);
    expect(find.byKey(const ValueKey('add_wallet_card')), findsOneWidget);
    await tester.tap(find.text('Custom add wallet'));
    expect(tapped, isTrue);
  });

  testWidgets('default add-wallet card uses dark color scheme', (tester) async {
    final theme = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.deepPurple,
        brightness: Brightness.dark,
      ),
    );

    await tester.pumpWidget(_buildList(theme: theme));
    await tester.pumpAndSettle();

    final card = find.byKey(const ValueKey('add_wallet_card'));
    final containers = find.descendant(
      of: card,
      matching: find.byType(Container),
    );
    final root = tester.widget<Container>(containers.first);
    final decoration = root.decoration! as BoxDecoration;

    expect(decoration.color, theme.colorScheme.surfaceContainerLow);
    expect(decoration.border!.top.color, theme.colorScheme.outlineVariant);
    expect(decoration.color, isNot(Colors.grey[100]));
  });
}
