import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk_flutter/l10n/app_localizations.dart';
import 'package:ndk_flutter/ndk_flutter.dart';

const _offer =
    'lno1pqqq5xj5wajkcan9gdshx6pq23jhxarfdenjqstyv3ex2umnzcss80xkrjkyrjk43u5dgu8f6a450fg2cnjtg7lhg76c3gtk5gdhshns';

// Preparing a direct offer must not add a wallet or access the network.
class _UnusedNdk implements Ndk {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('Unexpected NDK access: ${invocation.memberName}');
}

Future<AppLocalizations> _openScanner(
  WidgetTester tester,
  WalletInputScanner scanner,
) async {
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
            return TextButton(
              onPressed: () => showAddWalletTypeDialog(
                context,
                NdkFlutter(ndk: _UnusedNdk()),
                walletInputScanner: scanner,
              ),
              child: const Text('Open scanner'),
            );
          },
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open scanner'));
  await tester.pumpAndSettle();
  return l10n;
}

void main() {
  testWidgets('unsupported scan closes obsolete flow and shows error', (
    tester,
  ) async {
    final l10n = await _openScanner(tester, (_, _) async {
      return const WalletInputScanResult.value('unrecognized QR content');
    });
    expect(find.text(l10n.unsupportedWalletInput), findsOneWidget);
    expect(find.text(l10n.addWalletTitle), findsNothing);
  });

  testWidgets('scanner exception closes obsolete flow and shows error', (
    tester,
  ) async {
    final l10n = await _openScanner(tester, (_, _) async {
      throw Exception('Camera unavailable');
    });
    expect(find.text('Exception: Camera unavailable'), findsOneWidget);
    expect(find.text(l10n.addWalletTitle), findsNothing);
  });

  testWidgets('invalid offer closes obsolete flow with validation error', (
    tester,
  ) async {
    final l10n = await _openScanner(tester, (_, _) async {
      return const WalletInputScanResult.value('lno1invalid');
    });
    expect(find.textContaining('Invalid'), findsOneWidget);
    expect(find.text(l10n.addWalletTitle), findsNothing);
  });

  for (final value in [_offer, 'bitcoin?lno=$_offer']) {
    testWidgets('valid scanned ${value == _offer ? 'offer' : 'shorthand'} '
        'reaches confirmation without adding wallet', (tester) async {
      final l10n = await _openScanner(tester, (_, _) async {
        return WalletInputScanResult.value(value);
      });
      expect(find.text(l10n.confirm), findsOneWidget);
    });
  }
}
