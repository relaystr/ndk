import 'package:flutter_test/flutter_test.dart';
import 'package:ndk/domain_layer/usecases/nwc/consts/nwc_method.dart';
import 'package:ndk_flutter/ndk_flutter.dart';

void main() {
  test('builds configurable web-wallet authorization URL', () {
    final uri = buildNwcWebWalletAuthUri(
      authorizationEndpoint: Uri.parse('https://coinos.io/apps/new'),
      appName: 'NDK Demo',
      pubkey: 'generated-public-key',
    );

    expect(uri.origin, 'https://coinos.io');
    expect(uri.path, '/apps/new');
    expect(uri.queryParameters['name'], 'NDK Demo');
    expect(uri.queryParameters['pubkey'], 'generated-public-key');
  });

  test('builds generic NWC wallet-auth deep link', () {
    const config = AlbyGoConnectConfig(
      appName: 'NDK Demo',
      appIconUrl: 'https://example.com/icon.png',
      callback: 'ndk://nwc',
      discoveryRelay: 'wss://relay.example.com',
      requestMethods: [NwcMethod.GET_INFO, NwcMethod.PAY_INVOICE],
    );

    final uri = buildNwcWalletAuthUri(
      appPubkey:
          'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
      config: config,
    );

    expect(uri.scheme, 'nostr+walletauth');
    expect(
      uri.host,
      'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
    );
    expect(uri.queryParameters['relay'], 'wss://relay.example.com');
    expect(uri.queryParameters['name'], 'NDK Demo');
    expect(uri.queryParameters['request_methods'], 'get_info pay_invoice');
    expect(uri.queryParameters['return_to'], 'ndk://nwc');
  });

  group('classifyWalletInput', () {
    test('recognizes a complete NWC connection URI', () {
      const pubkey =
          'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
      const secret =
          'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';

      expect(
        classifyWalletInput(
          'nostr+walletconnect://$pubkey?relay=wss%3A%2F%2Frelay.example&secret=$secret',
        ),
        WalletInputKind.nwc,
      );
    });

    test('rejects incomplete NWC connection URIs', () {
      expect(
        classifyWalletInput('nostr+walletconnect://wallet?secret=secret'),
        isNull,
      );
    });

    test('recognizes direct and BIP321 BOLT12 inputs', () {
      expect(classifyWalletInput('lno1offer'), WalletInputKind.bolt12);
      expect(
        classifyWalletInput('bitcoin:?lno=lno1offer'),
        WalletInputKind.bolt12,
      );
    });

    test('recognizes LNURL and BIP353 address shapes', () {
      expect(
        classifyWalletInput('alice@example.com'),
        WalletInputKind.lightningAddress,
      );
      expect(
        classifyWalletInput('₿alice@example.com'),
        WalletInputKind.lightningAddress,
      );
      expect(
        classifyWalletInput('lightning:alice@example.com'),
        WalletInputKind.lightningAddress,
      );
    });

    test('recognizes secure Cashu mint URLs', () {
      expect(
        classifyWalletInput('https://mint.example.com'),
        WalletInputKind.cashuMint,
      );
      expect(classifyWalletInput('http://mint.example.com'), isNull);
    });

    test('rejects payment invoices and arbitrary text', () {
      expect(classifyWalletInput('lnbc1invoice'), isNull);
      expect(classifyWalletInput('not a wallet'), isNull);
    });
  });
}
