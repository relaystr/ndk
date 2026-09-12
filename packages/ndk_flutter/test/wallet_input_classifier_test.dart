import 'package:flutter_test/flutter_test.dart';
import 'package:ndk/entities.dart';
import 'package:ndk/domain_layer/usecases/nwc/consts/nwc_method.dart';
import 'package:ndk_flutter/ndk_flutter.dart';

void main() {
  test('builds configurable web-wallet authorization URL', () {
    final uri = buildNwcWebWalletAuthUri(
      authorizationEndpoint: Uri.parse('https://coinos.io/apps/new'),
      appName: 'NDK Demo',
      pubkey: 'generated-public-key',
      state: '0123456789abcdef0123456789abcdef',
    );

    expect(uri.origin, 'https://coinos.io');
    expect(uri.path, '/apps/new');
    expect(uri.queryParameters['name'], 'NDK Demo');
    expect(uri.queryParameters['pubkey'], 'generated-public-key');
    expect(uri.queryParameters['state'], '0123456789abcdef0123456789abcdef');
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
      state: '0123456789abcdef0123456789abcdef',
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
    expect(uri.queryParameters['state'], '0123456789abcdef0123456789abcdef');
  });

  test('builds generic callback URI handled by Primal and Alby Go', () {
    const config = AlbyGoConnectConfig(
      appName: 'NDK Demo',
      appIconUrl: 'https://example.com/icon.png',
      callback: 'ndk://nwc',
    );

    final uri = buildNwcCallbackUri(config: config);

    expect(uri.scheme, 'nostrnwc');
    expect(uri.host, 'connect');
    expect(uri.queryParameters['appname'], 'NDK Demo');
    expect(uri.queryParameters['appicon'], 'https://example.com/icon.png');
    expect(uri.queryParameters['callback'], 'ndk://nwc');
  });

  test('builds Alby Go-specific wallet-auth deep link', () {
    const config = AlbyGoConnectConfig(
      appName: 'NDK Demo',
      appIconUrl: 'https://example.com/icon.png',
      callback: 'ndk://nwc',
    );

    final uri = buildNwcWalletAuthUri(
      appPubkey:
          'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
      config: config,
      state: '0123456789abcdef0123456789abcdef',
      scheme: config.walletAuthScheme,
    );

    expect(uri.scheme, 'nostr+walletauth+alby');
    expect(
      uri.queryParameters['request_methods'],
      'get_info get_balance get_budget make_invoice pay_invoice '
      'lookup_invoice list_transactions',
    );
    expect(config.nostrNwcScheme, 'nostrnwc+alby');
    expect(config.androidPackage, 'com.getalby.mobile');

    final qrUri = buildNwcWalletAuthUri(
      appPubkey:
          'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
      config: config,
      state: '0123456789abcdef0123456789abcdef',
      scheme: config.walletAuthScheme,
      includeReturnTo: false,
    );
    expect(qrUri.queryParameters.containsKey('return_to'), isFalse);
    expect(qrUri.queryParameters['relay'], config.discoveryRelay);
    expect(qrUri.queryParameters['state'], '0123456789abcdef0123456789abcdef');
  });

  test('generates 128-bit lowercase hex wallet-auth state', () {
    final first = generateNwcWalletAuthState();
    final second = generateNwcWalletAuthState();

    expect(first, matches(RegExp(r'^[0-9a-f]{32}$')));
    expect(second, isNot(first));
  });

  test('matches NWC-08 info by client pubkey and state', () {
    const appPubkey =
        'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
    final event = Nip01Event(
      pubKey:
          'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
      kind: 13194,
      tags: const [
        ['p', appPubkey],
        ['state', '0123456789abcdef0123456789abcdef'],
        ['relay', 'wss://wallet.example.com/CaseSensitive'],
      ],
      content: 'get_info get_balance',
    );

    expect(
      matchesNwcWalletAuthInfoEvent(
        event,
        appPubkey: appPubkey,
        state: '0123456789abcdef0123456789abcdef',
      ),
      isTrue,
    );
    expect(
      matchesNwcWalletAuthInfoEvent(
        event,
        appPubkey: appPubkey,
        state: 'wrong-state',
      ),
      isFalse,
    );
    expect(
      matchesNwcWalletAuthInfoEvent(
        event,
        appPubkey: appPubkey,
        state: '0123456789abcdef0123456789abcdef',
        walletServicePubkey:
            'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc',
      ),
      isFalse,
    );
    expect(
      walletAuthConnectionRelay(
        event,
        fallbackRelay: 'wss://discovery.example.com',
      ),
      'wss://wallet.example.com/CaseSensitive',
    );

    final eventWithoutState = Nip01Event(
      pubKey: event.pubKey,
      kind: event.kind,
      tags: const [
        ['p', appPubkey],
      ],
      content: event.content,
    );
    expect(
      matchesNwcWalletAuthInfoEvent(
        eventWithoutState,
        appPubkey: appPubkey,
        state: '0123456789abcdef0123456789abcdef',
      ),
      isTrue,
    );

    final untaggedLegacyEvent = Nip01Event(
      pubKey: event.pubKey,
      kind: event.kind,
      tags: const [],
      content: event.content,
    );
    expect(
      matchesNwcWalletAuthInfoEvent(
        untaggedLegacyEvent,
        appPubkey: appPubkey,
        state: '0123456789abcdef0123456789abcdef',
        walletServicePubkey: event.pubKey,
        requireAppPubkeyTag: false,
      ),
      isTrue,
    );
    expect(
      matchesNwcWalletAuthInfoEvent(
        untaggedLegacyEvent,
        appPubkey: appPubkey,
        state: '0123456789abcdef0123456789abcdef',
        walletServicePubkey:
            'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc',
        requireAppPubkeyTag: false,
      ),
      isFalse,
    );

    final eventWithoutRelay = Nip01Event(
      pubKey: event.pubKey,
      kind: event.kind,
      tags: const [
        ['p', appPubkey],
        ['state', '0123456789abcdef0123456789abcdef'],
      ],
      content: event.content,
    );
    expect(
      walletAuthConnectionRelay(
        eventWithoutRelay,
        fallbackRelay: 'wss://discovery.example.com',
      ),
      'wss://discovery.example.com',
    );
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
