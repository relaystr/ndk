import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:ndk/entities.dart';
import 'package:ndk/domain_layer/usecases/nwc/consts/nwc_kind.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/bip340.dart';
import 'package:ndk/shared/nips/nip01/helpers.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';
import 'package:ndk_flutter/ndk_flutter.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/app_localizations.dart';

const String _defaultMintUrl = 'https://mint.minibits.cash/Bitcoin';
const String _dialogBackResult = '__back__';

/// Opens a host-provided NWC QR scanner and returns the scanned URI.
typedef NwcUriScanner = Future<String?> Function(BuildContext context);

/// Opens a host-provided scanner and returns a BOLT12, BIP321, or BIP353 input.
typedef Bolt12InputScanner = Future<String?> Function(BuildContext context);

/// Result returned by a host-provided wallet scanner screen.
enum WalletInputOrigin { scanner, walletChooser, cashuMintChooser }

class WalletInputScanResult {
  final String? value;
  final bool connectionStarted;
  final bool manuallyEntered;
  final WalletInputOrigin origin;
  final CashuMintSuggestion? cashuMintSuggestion;
  final LnBitsConnectionInput? lnBitsConnection;
  final String? providerId;

  const WalletInputScanResult.value(
    this.value, {
    this.manuallyEntered = false,
    this.origin = WalletInputOrigin.scanner,
    this.cashuMintSuggestion,
    this.providerId,
  }) : connectionStarted = false,
       lnBitsConnection = null;

  const WalletInputScanResult.lnBits(LnBitsConnectionInput connection)
    : lnBitsConnection = connection,
      value = null,
      connectionStarted = false,
      manuallyEntered = true,
      origin = WalletInputOrigin.walletChooser,
      cashuMintSuggestion = null,
      providerId = null;

  const WalletInputScanResult.connectionStarted()
    : value = null,
      connectionStarted = true,
      manuallyEntered = false,
      origin = WalletInputOrigin.walletChooser,
      cashuMintSuggestion = null,
      lnBitsConnection = null,
      providerId = null;
}

class LnBitsConnectionInput {
  final String url;
  final String adminKey;
  final String? walletName;
  final String? remoteWalletId;
  final bool readOnly;

  const LnBitsConnectionInput({
    required this.url,
    required this.adminKey,
    this.walletName,
    this.remoteWalletId,
    this.readOnly = false,
  });
}

/// Wallet connection choice displayed inside a host-provided scanner screen.
enum WalletScannerConnectionKind { installedWallet, albyGo, custom }

class WalletScannerConnectionOption {
  final String? id;
  final String label;
  final String? subtitle;
  final WidgetBuilder? iconBuilder;
  final Future<void> Function() connect;
  final WalletScannerConnectionKind kind;

  const WalletScannerConnectionOption({
    required this.label,
    required this.connect,
    required this.kind,
    this.id,
    this.subtitle,
    this.iconBuilder,
  });
}

/// Content and actions for a host-provided wallet scanner screen.
class WalletInputScannerConfiguration {
  final String supportedInputDescription;
  final String connectionSectionTitle;
  final List<WalletScannerConnectionOption> connectionOptions;
  final ValueListenable<WalletConnectionState> connectionState;
  final Future<bool> Function() retryPendingConnection;
  final VoidCallback cancelPendingConnection;
  final Future<List<CashuMintSuggestion>> Function() discoverCashuMints;
  final Future<CashuMintSuggestion> Function(CashuMintSuggestion suggestion)
  enrichCashuMint;
  final Future<LnBitsConnectionInput> Function(LnBitsConnectionInput input)?
  validateLnBitsConnection;
  final bool openWalletChooserInitially;
  final bool openCashuMintChooserInitially;

  const WalletInputScannerConfiguration({
    required this.supportedInputDescription,
    required this.connectionSectionTitle,
    required this.connectionOptions,
    required this.connectionState,
    required this.retryPendingConnection,
    required this.cancelPendingConnection,
    required this.discoverCashuMints,
    required this.enrichCashuMint,
    this.validateLnBitsConnection,
    this.openWalletChooserInitially = false,
    this.openCashuMintChooserInitially = false,
  });
}

/// Community-rated Cashu mint discovered from signed NIP-87 events.
class CashuMintSuggestion {
  final String url;
  final String name;
  final String? iconUrl;
  final double? averageRating;
  final int reviewsCount;
  final List<CashuMintReview> reviews;

  const CashuMintSuggestion({
    required this.url,
    required this.name,
    this.iconUrl,
    required this.averageRating,
    required this.reviewsCount,
    this.reviews = const [],
  });
}

class CashuMintReview {
  final int? rating;
  final String comment;

  const CashuMintReview({required this.rating, required this.comment});
}

/// Opens a host-provided scanner accepting every supported wallet input.
///
/// Scanner should explain [WalletInputScannerConfiguration.supportedInputDescription]
/// and render its wallet connection choices alongside camera and paste controls.
typedef WalletInputScanner =
    Future<WalletInputScanResult?> Function(
      BuildContext context,
      WalletInputScannerConfiguration configuration,
    );

/// Launches a wallet-assisted NWC connection flow.
typedef NwcConnectionLauncher =
    Future<void> Function(
      BuildContext context,
      NdkFlutter ndkFlutter,
      NwcWalletAuthCoordinator coordinator,
    );

/// Host-provided wallet app or web service that can authorize an NWC connection.
class NwcConnectionOption {
  final String? id;
  final String label;
  final String? subtitle;
  final WidgetBuilder? iconBuilder;
  final NwcConnectionLauncher connect;

  const NwcConnectionOption({
    required this.label,
    required this.connect,
    this.id,
    this.subtitle,
    this.iconBuilder,
  });
}

/// Default assisted web wallet connections, using the host app's identity and
/// callback from [config]. Pass an explicit list to override or disable them.
List<NwcConnectionOption> defaultNwcConnectionOptions({
  AlbyGoConnectConfig config = kDefaultAlbyGoConnectConfig,
}) => [
  NwcConnectionOption(
    id: 'alby-cloud',
    label: 'Alby Cloud',
    connect: (context, ndkFlutter, coordinator) =>
        coordinator.connectWebWalletAuth(
          context,
          authorizationEndpoint: Uri.parse('https://my.albyhub.com/apps/new'),
          appName: config.appName,
          discoveryRelay: config.discoveryRelay,
          callback: config.callback,
          walletName: 'Alby Cloud',
          providerId: 'alby',
          waitForDiscoveryNdkFlutter: ndkFlutter,
          additionalQueryParameters: {'return_to': config.callback},
        ),
  ),
  NwcConnectionOption(
    id: 'coinos',
    label: 'Coinos',
    connect: (context, ndkFlutter, coordinator) =>
        coordinator.connectWebWalletAuth(
          context,
          authorizationEndpoint: Uri.parse('https://coinos.io/apps/new'),
          appName: config.appName,
          discoveryRelay: 'wss://relay.coinos.io',
          callback: config.callback,
          walletName: 'Coinos',
          providerId: 'coinos',
          waitForDiscoveryNdkFlutter: ndkFlutter,
          allowUntaggedInfoEvent: true,
          walletServicePubkey:
              'ba80990666ef0b6f4ba5059347beb13242921e54669e680064ca755256a1e3a6',
        ),
  ),
];

/// Wallet input categories recognized by the unified add-wallet flow.
enum WalletInputKind { nwc, bolt12, lightningAddress, cashuMint, lnBits }

/// Classifies locally recognizable wallet input without performing network I/O.
WalletInputKind? classifyWalletInput(String input) {
  final value = _normalizeWalletInput(input);
  if (value.isEmpty) return null;

  final uri = Uri.tryParse(value);
  if (uri?.scheme.toLowerCase() == 'nostr+walletconnect') {
    try {
      NostrWalletConnectUri.parseConnectionUri(value);
      return WalletInputKind.nwc;
    } catch (_) {
      return null;
    }
  }

  final normalizedLower = value.toLowerCase();
  if (normalizedLower.startsWith('lno1') ||
      (uri?.scheme.toLowerCase() == 'bitcoin' &&
          uri!.queryParameters.entries.any(
            (entry) =>
                entry.key.toLowerCase() == 'lno' && entry.value.isNotEmpty,
          ))) {
    return WalletInputKind.bolt12;
  }

  var address = value;
  if (address.startsWith('₿')) address = address.substring(1);
  final addressParts = address.split('@');
  if (addressParts.length == 2 &&
      addressParts.every((part) => part.isNotEmpty) &&
      !address.contains(RegExp(r'\s'))) {
    return WalletInputKind.lightningAddress;
  }

  if (uri?.scheme.toLowerCase() == 'https' && uri!.host.isNotEmpty) {
    return WalletInputKind.cashuMint;
  }
  return null;
}

String _normalizeWalletInput(String input) {
  var value = input.trim();
  if (value.toLowerCase().startsWith('lightning:')) {
    value = value.substring('lightning:'.length).trim();
  }
  if (value.toLowerCase().startsWith('bitcoin?')) {
    value = 'bitcoin:${value.substring('bitcoin'.length)}';
  }
  return value;
}

/// Builds client-key web-wallet authorization URL.
Uri buildNwcWebWalletAuthUri({
  required Uri authorizationEndpoint,
  required String appName,
  required String pubkey,
  required String state,
  Map<String, String> additionalQueryParameters = const {},
}) {
  return authorizationEndpoint.replace(
    queryParameters: {
      ...authorizationEndpoint.queryParameters,
      ...additionalQueryParameters,
      'name': appName,
      'pubkey': pubkey,
      'state': state,
    },
  );
}

/// Builds standard NWC wallet-auth URI handled by compatible wallet apps.
Uri buildNwcWalletAuthUri({
  required String appPubkey,
  required AlbyGoConnectConfig config,
  required String state,
  String scheme = 'nostr+walletauth',
  bool includeReturnTo = true,
}) {
  return Uri(
    scheme: scheme,
    host: appPubkey,
    queryParameters: {
      'relay': config.discoveryRelay,
      'state': state,
      'name': config.appName,
      'request_methods': config.requestMethods
          .map((method) => method.name)
          .join(' '),
      'icon': config.appIconUrl,
      if (includeReturnTo) 'return_to': config.callback,
    },
  );
}

/// Builds an NWC-07 callback URI handled by Primal, Alby Go, and other wallets
/// registered for `nostrnwc://connect`.
Uri buildNwcCallbackUri({
  required AlbyGoConnectConfig config,
  String scheme = 'nostrnwc',
}) {
  return Uri(
    scheme: scheme,
    host: config.nostrNwcHost,
    queryParameters: {
      'appname': config.appName,
      'appicon': config.appIconUrl,
      'callback': config.callback,
    },
  );
}

/// Generates NWC-08 correlation state with 128 bits of secure randomness.
String generateNwcWalletAuthState() => Helpers.getSecureRandomHex(16);

/// Validates discovery against client key and any returned correlation state.
/// Missing state remains accepted for wallets implementing earlier drafts.
bool matchesNwcWalletAuthInfoEvent(
  Nip01Event event, {
  required String appPubkey,
  required String state,
  String? walletServicePubkey,
  bool requireAppPubkeyTag = true,
}) {
  final returnedState = event.getFirstTag('state');
  return event.kind == NwcKind.INFO.value &&
      (!requireAppPubkeyTag || event.pTags.contains(appPubkey.toLowerCase())) &&
      (returnedState == null ||
          returnedState.isEmpty ||
          returnedState == state) &&
      (walletServicePubkey == null || event.pubKey == walletServicePubkey);
}

/// Uses wallet-service relay recommendation when NWC-08 info provides one.
String walletAuthConnectionRelay(
  Nip01Event event, {
  required String fallbackRelay,
}) {
  for (final tag in event.tags) {
    if (tag.length > 1 && tag[0] == 'relay' && tag[1].trim().isNotEmpty) {
      return tag[1];
    }
  }
  return fallbackRelay;
}

enum AlbyGoConnectMethod { walletAuth, nostrNwcCallback }

enum WalletConnectionPhase {
  idle,
  awaitingReturn,
  connecting,
  connected,
  failed,
}

@immutable
class WalletConnectionState {
  final WalletConnectionPhase phase;
  final String? walletName;
  final String? error;

  const WalletConnectionState._(this.phase, {this.walletName, this.error});

  const WalletConnectionState.idle() : this._(WalletConnectionPhase.idle);

  const WalletConnectionState.awaitingReturn(String walletName)
    : this._(WalletConnectionPhase.awaitingReturn, walletName: walletName);

  const WalletConnectionState.connecting(String walletName)
    : this._(WalletConnectionPhase.connecting, walletName: walletName);

  const WalletConnectionState.connected(String walletName)
    : this._(WalletConnectionPhase.connected, walletName: walletName);

  const WalletConnectionState.failed(String walletName, String error)
    : this._(
        WalletConnectionPhase.failed,
        walletName: walletName,
        error: error,
      );
}

const List<NwcMethod> _defaultAlbyGoRequestMethods = [
  NwcMethod.GET_INFO,
  NwcMethod.GET_BALANCE,
  NwcMethod.GET_BUDGET,
  NwcMethod.MAKE_INVOICE,
  NwcMethod.PAY_INVOICE,
  NwcMethod.LOOKUP_INVOICE,
  NwcMethod.LIST_TRANSACTIONS,
];

/// Configuration for launching the Alby Go NWC connection intent.
///
/// Provide raw (unencoded) values. They will be encoded for the intent URL.
class AlbyGoConnectConfig {
  final String appName;
  final String appIconUrl;
  final String callback;
  final String discoveryRelay;
  final List<NwcMethod> requestMethods;
  final String walletName;
  final AlbyGoConnectMethod connectMethod;
  final String walletAuthScheme;
  final String nostrNwcScheme;
  final String androidPackage;

  /// Host used when [connectMethod] is [AlbyGoConnectMethod.nostrNwcCallback].
  final String nostrNwcHost;

  const AlbyGoConnectConfig({
    required this.appName,
    required this.appIconUrl,
    required this.callback,
    this.discoveryRelay = 'wss://relay.getalby.com',
    this.requestMethods = _defaultAlbyGoRequestMethods,
    this.walletName = 'Alby Go',
    this.connectMethod = AlbyGoConnectMethod.walletAuth,
    this.walletAuthScheme = 'nostr+walletauth+alby',
    this.nostrNwcScheme = 'nostrnwc+alby',
    this.androidPackage = 'com.getalby.mobile',
    this.nostrNwcHost = 'connect',
  });
}

/// Default Alby Go parameters aligned with the sample app's NWC auth flow.
const AlbyGoConnectConfig kDefaultAlbyGoConnectConfig = AlbyGoConnectConfig(
  appName: 'NDK Demo',
  appIconUrl: 'https://logowik.com/content/uploads/images/flutter5786.jpg',
  callback: 'ndk://nwc',
);

class NwcWalletAuthCoordinator {
  _PendingNwcWalletAuthSession? _pendingSession;
  _PendingNwcCallbackSession? _pendingCallbackSession;
  String? _lastConnectedWalletId;
  bool _isCompletingPendingSession = false;
  Future<void> Function()? _retryLaunch;
  Future<void> Function()? _closeWalletAuthSubscription;
  final ValueNotifier<WalletConnectionState> connectionState = ValueNotifier(
    const WalletConnectionState.idle(),
  );

  bool get hasPendingSession => _pendingSession != null;

  void cancelPendingConnection() {
    final closeSubscription = _closeWalletAuthSubscription;
    _closeWalletAuthSubscription = null;
    _pendingSession = null;
    _pendingCallbackSession = null;
    _retryLaunch = null;
    connectionState.value = const WalletConnectionState.idle();
    if (closeSubscription != null) {
      unawaited(closeSubscription().catchError((_) {}));
    }
  }

  /// Clears stale terminal UI state before starting a new add-wallet flow.
  /// Active external-wallet sessions remain untouched.
  void resetTerminalConnectionState() {
    final phase = connectionState.value.phase;
    if (phase == WalletConnectionPhase.connected ||
        phase == WalletConnectionPhase.failed) {
      cancelPendingConnection();
    }
  }

  Future<bool> retryPendingConnection(
    BuildContext context,
    NdkFlutter ndkFlutter,
  ) async {
    if (_pendingSession != null) {
      return completePendingWalletAuth(context, ndkFlutter);
    }
    final retryLaunch = _retryLaunch;
    if (retryLaunch == null) return false;
    await retryLaunch();
    return true;
  }

  /// Finishes whichever external-wallet flow was active when app resumes.
  ///
  /// Callback-based wallets deliver deep link shortly after lifecycle resume.
  /// Give that intent brief grace period before treating plain return as failure.
  Future<bool> handleAppResume(
    BuildContext context,
    NdkFlutter ndkFlutter,
  ) async {
    final pendingCallback = _pendingCallbackSession;
    if (pendingCallback == null) {
      return completePendingWalletAuth(context, ndkFlutter);
    }

    await Future<void>.delayed(const Duration(milliseconds: 750));
    if (!identical(_pendingCallbackSession, pendingCallback)) return true;

    _markFailed(
      pendingCallback.walletName,
      'Wallet returned without providing a connection. Try again or choose another wallet.',
    );
    return true;
  }

  String? takeLastConnectedWalletId() {
    final walletId = _lastConnectedWalletId;
    _lastConnectedWalletId = null;
    return walletId;
  }

  void _markAwaiting(String walletName) {
    connectionState.value = WalletConnectionState.awaitingReturn(walletName);
  }

  void _markFailed(String walletName, Object error) {
    connectionState.value = WalletConnectionState.failed(
      walletName,
      error.toString(),
    );
  }

  /// Launches an installed-wallet or web authorization URI and waits for its
  /// callback to be passed to [processProtocolUrl].
  Future<void> connectWithUri(
    BuildContext context, {
    required Uri launchUri,
    required String callback,
    required String walletName,
    String? providerId,
  }) async {
    _retryLaunch = () => connectWithUri(
      context,
      launchUri: launchUri,
      callback: callback,
      walletName: walletName,
      providerId: providerId,
    );
    _pendingSession = null;
    _pendingCallbackSession = _PendingNwcCallbackSession(
      returnTo: callback,
      walletName: walletName,
      providerId: providerId,
    );
    _markAwaiting(walletName);

    try {
      if (!kIsWeb && Platform.isAndroid) {
        final intent = AndroidIntent(
          action: 'action_view',
          data: launchUri.toString(),
        );
        await intent.launch();
      } else {
        final launched = await launchUrl(
          launchUri,
          mode: LaunchMode.externalApplication,
        );
        if (!launched) throw StateError('Could not launch wallet app');
      }
    } catch (error) {
      _pendingCallbackSession = null;
      _markFailed(walletName, error);
      if (!context.mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.error(error.toString())),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Opens an NWC-07 URI using normal platform intent resolution.
  Future<void> connectInstalledWallet(
    BuildContext context, {
    required AlbyGoConnectConfig config,
  }) {
    return connectWithUri(
      context,
      launchUri: buildNwcCallbackUri(config: config),
      callback: config.callback,
      walletName: 'NWC',
    );
  }

  /// Opens standard `nostr+walletauth://` URI in a compatible wallet.
  Future<void> connectWalletAuth(
    BuildContext context, {
    required AlbyGoConnectConfig config,
    required String walletName,
    String? providerId,
    String uriScheme = 'nostr+walletauth',
    String? androidPackage,
    NdkFlutter? qrFallbackNdkFlutter,
    bool showAlbyGoQrInstructions = false,
  }) async {
    final canLaunchWalletApp =
        !kIsWeb && (Platform.isAndroid || Platform.isIOS);
    if (!canLaunchWalletApp && qrFallbackNdkFlutter == null) return;

    final appKey = Bip340.generatePrivateKey();
    _retryLaunch = () => connectWalletAuth(
      context,
      config: config,
      walletName: walletName,
      providerId: providerId,
      uriScheme: uriScheme,
      androidPackage: androidPackage,
      qrFallbackNdkFlutter: qrFallbackNdkFlutter,
      showAlbyGoQrInstructions: showAlbyGoQrInstructions,
    );
    final state = generateNwcWalletAuthState();
    final launchUri = buildNwcWalletAuthUri(
      appPubkey: appKey.publicKey,
      config: config,
      state: state,
      scheme: uriScheme,
    );
    final qrUri = buildNwcWalletAuthUri(
      appPubkey: appKey.publicKey,
      config: config,
      state: state,
      scheme: uriScheme,
      includeReturnTo: false,
    );

    _pendingSession = _PendingNwcWalletAuthSession(
      appKey: appKey,
      discoveryRelay: config.discoveryRelay,
      returnTo: config.callback,
      walletName: walletName,
      providerId: providerId,
      state: state,
      allowUntaggedInfoEvent: false,
    );
    _pendingCallbackSession = null;
    _markAwaiting(walletName);

    if (!canLaunchWalletApp) {
      if (!context.mounted) return;
      await _showWalletAuthDiscoveryDialog(
        context,
        authorizationUri: qrUri,
        walletName: walletName,
        ndkFlutter: qrFallbackNdkFlutter!,
        showAlbyGoQrInstructions: showAlbyGoQrInstructions,
      );
      return;
    }

    try {
      if (Platform.isAndroid) {
        final intent = AndroidIntent(
          action: 'action_view',
          data: launchUri.toString(),
          package: androidPackage,
        );
        if (androidPackage != null) {
          if (await intent.canResolveActivity() != true) {
            throw StateError('Wallet app is not installed');
          }
          await intent.launch();
        } else {
          final l10n = AppLocalizations.of(context)!;
          await intent.launchChooser(l10n.chooseWalletApp);
        }
      } else {
        final launched = await launchUrl(
          launchUri,
          mode: LaunchMode.externalApplication,
        );
        if (!launched) throw StateError('Could not launch wallet app');
      }
      if (qrFallbackNdkFlutter != null &&
          hasPendingSession &&
          context.mounted) {
        await _showWalletAuthDiscoveryDialog(
          context,
          walletName: walletName,
          ndkFlutter: qrFallbackNdkFlutter,
          showAlbyGoQrInstructions: showAlbyGoQrInstructions,
        );
      }
    } catch (error) {
      if (qrFallbackNdkFlutter != null && context.mounted) {
        await _showWalletAuthDiscoveryDialog(
          context,
          authorizationUri: qrUri,
          walletName: walletName,
          ndkFlutter: qrFallbackNdkFlutter,
          showAlbyGoQrInstructions: showAlbyGoQrInstructions,
        );
        return;
      }
      _pendingSession = null;
      _markFailed(walletName, error);
      if (!context.mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.error(error.toString())),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<bool?> _showWalletAuthDiscoveryDialog(
    BuildContext context, {
    Uri? authorizationUri,
    required String walletName,
    required NdkFlutter ndkFlutter,
    bool showAlbyGoQrInstructions = false,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _NwcWalletAuthDiscoveryDialog(
        authorizationUri: authorizationUri,
        walletName: walletName,
        coordinator: this,
        ndkFlutter: ndkFlutter,
        showAlbyGoQrInstructions: showAlbyGoQrInstructions,
      ),
    );
  }

  /// Starts client-key NWC authorization through a web wallet.
  ///
  /// [appName] is sent as `name`; generated public key is sent as `pubkey`.
  /// Call [completePendingWalletAuth] when host app resumes to discover wallet
  /// info event addressed to generated key on [discoveryRelay].
  Future<void> connectWebWalletAuth(
    BuildContext context, {
    required Uri authorizationEndpoint,
    required String appName,
    required String discoveryRelay,
    required String callback,
    required String walletName,
    String? providerId,
    String? walletServicePubkey,
    NdkFlutter? waitForDiscoveryNdkFlutter,
    bool allowUntaggedInfoEvent = false,
    Map<String, String> additionalQueryParameters = const {},
  }) async {
    if (allowUntaggedInfoEvent && walletServicePubkey == null) {
      throw ArgumentError(
        'walletServicePubkey is required for untagged info-event discovery',
      );
    }
    final appKey = Bip340.generatePrivateKey();
    final state = generateNwcWalletAuthState();
    _retryLaunch = () => connectWebWalletAuth(
      context,
      authorizationEndpoint: authorizationEndpoint,
      appName: appName,
      discoveryRelay: discoveryRelay,
      callback: callback,
      walletName: walletName,
      providerId: providerId,
      walletServicePubkey: walletServicePubkey,
      waitForDiscoveryNdkFlutter: waitForDiscoveryNdkFlutter,
      allowUntaggedInfoEvent: allowUntaggedInfoEvent,
      additionalQueryParameters: additionalQueryParameters,
    );
    final launchUri = buildNwcWebWalletAuthUri(
      authorizationEndpoint: authorizationEndpoint,
      appName: appName,
      pubkey: appKey.publicKey,
      state: state,
      additionalQueryParameters: additionalQueryParameters,
    );

    _pendingSession = _PendingNwcWalletAuthSession(
      appKey: appKey,
      discoveryRelay: discoveryRelay,
      returnTo: callback,
      walletName: walletName,
      walletServicePubkey: walletServicePubkey,
      providerId: providerId,
      state: state,
      allowUntaggedInfoEvent: allowUntaggedInfoEvent,
    );
    _pendingCallbackSession = null;
    _markAwaiting(walletName);

    try {
      final launched = await launchUrl(
        launchUri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) throw StateError('Could not launch wallet provider');
      if (waitForDiscoveryNdkFlutter != null &&
          hasPendingSession &&
          context.mounted) {
        await _showWalletAuthDiscoveryDialog(
          context,
          walletName: walletName,
          ndkFlutter: waitForDiscoveryNdkFlutter,
        );
      }
    } catch (error) {
      _pendingSession = null;
      _markFailed(walletName, error);
      if (!context.mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.error(error.toString())),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> connectAlbyGo(
    BuildContext context,
    NdkFlutter ndkFlutter, {
    AlbyGoConnectConfig config = kDefaultAlbyGoConnectConfig,
  }) async {
    if (config.connectMethod == AlbyGoConnectMethod.walletAuth) {
      return connectWalletAuth(
        context,
        config: config,
        walletName: config.walletName,
        providerId: 'alby',
        uriScheme: config.walletAuthScheme,
        androidPackage: config.androidPackage,
        qrFallbackNdkFlutter: ndkFlutter,
        showAlbyGoQrInstructions: true,
      );
    }

    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) return;

    _retryLaunch = () => connectAlbyGo(context, ndkFlutter, config: config);

    final launchUri = Uri(
      scheme: config.nostrNwcScheme,
      host: config.nostrNwcHost,
      queryParameters: {
        'appname': config.appName,
        'appicon': config.appIconUrl,
        'callback': config.callback,
      },
    );
    _pendingSession = null;
    _pendingCallbackSession = _PendingNwcCallbackSession(
      returnTo: config.callback,
      walletName: config.walletName,
      providerId: 'alby',
    );
    _markAwaiting(config.walletName);

    try {
      if (Platform.isAndroid) {
        final intent = AndroidIntent(
          action: 'action_view',
          data: launchUri.toString(),
          package: config.androidPackage,
        );
        await intent.launch();
      } else {
        final launched = await launchUrl(
          launchUri,
          mode: LaunchMode.externalApplication,
        );
        if (!launched) {
          throw StateError('Could not launch wallet app');
        }
      }
    } catch (e) {
      _pendingCallbackSession = null;
      _markFailed(config.walletName, e);
      if (!context.mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.error(e.toString())),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<bool> processProtocolUrl(
    BuildContext context,
    NdkFlutter ndkFlutter,
    String url,
  ) async {
    final l10n = context.mounted ? AppLocalizations.of(context)! : null;
    final scaffoldMessenger = context.mounted
        ? ScaffoldMessenger.of(context)
        : null;

    final returnedUri = Uri.tryParse(url);
    final pendingWalletAuth = _pendingSession;
    final returnedRelay =
        returnedUri?.queryParameters['relay_url'] ??
        returnedUri?.queryParameters['relay'];
    final returnedWalletPubkey =
        returnedUri?.queryParameters['wallet_pubkey'] ??
        returnedUri?.queryParameters['pubkey'];
    final returnedState = returnedUri?.queryParameters['state'];
    if (pendingWalletAuth != null &&
        _matchesReturnTo(url, pendingWalletAuth.returnTo) &&
        (returnedState == null ||
            returnedState.isEmpty ||
            returnedState == pendingWalletAuth.state) &&
        returnedRelay != null &&
        returnedRelay.isNotEmpty &&
        returnedWalletPubkey != null &&
        returnedWalletPubkey.isNotEmpty) {
      try {
        connectionState.value = WalletConnectionState.connecting(
          pendingWalletAuth.walletName,
        );
        final secret = pendingWalletAuth.appKey.privateKey;
        if (secret == null) {
          throw StateError('Generated wallet auth key is missing private key');
        }
        final nwcUri =
            'nostr+walletconnect://$returnedWalletPubkey?relay=${Uri.encodeComponent(returnedRelay)}&secret=$secret';
        await _addNwcWallet(
          ndkFlutter,
          nwcUri: nwcUri,
          walletName: pendingWalletAuth.walletName,
          providerId: pendingWalletAuth.providerId,
        );
        _pendingSession = null;
        final closeSubscription = _closeWalletAuthSubscription;
        _closeWalletAuthSubscription = null;
        await closeSubscription?.call();
        connectionState.value = WalletConnectionState.connected(
          pendingWalletAuth.walletName,
        );
        _retryLaunch = null;
        if (context.mounted) {
          scaffoldMessenger!.showSnackBar(
            SnackBar(
              content: Text(l10n!.nwcWalletAdded),
              backgroundColor: Colors.green,
            ),
          );
        }
        return true;
      } catch (error) {
        _markFailed(pendingWalletAuth.walletName, error);
        return true;
      }
    }

    final callbackNwcUri = _extractNwcUriFromCallback(url);
    if (callbackNwcUri != null) {
      final pendingCallbackSession = _pendingCallbackSession;
      if (pendingCallbackSession != null &&
          !url.startsWith(Nwc.kNWCProtocolPrefix) &&
          !_matchesReturnTo(url, pendingCallbackSession.returnTo)) {
        return false;
      }

      try {
        connectionState.value = WalletConnectionState.connecting(
          pendingCallbackSession?.walletName ??
              _pendingSession?.walletName ??
              kDefaultAlbyGoConnectConfig.walletName,
        );
        await _addNwcWallet(
          ndkFlutter,
          nwcUri: callbackNwcUri,
          walletName:
              pendingCallbackSession?.walletName ??
              _pendingSession?.walletName ??
              kDefaultAlbyGoConnectConfig.walletName,
          providerId:
              pendingCallbackSession?.providerId ?? _pendingSession?.providerId,
        );
        _pendingSession = null;
        final closeSubscription = _closeWalletAuthSubscription;
        _closeWalletAuthSubscription = null;
        await closeSubscription?.call();
        connectionState.value = WalletConnectionState.connected(
          pendingCallbackSession?.walletName ??
              _pendingSession?.walletName ??
              kDefaultAlbyGoConnectConfig.walletName,
        );
        _retryLaunch = null;
        if (context.mounted) {
          scaffoldMessenger!.showSnackBar(
            SnackBar(
              content: Text(l10n!.nwcWalletAdded),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        _markFailed(
          pendingCallbackSession?.walletName ??
              _pendingSession?.walletName ??
              kDefaultAlbyGoConnectConfig.walletName,
          e,
        );
        if (context.mounted) {
          scaffoldMessenger!.showSnackBar(
            SnackBar(
              content: Text(l10n!.error(e.toString())),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        _pendingSession = null;
        _pendingCallbackSession = null;
      }
      return true;
    }

    final pendingSession = _pendingSession;
    if (pendingSession == null ||
        !_matchesReturnTo(url, pendingSession.returnTo)) {
      return false;
    }

    return completePendingWalletAuth(context, ndkFlutter);
  }

  /// Resolves pending client-key wallet authorization from its NWC info event.
  ///
  /// Useful for web providers that return control by app lifecycle rather than
  /// a callback URL.
  Future<bool> completePendingWalletAuth(
    BuildContext context,
    NdkFlutter ndkFlutter, {
    Duration? timeout = const Duration(seconds: 15),
    bool showMessages = true,
  }) async {
    final pendingSession = _pendingSession;
    if (pendingSession == null || _isCompletingPendingSession) return false;

    _isCompletingPendingSession = true;
    connectionState.value = WalletConnectionState.connecting(
      pendingSession.walletName,
    );
    final l10n = context.mounted ? AppLocalizations.of(context)! : null;
    final scaffoldMessenger = context.mounted
        ? ScaffoldMessenger.of(context)
        : null;

    _pendingCallbackSession = null;

    if (showMessages && context.mounted) {
      scaffoldMessenger!.showSnackBar(
        SnackBar(content: Text(l10n!.fetchingWalletConnectionInfo)),
      );
    }

    Future<void> Function()? closeSubscription;
    try {
      final requests = ndkFlutter.ndk.requests;
      final subscription = requests.subscription(
        filter: Filter(
          kinds: [NwcKind.INFO.value],
          authors: pendingSession.walletServicePubkey == null
              ? null
              : [pendingSession.walletServicePubkey!],
          pTags: pendingSession.allowUntaggedInfoEvent
              ? null
              : [pendingSession.appKey.publicKey],
        ),
        explicitRelays: {pendingSession.discoveryRelay},
      );
      var subscriptionClosed = false;
      Future<void> closeCurrentSubscription() async {
        if (subscriptionClosed) return;
        subscriptionClosed = true;
        await requests.closeSubscription(
          subscription.requestId,
          debugLabel: 'NWC wallet authorization',
        );
      }

      closeSubscription = closeCurrentSubscription;
      _closeWalletAuthSubscription = closeCurrentSubscription;
      final matchingEvents = subscription.stream.where(
        (event) => matchesNwcWalletAuthInfoEvent(
          event,
          appPubkey: pendingSession.appKey.publicKey,
          state: pendingSession.state,
          walletServicePubkey: pendingSession.walletServicePubkey,
          requireAppPubkeyTag: !pendingSession.allowUntaggedInfoEvent,
        ),
      );

      var walletAddedDuringDiscovery = false;
      Future<Nip01Event> findUsableInfoEvent() async {
        if (!pendingSession.allowUntaggedInfoEvent) {
          return matchingEvents.first;
        }

        final usableEvent = Completer<Nip01Event>();
        Nip01Event? latestInfoEvent;
        var validating = false;
        var retryRequested = false;

        Future<void> validateLatestInfoEvent() async {
          if (validating) {
            retryRequested = true;
            return;
          }
          validating = true;
          try {
            do {
              retryRequested = false;
              final event = latestInfoEvent;
              if (event == null || usableEvent.isCompleted) return;
              if (!identical(_pendingSession, pendingSession)) {
                if (!usableEvent.isCompleted) {
                  usableEvent.completeError(
                    StateError('Wallet connection cancelled'),
                  );
                }
                return;
              }

              final secret = pendingSession.appKey.privateKey;
              if (secret == null) {
                usableEvent.completeError(
                  StateError(
                    'Generated wallet auth keypair is missing a private key',
                  ),
                );
                return;
              }
              final relay = walletAuthConnectionRelay(
                event,
                fallbackRelay: pendingSession.discoveryRelay,
              );
              final nwcUri =
                  'nostr+walletconnect://${pendingSession.walletServicePubkey}?relay=${Uri.encodeComponent(relay)}&secret=$secret';
              try {
                await _addNwcWallet(
                  ndkFlutter,
                  nwcUri: nwcUri,
                  walletName: pendingSession.walletName,
                  providerId: pendingSession.providerId,
                  requireAuthenticatedResponse: true,
                );
                walletAddedDuringDiscovery = true;
                usableEvent.complete(event);
                return;
              } catch (error) {
                // A generic info event proves service availability, not client
                // authorization. Retry every five seconds while this discovery
                // session remains open.
                Logger.log.d(
                  () =>
                      'NWC wallet authorization not ready for ${pendingSession.walletName}: $error',
                );
              }
            } while (retryRequested && !usableEvent.isCompleted);
          } finally {
            validating = false;
          }
        }

        final matchingEventsSubscription = matchingEvents.listen(
          (event) {
            latestInfoEvent = event;
            unawaited(validateLatestInfoEvent());
          },
          onError: (Object error, StackTrace stackTrace) {
            if (!usableEvent.isCompleted) {
              usableEvent.completeError(error, stackTrace);
            }
          },
          onDone: () {
            if (!usableEvent.isCompleted) {
              usableEvent.completeError(
                StateError('Wallet info subscription closed'),
              );
            }
          },
        );

        final validationTimer = Timer.periodic(const Duration(seconds: 5), (_) {
          retryRequested = true;
          unawaited(validateLatestInfoEvent());
        });

        try {
          return await usableEvent.future;
        } finally {
          validationTimer.cancel();
          await matchingEventsSubscription.cancel();
        }
      }

      final usableInfoEvent = findUsableInfoEvent();
      final foundWalletAuthEvent = timeout == null
          ? await usableInfoEvent
          : await usableInfoEvent.timeout(timeout);
      if (!identical(_pendingSession, pendingSession)) return false;
      final appPrivateKey = pendingSession.appKey.privateKey;

      if (appPrivateKey == null) {
        throw StateError(
          'Generated wallet auth keypair is missing a private key',
        );
      }

      final walletServicePubkey =
          pendingSession.walletServicePubkey ?? foundWalletAuthEvent.pubKey;
      final connectionRelay = walletAuthConnectionRelay(
        foundWalletAuthEvent,
        fallbackRelay: pendingSession.discoveryRelay,
      );
      final constructedNwcUri =
          'nostr+walletconnect://$walletServicePubkey?relay=${Uri.encodeComponent(connectionRelay)}&secret=$appPrivateKey';

      if (!walletAddedDuringDiscovery) {
        await _addNwcWallet(
          ndkFlutter,
          nwcUri: constructedNwcUri,
          walletName: pendingSession.walletName,
          providerId: pendingSession.providerId,
          requireAuthenticatedResponse: pendingSession.allowUntaggedInfoEvent,
        );
      }

      _pendingSession = null;
      connectionState.value = WalletConnectionState.connected(
        pendingSession.walletName,
      );
      _retryLaunch = null;

      if (!showMessages || !context.mounted) return true;
      scaffoldMessenger!.showSnackBar(
        SnackBar(
          content: Text(l10n!.nwcWalletAdded),
          backgroundColor: Colors.green,
        ),
      );
      return true;
    } on TimeoutException {
      if (!identical(_pendingSession, pendingSession)) return false;
      _markFailed(
        pendingSession.walletName,
        'Timed out while waiting for wallet connection info from ${pendingSession.discoveryRelay}',
      );
      if (!showMessages || !context.mounted) return true;
      scaffoldMessenger!.showSnackBar(
        SnackBar(
          content: Text(
            l10n!.error(
              'Timed out while waiting for wallet connection info from ${pendingSession.discoveryRelay}',
            ),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return true;
    } catch (e) {
      if (!identical(_pendingSession, pendingSession)) return false;
      _markFailed(pendingSession.walletName, e);
      if (!showMessages || !context.mounted) return true;
      scaffoldMessenger!.showSnackBar(
        SnackBar(
          content: Text(l10n!.error(e.toString())),
          backgroundColor: Colors.red,
        ),
      );
      return true;
    } finally {
      if (identical(_closeWalletAuthSubscription, closeSubscription)) {
        _closeWalletAuthSubscription = null;
      }
      await closeSubscription?.call();
      _isCompletingPendingSession = false;
    }
  }

  Future<void> _addNwcWallet(
    NdkFlutter ndkFlutter, {
    required String nwcUri,
    required String walletName,
    String? providerId,
    bool requireAuthenticatedResponse = false,
  }) async {
    final walletId = DateTime.now().millisecondsSinceEpoch.toString();
    final nwcWallet = NwcWallet(
      id: walletId,
      name: walletName,
      supportedUnits: {'sat'},
      nwcUrl: nwcUri,
      providerId: providerId,
      metadata: {
        if (requireAuthenticatedResponse)
          NwcWallet.kRequireAuthenticatedResponseMetadataKey: true,
      },
    );
    await ndkFlutter.ndk.wallets.addWallet(nwcWallet);
    _lastConnectedWalletId = walletId;
  }
}

class _PendingNwcWalletAuthSession {
  final KeyPair appKey;
  final String discoveryRelay;
  final String returnTo;
  final String walletName;
  final String state;
  final String? walletServicePubkey;
  final String? providerId;
  final bool allowUntaggedInfoEvent;

  const _PendingNwcWalletAuthSession({
    required this.appKey,
    required this.discoveryRelay,
    required this.returnTo,
    required this.walletName,
    required this.state,
    required this.allowUntaggedInfoEvent,
    this.walletServicePubkey,
    this.providerId,
  });
}

class _NwcWalletAuthDiscoveryDialog extends StatefulWidget {
  final Uri? authorizationUri;
  final String walletName;
  final NwcWalletAuthCoordinator coordinator;
  final NdkFlutter ndkFlutter;
  final bool showAlbyGoQrInstructions;

  const _NwcWalletAuthDiscoveryDialog({
    this.authorizationUri,
    required this.walletName,
    required this.coordinator,
    required this.ndkFlutter,
    this.showAlbyGoQrInstructions = false,
  });

  @override
  State<_NwcWalletAuthDiscoveryDialog> createState() =>
      _NwcWalletAuthDiscoveryDialogState();
}

class _NwcWalletAuthDiscoveryDialogState
    extends State<_NwcWalletAuthDiscoveryDialog> {
  bool _waiting = false;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    widget.coordinator.connectionState.addListener(_onConnectionStateChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _waitForConnection());
  }

  @override
  void dispose() {
    widget.coordinator.connectionState.removeListener(
      _onConnectionStateChanged,
    );
    if (!_closing && widget.coordinator.hasPendingSession) {
      widget.coordinator.cancelPendingConnection();
    }
    super.dispose();
  }

  void _onConnectionStateChanged() {
    if (!mounted) return;
    final state = widget.coordinator.connectionState.value;
    if (state.phase == WalletConnectionPhase.connected && !_closing) {
      _closing = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).pop(true);
      });
      return;
    }
    setState(() {});
  }

  Future<void> _waitForConnection() async {
    if (_waiting) return;
    setState(() => _waiting = true);
    try {
      await widget.coordinator.completePendingWalletAuth(
        context,
        widget.ndkFlutter,
        timeout: null,
        showMessages: false,
      );
    } finally {
      if (mounted) setState(() => _waiting = false);
    }
  }

  void _cancel() {
    widget.coordinator.cancelPendingConnection();
    Navigator.of(context).pop(false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = widget.coordinator.connectionState.value;
    final failed = state.phase == WalletConnectionPhase.failed;

    return AlertDialog(
      title: Text(l10n.walletConnectionFinishIn(widget.walletName)),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.authorizationUri != null) ...[
              Semantics(
                label: l10n.scanNwcQrCodeTitle,
                child: ColoredBox(
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: SizedBox.square(
                      dimension: 300,
                      child: PrettyQrView.data(
                        data: widget.authorizationUri.toString(),
                        decoration: const PrettyQrDecoration(
                          quietZone: PrettyQrQuietZone.standard,
                          shape: PrettyQrSmoothSymbol(roundFactor: 0),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (widget.showAlbyGoQrInstructions) ...[
                const SizedBox(height: 12),
                Text(
                  l10n.albyGoQrScanInstructions,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: 16),
            ],
            if (_waiting) ...[
              const CircularProgressIndicator(),
              const SizedBox(height: 12),
            ],
            Text(
              failed
                  ? l10n.walletConnectionFailed(widget.walletName)
                  : l10n.fetchingWalletConnectionInfo,
              textAlign: TextAlign.center,
            ),
            if (failed && state.error != null) ...[
              const SizedBox(height: 8),
              Text(
                state.error!,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
      actions: [
        if (widget.authorizationUri != null)
          TextButton.icon(
            onPressed: () => Clipboard.setData(
              ClipboardData(text: widget.authorizationUri.toString()),
            ),
            icon: const Icon(Icons.copy_outlined),
            label: Text(l10n.copy),
          ),
        TextButton(onPressed: _cancel, child: Text(l10n.cancel)),
      ],
    );
  }
}

class _PendingNwcCallbackSession {
  final String returnTo;
  final String walletName;
  final String? providerId;

  const _PendingNwcCallbackSession({
    required this.returnTo,
    required this.walletName,
    this.providerId,
  });
}

/// Shows a dialog to add a Cashu wallet.
///
/// Returns the created [CashuWallet] if successful, or null if cancelled.
Future<CashuWallet?> showAddCashuWalletDialog(
  BuildContext context,
  NdkFlutter ndkFlutter, {
  String defaultMintUrl = _defaultMintUrl,
  bool returnToWalletType = false,
  AlbyGoConnectConfig albyGoConnectConfig = kDefaultAlbyGoConnectConfig,
  NwcWalletAuthCoordinator? nwcWalletAuthCoordinator,
  NwcUriScanner? nwcUriScanner,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final mintUrlController = TextEditingController(text: defaultMintUrl);

  return showDialog<CashuWallet?>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Row(
          children: [
            IconButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                if (returnToWalletType && context.mounted) {
                  await showAddWalletTypeDialog(
                    context,
                    ndkFlutter,
                    albyGoConnectConfig: albyGoConnectConfig,
                    nwcWalletAuthCoordinator: nwcWalletAuthCoordinator,
                    nwcUriScanner: nwcUriScanner,
                  );
                }
              },
              icon: const Icon(Icons.arrow_back),
            ),
            Expanded(child: Text(l10n.addCashuWalletTitle)),
            IconButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              icon: const Icon(Icons.close),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.enterMintUrl),
            const SizedBox(height: 16),
            TextField(
              controller: mintUrlController,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: l10n.mintUrl,
                hintText: l10n.mintUrlHint,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () async {
              final mintUrl = mintUrlController.text.trim();
              if (mintUrl.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.pleaseEnterMintUrl),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              final scaffoldMessenger = ScaffoldMessenger.of(context);

              try {
                await ndkFlutter.ndk.cashu.addMintToKnownMints(
                  mintUrl: mintUrl,
                );
                final mintInfo = await ndkFlutter.ndk.cashu.getMintInfoNetwork(
                  mintUrl: mintUrl,
                );

                final cashuWallet = CashuWallet(
                  id: mintUrl,
                  name: mintInfo.name ?? mintUrl,
                  mintUrl: mintUrl,
                  mintInfo: mintInfo,
                  supportedUnits: mintInfo.supportedUnits,
                );

                await ndkFlutter.ndk.wallets.addWallet(cashuWallet);

                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop(cashuWallet);
                }
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text(l10n.cashuWalletAdded),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text('${l10n.failedToAddMint}: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Text(l10n.add),
          ),
        ],
      );
    },
  );
}

/// Shows a dialog to add an NWC wallet.
///
/// Returns the created [NwcWallet] if successful, or null if cancelled.
Future<NwcWallet?> showAddNwcWalletDialog(
  BuildContext context,
  NdkFlutter ndkFlutter, {
  int defaultBalance = 10000,
  NwcUriScanner? nwcUriScanner,
}) async {
  return showDialog<NwcWallet?>(
    context: context,
    builder: (context) {
      return _AddNwcWalletDialog(
        ndkFlutter: ndkFlutter,
        defaultBalance: defaultBalance,
        nwcUriScanner: nwcUriScanner,
      );
    },
  );
}

class _AddNwcWalletDialog extends StatefulWidget {
  final NdkFlutter ndkFlutter;
  final int defaultBalance;
  final NwcUriScanner? nwcUriScanner;

  const _AddNwcWalletDialog({
    required this.ndkFlutter,
    required this.defaultBalance,
    required this.nwcUriScanner,
  });

  @override
  State<_AddNwcWalletDialog> createState() => _AddNwcWalletDialogState();
}

class _AddNwcWalletDialogState extends State<_AddNwcWalletDialog>
    with SingleTickerProviderStateMixin {
  final nwcUriController = TextEditingController();
  late final balanceController = TextEditingController(
    text: widget.defaultBalance.toString(),
  );
  late TabController _tabController;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    nwcUriController.dispose();
    balanceController.dispose();
    super.dispose();
  }

  Future<void> _scanNwcUri() async {
    final nwcUriScanner = widget.nwcUriScanner;
    if (nwcUriScanner == null) return;

    final scannedUri = await nwcUriScanner(context);
    if (!mounted || scannedUri == null) return;

    final trimmedUri = scannedUri.trim();
    if (trimmedUri.startsWith(Nwc.kNWCProtocolPrefix)) {
      nwcUriController.text = trimmedUri;
      return;
    }

    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.invalidNwcQrCode),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back),
          ),
          Expanded(child: Text(l10n.addNwcWalletTitle)),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TabBar(
              controller: _tabController,
              tabs: [
                Tab(text: l10n.faucet),
                Tab(text: l10n.manual),
              ],
            ),
            SizedBox(
              height: 150,
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Faucet Tab
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Text(
                          l10n.nwcFaucetDescription,
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: balanceController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            border: const OutlineInputBorder(),
                            labelText: '${l10n.startingBalance} (sats)',
                            hintText: l10n.startingBalanceHint,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Manual Tab
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        TextField(
                          controller: nwcUriController,
                          decoration: InputDecoration(
                            border: const OutlineInputBorder(),
                            labelText: l10n.nwcConnectionUri,
                            hintText: l10n.nwcConnectionUriHint,
                            suffixIcon: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  onPressed: () async {
                                    final clipboardData =
                                        await Clipboard.getData(
                                          Clipboard.kTextPlain,
                                        );
                                    if (clipboardData?.text != null) {
                                      nwcUriController.text =
                                          clipboardData!.text!;
                                    }
                                  },
                                  icon: const Icon(Icons.paste),
                                  tooltip: l10n.copy,
                                ),
                                if (widget.nwcUriScanner != null)
                                  IconButton(
                                    onPressed: _scanNwcUri,
                                    icon: const Icon(Icons.qr_code_scanner),
                                    tooltip: l10n.scanNwcQrCodeTitle,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        TextButton(
          onPressed: isLoading
              ? null
              : () async {
                  final currentTab = _tabController.index;
                  final scaffoldMessenger = ScaffoldMessenger.of(context);
                  final navigator = Navigator.of(context);

                  if (currentTab == 0) {
                    // Faucet tab
                    setState(() => isLoading = true);

                    try {
                      final balance =
                          int.tryParse(balanceController.text) ??
                          widget.defaultBalance;
                      final response = await http.post(
                        Uri.parse('https://faucet.nwc.dev?balance=$balance'),
                      );

                      if (response.statusCode == 200) {
                        final nwcUri = response.body.trim();

                        if (nwcUri.isNotEmpty) {
                          final walletId = DateTime.now().millisecondsSinceEpoch
                              .toString();
                          final nwcWallet = NwcWallet(
                            id: walletId,
                            name: 'NWC Faucet',
                            supportedUnits: {'sat'},
                            nwcUrl: nwcUri,
                          );
                          await widget.ndkFlutter.ndk.wallets.addWallet(
                            nwcWallet,
                          );

                          if (!mounted) return;
                          navigator.pop(nwcWallet);
                          scaffoldMessenger.showSnackBar(
                            SnackBar(
                              content: Text(l10n.nwcFaucetWalletAdded(balance)),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } else {
                          scaffoldMessenger.showSnackBar(
                            SnackBar(
                              content: Text(l10n.invalidFaucetResponse),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      } else {
                        scaffoldMessenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              '${l10n.errorCreatingWallet}: ${response.statusCode}',
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    } catch (e) {
                      scaffoldMessenger.showSnackBar(
                        SnackBar(
                          content: Text('${l10n.errorCreatingWallet}: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    } finally {
                      if (mounted) {
                        setState(() => isLoading = false);
                      }
                    }
                  } else {
                    // Manual tab
                    try {
                      final walletId = DateTime.now().millisecondsSinceEpoch
                          .toString();
                      final nwcWallet = NwcWallet(
                        id: walletId,
                        name: 'NWC',
                        supportedUnits: {'sat'},
                        nwcUrl: nwcUriController.text,
                      );
                      await widget.ndkFlutter.ndk.wallets.addWallet(nwcWallet);

                      if (!mounted) return;
                      navigator.pop(nwcWallet);
                      scaffoldMessenger.showSnackBar(
                        SnackBar(
                          content: Text(l10n.nwcWalletAdded),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } catch (e) {
                      scaffoldMessenger.showSnackBar(
                        SnackBar(
                          content: Text(e.toString()),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
          child: isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.add),
        ),
      ],
    );
  }
}

/// Shows a dialog to add an LNURL wallet.
///
/// Returns the created [Wallet] if successful, or null if cancelled.
Future<Wallet?> showAddLnurlWalletDialog(
  BuildContext context,
  NdkFlutter ndkFlutter, {
  bool returnToWalletType = false,
  AlbyGoConnectConfig albyGoConnectConfig = kDefaultAlbyGoConnectConfig,
  NwcWalletAuthCoordinator? nwcWalletAuthCoordinator,
  NwcUriScanner? nwcUriScanner,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final identifierController = TextEditingController();

  // Check if user is logged in and has lud16 in their profile
  String? profileLud16;
  if (ndkFlutter.ndk.accounts.isLoggedIn) {
    final pubkey = ndkFlutter.ndk.accounts.getPublicKey();
    if (pubkey != null) {
      try {
        final metadata = await ndkFlutter.ndk.metadata.loadMetadata(pubkey);
        profileLud16 = metadata?.lud16;
      } catch (e) {
        // Ignore errors loading metadata
      }
    }
  }

  if (!context.mounted) return null;

  return showDialog<Wallet?>(
    context: context,
    builder: (dialogContext) {
      return _AddLnurlWalletDialog(
        l10n: l10n,
        identifierController: identifierController,
        profileLud16: profileLud16,
        ndkFlutter: ndkFlutter,
        parentContext: context,
        returnToWalletType: returnToWalletType,
        albyGoConnectConfig: albyGoConnectConfig,
        nwcWalletAuthCoordinator: nwcWalletAuthCoordinator,
        nwcUriScanner: nwcUriScanner,
      );
    },
  );
}

class _AddLnurlWalletDialog extends StatefulWidget {
  final AppLocalizations l10n;
  final TextEditingController identifierController;
  final String? profileLud16;
  final NdkFlutter ndkFlutter;
  final BuildContext parentContext;
  final bool returnToWalletType;
  final AlbyGoConnectConfig albyGoConnectConfig;
  final NwcWalletAuthCoordinator? nwcWalletAuthCoordinator;
  final NwcUriScanner? nwcUriScanner;

  const _AddLnurlWalletDialog({
    required this.l10n,
    required this.identifierController,
    required this.profileLud16,
    required this.ndkFlutter,
    required this.parentContext,
    required this.returnToWalletType,
    required this.albyGoConnectConfig,
    required this.nwcWalletAuthCoordinator,
    required this.nwcUriScanner,
  });

  @override
  State<_AddLnurlWalletDialog> createState() => _AddLnurlWalletDialogState();
}

class _AddLnurlWalletDialogState extends State<_AddLnurlWalletDialog> {
  Future<void> _addWalletWithIdentifier(String identifier) async {
    if (identifier.isEmpty || !identifier.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.l10n.pleaseEnterValidIdentifier),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      final walletId = DateTime.now().millisecondsSinceEpoch.toString();
      final wallet = widget.ndkFlutter.ndk.wallets.createWallet(
        type: WalletType.LNURL,
        id: walletId,
        name: identifier,
        supportedUnits: {'sat'},
        metadata: {'identifier': identifier},
      );
      await widget.ndkFlutter.ndk.wallets.addWallet(wallet);

      if (!mounted) return;
      Navigator.of(context).pop(wallet);
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(widget.l10n.lnurlWalletAdded),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _addManualWallet() async {
    final identifier = widget.identifierController.text.trim();
    await _addWalletWithIdentifier(identifier);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          IconButton(
            onPressed: () async {
              Navigator.of(context).pop();
              if (widget.returnToWalletType && widget.parentContext.mounted) {
                await showAddWalletTypeDialog(
                  widget.parentContext,
                  widget.ndkFlutter,
                  albyGoConnectConfig: widget.albyGoConnectConfig,
                  nwcWalletAuthCoordinator: widget.nwcWalletAuthCoordinator,
                  nwcUriScanner: widget.nwcUriScanner,
                );
              }
            },
            icon: const Icon(Icons.arrow_back),
          ),
          Expanded(child: Text(widget.l10n.addLnurlWalletTitle)),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.l10n.enterLnurlIdentifier),
          const SizedBox(height: 16),
          // Show profile lud16 option if available
          if (widget.profileLud16 != null &&
              widget.profileLud16!.isNotEmpty) ...[
            Card(
              child: ListTile(
                leading: NPicture(
                  ndkFlutter: widget.ndkFlutter,
                  circleAvatarRadius: 20,
                ),
                title: Text(widget.profileLud16!),
                subtitle: Text(widget.l10n.fromYourProfile),
                trailing: TextButton(
                  onPressed: () =>
                      _addWalletWithIdentifier(widget.profileLud16!),
                  child: Text(widget.l10n.add),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Text(
              widget.l10n.orEnterManually,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 8),
          ],
          TextField(
            controller: widget.identifierController,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              labelText: widget.l10n.lnurlIdentifierHint,
              hintText: widget.l10n.lnurlIdentifierHint,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(widget.l10n.cancel),
        ),
        TextButton(onPressed: _addManualWallet, child: Text(widget.l10n.add)),
      ],
    );
  }
}

/// Shows a dialog to add a receive-only BOLT12 offer wallet.
Future<Bolt12Wallet?> showAddBolt12WalletDialog(
  BuildContext context,
  NdkFlutter ndkFlutter, {
  bool returnToWalletType = false,
  AlbyGoConnectConfig albyGoConnectConfig = kDefaultAlbyGoConnectConfig,
  NwcWalletAuthCoordinator? nwcWalletAuthCoordinator,
  NwcUriScanner? nwcUriScanner,
  Bolt12InputScanner? bolt12InputScanner,
}) {
  return showDialog<Bolt12Wallet?>(
    context: context,
    builder: (dialogContext) => _AddBolt12WalletDialog(
      ndkFlutter: ndkFlutter,
      parentContext: context,
      returnToWalletType: returnToWalletType,
      albyGoConnectConfig: albyGoConnectConfig,
      nwcWalletAuthCoordinator: nwcWalletAuthCoordinator,
      nwcUriScanner: nwcUriScanner,
      bolt12InputScanner: bolt12InputScanner,
    ),
  );
}

class _AddBolt12WalletDialog extends StatefulWidget {
  final NdkFlutter ndkFlutter;
  final BuildContext parentContext;
  final bool returnToWalletType;
  final AlbyGoConnectConfig albyGoConnectConfig;
  final NwcWalletAuthCoordinator? nwcWalletAuthCoordinator;
  final NwcUriScanner? nwcUriScanner;
  final Bolt12InputScanner? bolt12InputScanner;

  const _AddBolt12WalletDialog({
    required this.ndkFlutter,
    required this.parentContext,
    required this.returnToWalletType,
    required this.albyGoConnectConfig,
    required this.nwcWalletAuthCoordinator,
    required this.nwcUriScanner,
    required this.bolt12InputScanner,
  });

  @override
  State<_AddBolt12WalletDialog> createState() => _AddBolt12WalletDialogState();
}

class _AddBolt12WalletDialogState extends State<_AddBolt12WalletDialog> {
  final _inputController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _inputController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _scan() async {
    final scanner = widget.bolt12InputScanner;
    if (scanner == null) return;
    final value = await scanner(context);
    if (!mounted || value == null) return;

    if (Bolt12WalletProvider.isSupportedInput(value)) {
      _inputController.text = value.trim();
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.invalidBolt12QrCode),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _add() async {
    final l10n = AppLocalizations.of(context)!;
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final input = _inputController.text.trim();
    if (input.isEmpty) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(l10n.pleaseEnterBolt12Input),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final resolved = await Bolt12WalletProvider.resolveInput(input);
      final requestedName = _nameController.text.trim();
      final description = resolved.decoded['offer_description'] as String?;
      final name = requestedName.isNotEmpty
          ? requestedName
          : resolved.bip353Address ?? description ?? l10n.bolt12Wallet;
      final wallet =
          widget.ndkFlutter.ndk.wallets.createWallet(
                id: 'bolt12-${DateTime.now().microsecondsSinceEpoch}',
                name: name,
                type: WalletType.BOLT12,
                supportedUnits: {'sat'},
                metadata: resolved.toMetadata(),
              )
              as Bolt12Wallet;
      await widget.ndkFlutter.ndk.wallets.addWallet(wallet);

      if (!mounted) return;
      Navigator.of(context).pop(wallet);
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(l10n.bolt12WalletAdded),
          backgroundColor: Colors.green,
        ),
      );
    } catch (error) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text(error.toString()), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Row(
        children: [
          IconButton(
            onPressed: () async {
              Navigator.of(context).pop();
              if (widget.returnToWalletType && widget.parentContext.mounted) {
                await showAddWalletTypeDialog(
                  widget.parentContext,
                  widget.ndkFlutter,
                  albyGoConnectConfig: widget.albyGoConnectConfig,
                  nwcWalletAuthCoordinator: widget.nwcWalletAuthCoordinator,
                  nwcUriScanner: widget.nwcUriScanner,
                  bolt12InputScanner: widget.bolt12InputScanner,
                );
              }
            },
            icon: const Icon(Icons.arrow_back),
          ),
          Expanded(child: Text(l10n.addBolt12WalletTitle)),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
      content: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.enterBolt12Input),
            const SizedBox(height: 16),
            TextField(
              controller: _inputController,
              minLines: 2,
              maxLines: 4,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: l10n.bolt12Input,
                hintText: l10n.bolt12InputHint,
                suffixIcon: widget.bolt12InputScanner == null
                    ? null
                    : IconButton(
                        onPressed: _scan,
                        icon: const Icon(Icons.qr_code_scanner),
                        tooltip: l10n.scanBolt12QrCodeTitle,
                      ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: l10n.walletNameOptional,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        TextButton(
          onPressed: _isLoading ? null : _add,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.add),
        ),
      ],
    );
  }
}

/// Shows the unified add-wallet flow.
///
/// Scan and paste accept every supported wallet input. Wallet-assisted NWC and
/// type-specific manual setup remain available as alternative paths.
Future<bool> showAddWalletTypeDialog(
  BuildContext context,
  NdkFlutter ndkFlutter, {
  AlbyGoConnectConfig albyGoConnectConfig = kDefaultAlbyGoConnectConfig,
  NwcWalletAuthCoordinator? nwcWalletAuthCoordinator,
  WalletInputScanner? walletInputScanner,
  WalletQrScannerBuilder? walletQrScannerBuilder,
  List<NwcConnectionOption>? nwcConnectionOptions,
  NwcUriScanner? nwcUriScanner,
  Bolt12InputScanner? bolt12InputScanner,
}) async {
  final coordinator = nwcWalletAuthCoordinator ?? NwcWalletAuthCoordinator();
  coordinator.resetTerminalConnectionState();
  final legacyScanner = nwcUriScanner ?? bolt12InputScanner;
  final scanner =
      walletInputScanner ??
      (legacyScanner == null
          ? (context, configuration) => showWalletInputDialog(
              context,
              configuration,
              qrScannerBuilder: walletQrScannerBuilder,
            )
          : (BuildContext context, WalletInputScannerConfiguration _) async {
              final value = await legacyScanner(context);
              return value == null ? null : WalletInputScanResult.value(value);
            });
  return await showDialog<bool>(
        context: context,
        builder: (dialogContext) => _AddWalletFlow(
          ndkFlutter: ndkFlutter,
          parentContext: context,
          albyGoConnectConfig: albyGoConnectConfig,
          nwcWalletAuthCoordinator: coordinator,
          walletInputScanner: scanner,
          nwcConnectionOptions:
              nwcConnectionOptions ??
              defaultNwcConnectionOptions(config: albyGoConnectConfig),
        ),
      ) ??
      false;
}

class _AddWalletFlow extends StatefulWidget {
  final NdkFlutter ndkFlutter;
  final BuildContext parentContext;
  final AlbyGoConnectConfig albyGoConnectConfig;
  final NwcWalletAuthCoordinator nwcWalletAuthCoordinator;
  final WalletInputScanner walletInputScanner;
  final List<NwcConnectionOption> nwcConnectionOptions;

  const _AddWalletFlow({
    required this.ndkFlutter,
    required this.parentContext,
    required this.albyGoConnectConfig,
    required this.nwcWalletAuthCoordinator,
    required this.walletInputScanner,
    required this.nwcConnectionOptions,
  });

  @override
  State<_AddWalletFlow> createState() => _AddWalletFlowState();
}

class _WalletInputPreview {
  final String input;
  final bool manuallyEntered;
  final WalletInputKind detectedKind;
  final WalletType walletType;
  final String name;
  final List<_WalletPreviewDetail> details;
  final WalletInputOrigin origin;
  final CashuMintSuggestion? cashuMintSuggestion;
  final Bolt12ResolvedOffer? resolvedOffer;
  final CashuMintInfo? mintInfo;
  final LnBitsConnectionInput? lnBitsConnection;
  final String? providerId;

  const _WalletInputPreview({
    required this.input,
    required this.manuallyEntered,
    required this.detectedKind,
    required this.walletType,
    required this.name,
    required this.details,
    required this.origin,
    this.cashuMintSuggestion,
    this.resolvedOffer,
    this.mintInfo,
    this.lnBitsConnection,
    this.providerId,
  });
}

class _WalletPreviewDetail {
  final String label;
  final String value;

  const _WalletPreviewDetail(this.label, this.value);
}

class _AddWalletFlowState extends State<_AddWalletFlow> {
  final _inputController = TextEditingController();
  final _walletNameController = TextEditingController();
  final _lnBitsUrlController = TextEditingController();
  final _lnBitsAdminKeyController = TextEditingController();
  WalletInputKind? _inputKind;
  String? _errorMessage;
  bool _isAdding = false;
  bool _isResolvingDetails = false;
  _WalletInputPreview? _preview;
  bool _scannerOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _scan();
    });
  }

  @override
  void dispose() {
    _inputController.dispose();
    _walletNameController.dispose();
    _lnBitsUrlController.dispose();
    _lnBitsAdminKeyController.dispose();
    super.dispose();
  }

  Future<void> _scan({
    WalletInputOrigin initialOrigin = WalletInputOrigin.scanner,
  }) async {
    if (_scannerOpen) return;
    setState(() => _scannerOpen = true);
    WalletInputScanResult? result;
    try {
      result = await widget.walletInputScanner(
        context,
        _scannerConfiguration(
          openWalletChooserInitially:
              initialOrigin != WalletInputOrigin.scanner,
          openCashuMintChooserInitially:
              initialOrigin == WalletInputOrigin.cashuMintChooser,
        ),
      );
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[wallet-scan] scanner failed: ${error.runtimeType}');
      }
      if (mounted) _closeWithError(error);
      return;
    } finally {
      if (mounted) setState(() => _scannerOpen = false);
    }
    if (!mounted) return;
    if (result == null) {
      Navigator.of(context).pop(false);
      return;
    }
    if (result.connectionStarted) {
      widget.nwcWalletAuthCoordinator.cancelPendingConnection();
      Navigator.of(context).pop(true);
      return;
    }
    if (result.lnBitsConnection case final connection?) {
      await _prepareLnBitsPreview(connection);
      return;
    }
    if (result.value != null) {
      await _preparePreview(
        result.value!,
        manuallyEntered: result.manuallyEntered,
        origin: result.origin,
        cashuMintSuggestion: result.cashuMintSuggestion,
        providerId: result.providerId,
      );
    }
  }

  void _closeWithError(Object error) {
    final message = error.toString();
    final messenger = ScaffoldMessenger.maybeOf(widget.parentContext);
    messenger?.showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
    Navigator.of(context).pop(false);
  }

  Future<void> _prepareLnBitsPreview(LnBitsConnectionInput connection) async {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _isResolvingDetails = true;
      _errorMessage = null;
    });
    try {
      final validated = connection.walletName == null
          ? await _validateLnBitsConnection(connection)
          : connection;
      if (!mounted) return;
      final preview = _WalletInputPreview(
        input: validated.url,
        manuallyEntered: true,
        origin: WalletInputOrigin.walletChooser,
        detectedKind: WalletInputKind.lnBits,
        walletType: WalletType.LNBITS,
        name: validated.walletName!,
        lnBitsConnection: validated,
        details: [
          _WalletPreviewDetail(l10n.walletDetailType, l10n.lnbitsWalletOption),
          _WalletPreviewDetail(l10n.lnbitsUrl, validated.url),
          _WalletPreviewDetail(
            validated.readOnly
                ? l10n.lnbitsInvoiceReadKey
                : l10n.lnbitsAdminKey,
            l10n.walletSecretHidden,
          ),
          if (validated.remoteWalletId?.isNotEmpty == true)
            _WalletPreviewDetail(
              l10n.walletDetailWalletId,
              validated.remoteWalletId!,
            ),
        ],
      );
      setState(() {
        _preview = preview;
        _lnBitsUrlController.text = validated.url;
        _lnBitsAdminKeyController.text = validated.adminKey;
        _walletNameController.text = preview.name;
      });
    } catch (error) {
      if (mounted) _closeWithError(error);
    } finally {
      if (mounted) setState(() => _isResolvingDetails = false);
    }
  }

  Future<LnBitsConnectionInput> _validateLnBitsConnection(
    LnBitsConnectionInput connection,
  ) async {
    final normalizedUrl = LnBitsWalletProvider.normalizeUrl(connection.url);
    final adminKey = connection.adminKey.trim();
    final info = await LnBitsWalletProvider.probe(
      lnbitsUrl: normalizedUrl,
      adminKey: adminKey,
    );
    return LnBitsConnectionInput(
      url: normalizedUrl,
      adminKey: adminKey,
      walletName: info.name,
      remoteWalletId: info.id,
      readOnly: connection.readOnly,
    );
  }

  void _cancelPreview() {
    final origin = _preview?.origin ?? WalletInputOrigin.scanner;
    setState(() {
      _preview = null;
      _errorMessage = null;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _scan(initialOrigin: origin);
    });
  }

  WalletInputScannerConfiguration _scannerConfiguration({
    bool openWalletChooserInitially = false,
    bool openCashuMintChooserInitially = false,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final options = <WalletScannerConnectionOption>[];
    final showInstalledWallets =
        !kIsWeb && (Platform.isAndroid || Platform.isIOS);

    if (showInstalledWallets) {
      options.add(
        WalletScannerConnectionOption(
          id: 'installed-wallet',
          label: l10n.chooseWalletApp,
          subtitle: l10n.chooseWalletAppDescription,
          kind: WalletScannerConnectionKind.installedWallet,
          iconBuilder: (_) => const Icon(Icons.account_balance_wallet_outlined),
          connect: _launchInstalledWallet,
        ),
      );
    }
    options.add(
      WalletScannerConnectionOption(
        id: 'alby-go',
        label: l10n.albyGoOption,
        kind: WalletScannerConnectionKind.albyGo,
        iconBuilder: (_) => Image.asset(
          'assets/images/albygo.png',
          package: 'ndk_flutter',
          width: 28,
          height: 28,
        ),
        connect: _launchAlbyGo,
      ),
    );

    for (final option in widget.nwcConnectionOptions) {
      options.add(
        WalletScannerConnectionOption(
          id: option.id,
          label: option.label,
          subtitle: option.subtitle,
          kind: WalletScannerConnectionKind.custom,
          iconBuilder: option.iconBuilder,
          connect: () => _launchConnectionOption(option),
        ),
      );
    }

    return WalletInputScannerConfiguration(
      supportedInputDescription: l10n.walletInputHint,
      connectionSectionTitle: l10n.connectWithWallet,
      connectionOptions: options,
      connectionState: widget.nwcWalletAuthCoordinator.connectionState,
      retryPendingConnection: () => widget.nwcWalletAuthCoordinator
          .retryPendingConnection(widget.parentContext, widget.ndkFlutter),
      cancelPendingConnection:
          widget.nwcWalletAuthCoordinator.cancelPendingConnection,
      discoverCashuMints: _discoverCashuMints,
      enrichCashuMint: _enrichCashuMint,
      validateLnBitsConnection: _validateLnBitsConnection,
      openWalletChooserInitially: openWalletChooserInitially,
      openCashuMintChooserInitially: openCashuMintChooserInitially,
    );
  }

  Future<List<CashuMintSuggestion>> _discoverCashuMints() async {
    final recommendations = await widget.ndkFlutter.ndk.cashu
        .discoverMintRecommendations();
    final suggestions = recommendations.map((recommendation) {
      final info = recommendation.mintInfo;
      final fallbackName =
          Uri.tryParse(recommendation.url)?.host ?? recommendation.url;
      return CashuMintSuggestion(
        url: recommendation.url,
        name: info?.name?.trim().isNotEmpty == true
            ? info!.name!.trim()
            : fallbackName,
        iconUrl: info?.iconUrl?.trim().isNotEmpty == true
            ? info!.iconUrl!.trim()
            : null,
        averageRating: recommendation.averageRating,
        reviewsCount: recommendation.reviewsCount,
        reviews: recommendation.reviews
            .where((review) => review.comment.isNotEmpty)
            .take(5)
            .map(
              (review) => CashuMintReview(
                rating: review.rating,
                comment: review.comment,
              ),
            )
            .toList(),
      );
    }).toList();
    final existingMintUrls = (await widget.ndkFlutter.ndk.wallets.getWallets())
        .whereType<CashuWallet>()
        .map((wallet) => wallet.mintUrl.replaceAll(RegExp(r'/+$'), ''))
        .toSet();
    return suggestions
        .where((suggestion) => !existingMintUrls.contains(suggestion.url))
        .toList();
  }

  Future<CashuMintSuggestion> _enrichCashuMint(
    CashuMintSuggestion suggestion,
  ) async {
    final recommendation = CashuMintRecommendation(
      url: suggestion.url,
      averageRating: suggestion.averageRating,
      reviewsCount: suggestion.reviewsCount,
    );
    final enriched = await widget.ndkFlutter.ndk.cashu.enrichMintRecommendation(
      recommendation,
    );
    final info = enriched.mintInfo;
    return CashuMintSuggestion(
      url: suggestion.url,
      name: info?.name?.trim().isNotEmpty == true
          ? info!.name!.trim()
          : suggestion.name,
      iconUrl: info?.iconUrl?.trim().isNotEmpty == true
          ? info!.iconUrl!.trim()
          : suggestion.iconUrl,
      averageRating: suggestion.averageRating,
      reviewsCount: suggestion.reviewsCount,
      reviews: suggestion.reviews,
    );
  }

  void _setInput(String value) {
    final normalized = _normalizeWalletInput(value);
    final kind = classifyWalletInput(normalized);
    setState(() {
      _inputController.text = normalized;
      _inputController.selection = TextSelection.collapsed(
        offset: normalized.length,
      );
      _inputKind = kind;
      _errorMessage = kind == null
          ? AppLocalizations.of(context)!.unsupportedWalletInput
          : null;
    });
  }

  void _onInputChanged(String value) {
    final kind = classifyWalletInput(value);
    setState(() {
      _inputKind = kind;
      _errorMessage = null;
    });
  }

  Future<void> _preparePreview(
    String rawInput, {
    bool manuallyEntered = false,
    WalletInputOrigin origin = WalletInputOrigin.scanner,
    CashuMintSuggestion? cashuMintSuggestion,
    String? providerId,
  }) async {
    final input = _normalizeWalletInput(rawInput);
    _setInput(input);
    final kind = classifyWalletInput(input);
    if (kDebugMode) {
      debugPrint(
        '[wallet-scan] preview input: '
        'kind=${kind?.name ?? 'unsupported'}, characters=${input.length}',
      );
    }
    if (kind == null) {
      _closeWithError(
        _errorMessage ?? AppLocalizations.of(context)!.unsupportedWalletInput,
      );
      return;
    }

    setState(() {
      _isResolvingDetails = true;
      _errorMessage = null;
    });

    try {
      final preview = await _resolvePreview(
        input,
        kind,
        manuallyEntered,
        origin,
        cashuMintSuggestion,
        providerId,
      );
      if (!mounted) return;
      setState(() {
        _preview = preview;
        _walletNameController.text = preview.name;
        _walletNameController.selection = TextSelection.collapsed(
          offset: preview.name.length,
        );
      });
      if (kDebugMode) {
        debugPrint('[wallet-scan] confirmation ready: ${kind.name}');
      }
    } catch (error) {
      if (!mounted) return;
      if (kDebugMode) {
        debugPrint('[wallet-scan] preview failed: ${error.runtimeType}');
      }
      _closeWithError(error);
    } finally {
      if (mounted) setState(() => _isResolvingDetails = false);
    }
  }

  Future<_WalletInputPreview> _resolvePreview(
    String input,
    WalletInputKind kind,
    bool manuallyEntered,
    WalletInputOrigin origin,
    CashuMintSuggestion? cashuMintSuggestion,
    String? providerId,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    switch (kind) {
      case WalletInputKind.nwc:
        final parsed = NostrWalletConnectUri.parseConnectionUri(input);
        final relayHost = parsed.relays.isEmpty
            ? null
            : Uri.tryParse(parsed.relays.first)?.host;
        final name = parsed.lud16?.trim().isNotEmpty == true
            ? parsed.lud16!.trim()
            : relayHost?.isNotEmpty == true
            ? 'NWC · $relayHost'
            : l10n.nwcWalletTypeTitle;
        return _WalletInputPreview(
          input: input,
          manuallyEntered: manuallyEntered,
          origin: origin,
          detectedKind: kind,
          walletType: WalletType.NWC,
          name: name,
          providerId: providerId,
          details: [
            _WalletPreviewDetail(
              l10n.walletDetailType,
              l10n.nwcWalletTypeTitle,
            ),
            if (parsed.lud16?.trim().isNotEmpty == true)
              _WalletPreviewDetail(
                l10n.walletDetailAddress,
                parsed.lud16!.trim(),
              ),
            _WalletPreviewDetail(
              l10n.walletDetailPublicKey,
              parsed.walletPubkey,
            ),
            _WalletPreviewDetail(
              parsed.relays.length == 1
                  ? l10n.walletDetailRelay
                  : l10n.walletDetailRelays,
              parsed.relays.join('\n'),
            ),
            _WalletPreviewDetail(
              l10n.walletDetailSecret,
              l10n.walletSecretHidden,
            ),
          ],
        );
      case WalletInputKind.bolt12:
        final resolved = await Bolt12WalletProvider.resolveInput(input);
        return _bolt12Preview(
          input,
          kind,
          resolved,
          l10n,
          manuallyEntered,
          origin,
        );
      case WalletInputKind.lightningAddress:
        try {
          final resolved = await Bolt12WalletProvider.resolveInput(input);
          return _bolt12Preview(
            input,
            kind,
            resolved,
            l10n,
            manuallyEntered,
            origin,
          );
        } catch (_) {
          final address = input.replaceFirst('₿', '');
          final parts = address.split('@');
          if (parts.length != 2) {
            throw FormatException(l10n.unsupportedWalletInput);
          }
          final lnurlPayUrl = Uri.https(
            parts.last,
            '/.well-known/lnurlp/${parts.first}',
          );
          final response = await http
              .get(lnurlPayUrl)
              .timeout(const Duration(seconds: 10));
          final body = response.statusCode >= 200 && response.statusCode < 300
              ? jsonDecode(response.body)
              : null;
          if (body is! Map<String, dynamic> || body['tag'] != 'payRequest') {
            throw FormatException(l10n.unsupportedWalletInput);
          }
          return _WalletInputPreview(
            input: address,
            manuallyEntered: manuallyEntered,
            origin: origin,
            detectedKind: kind,
            walletType: WalletType.LNURL,
            name: address,
            details: [
              _WalletPreviewDetail(l10n.walletDetailType, l10n.lnurlProtocol),
              if (!manuallyEntered)
                _WalletPreviewDetail(l10n.walletDetailAddress, address),
            ],
          );
        }
      case WalletInputKind.cashuMint:
        final mintInfo = await widget.ndkFlutter.ndk.cashu.getMintInfoNetwork(
          mintUrl: input,
        );
        final name = mintInfo.name?.trim().isNotEmpty == true
            ? mintInfo.name!.trim()
            : 'Cashu · ${Uri.parse(input).host}';
        return _WalletInputPreview(
          input: input,
          manuallyEntered: manuallyEntered,
          origin: origin,
          cashuMintSuggestion: cashuMintSuggestion,
          detectedKind: kind,
          walletType: WalletType.CASHU,
          name: name,
          mintInfo: mintInfo,
          details: [
            _WalletPreviewDetail(
              l10n.walletDetailType,
              l10n.cashuWalletTypeTitle,
            ),
            _WalletPreviewDetail(l10n.walletDetailUrl, input),
            if (cashuMintSuggestion?.averageRating != null)
              _WalletPreviewDetail(
                l10n.walletDetailCommunityRating,
                l10n.cashuMintRating(
                  cashuMintSuggestion!.averageRating!.toStringAsFixed(1),
                  cashuMintSuggestion.reviewsCount,
                ),
              ),
            if (cashuMintSuggestion?.reviews.isNotEmpty == true)
              _WalletPreviewDetail(
                l10n.walletDetailCommunityReviews,
                cashuMintSuggestion!.reviews
                    .map(
                      (review) => review.rating == null
                          ? review.comment
                          : '★ ${review.rating}/5 — ${review.comment}',
                    )
                    .join('\n\n'),
              ),
            if (mintInfo.description?.trim().isNotEmpty == true)
              _WalletPreviewDetail(
                l10n.walletDetailDescription,
                mintInfo.description!.trim(),
              ),
            if (mintInfo.descriptionLong?.trim().isNotEmpty == true &&
                mintInfo.descriptionLong!.trim() !=
                    mintInfo.description?.trim())
              _WalletPreviewDetail(
                l10n.walletDetailDetails,
                mintInfo.descriptionLong!.trim(),
              ),
            if (mintInfo.version?.trim().isNotEmpty == true)
              _WalletPreviewDetail(
                l10n.walletDetailVersion,
                mintInfo.version!.trim(),
              ),
            if (mintInfo.pubkey?.trim().isNotEmpty == true)
              _WalletPreviewDetail(
                l10n.walletDetailPublicKey,
                mintInfo.pubkey!.trim(),
              ),
            if (mintInfo.supportedUnits.isNotEmpty)
              _WalletPreviewDetail(
                l10n.walletDetailUnits,
                mintInfo.supportedUnits.join(', '),
              ),
            if (mintInfo.contact.isNotEmpty)
              _WalletPreviewDetail(
                l10n.walletDetailContact,
                mintInfo.contact
                    .map((contact) => '${contact.method}: ${contact.info}')
                    .join('\n'),
              ),
            if (mintInfo.tosUrl?.trim().isNotEmpty == true)
              _WalletPreviewDetail(
                l10n.walletDetailTerms,
                mintInfo.tosUrl!.trim(),
              ),
            if (mintInfo.motd?.trim().isNotEmpty == true)
              _WalletPreviewDetail(
                l10n.walletDetailMessage,
                mintInfo.motd!.trim(),
              ),
          ],
        );
      case WalletInputKind.lnBits:
        throw StateError('LNbits uses structured connection details');
    }
  }

  _WalletInputPreview _bolt12Preview(
    String input,
    WalletInputKind detectedKind,
    Bolt12ResolvedOffer resolved,
    AppLocalizations l10n,
    bool manuallyEntered,
    WalletInputOrigin origin,
  ) {
    final metadata = resolved.toMetadata();
    final description = metadata['description']?.toString().trim();
    final issuer = metadata['issuer']?.toString().trim();
    final nodeId = metadata['nodeId']?.toString().trim();
    final amount = metadata['amount']?.toString().trim();
    final currency = metadata['currency']?.toString().trim();
    final expiresAt = metadata['expiresAt'] as int?;
    final name =
        resolved.bip353Address ??
        (issuer?.isNotEmpty == true
            ? issuer!
            : description?.isNotEmpty == true
            ? description!
            : l10n.bolt12WalletTypeTitle);
    return _WalletInputPreview(
      input: input,
      manuallyEntered: manuallyEntered,
      origin: origin,
      detectedKind: detectedKind,
      walletType: WalletType.BOLT12,
      name: name,
      resolvedOffer: resolved,
      details: [
        _WalletPreviewDetail(
          l10n.walletDetailType,
          resolved.bip353Address == null
              ? l10n.bolt12WalletTypeTitle
              : l10n.bip353WalletTypeTitle,
        ),
        if (resolved.bip353Address != null && !manuallyEntered)
          _WalletPreviewDetail(
            l10n.walletDetailAddress,
            resolved.bip353Address!,
          ),
        if (description?.isNotEmpty == true)
          _WalletPreviewDetail(l10n.walletDetailDescription, description!),
        if (issuer?.isNotEmpty == true)
          _WalletPreviewDetail(l10n.walletDetailIssuer, issuer!),
        if (amount?.isNotEmpty == true)
          _WalletPreviewDetail(l10n.walletDetailAmount, amount!),
        if (currency?.isNotEmpty == true)
          _WalletPreviewDetail(l10n.walletDetailCurrency, currency!),
        if (expiresAt != null)
          _WalletPreviewDetail(
            l10n.walletDetailExpiry,
            DateTime.fromMillisecondsSinceEpoch(
              expiresAt * 1000,
              isUtc: true,
            ).toLocal().toString(),
          ),
        if (nodeId?.isNotEmpty == true)
          _WalletPreviewDetail(l10n.walletDetailNodeId, nodeId!),
        _WalletPreviewDetail(l10n.walletDetailOffer, resolved.offer),
      ],
    );
  }

  Future<void> _confirmInput() async {
    var preview = _preview;
    if (preview == null) return;

    final isLnBits = preview.walletType == WalletType.LNBITS;
    late final String input;
    try {
      input = isLnBits
          ? LnBitsWalletProvider.normalizeUrl(_lnBitsUrlController.text)
          : _normalizeWalletInput(_inputController.text);
    } catch (error) {
      setState(() => _errorMessage = error.toString());
      return;
    }
    final kind = isLnBits ? WalletInputKind.lnBits : classifyWalletInput(input);
    if (kind == null) {
      setState(() {
        _errorMessage = AppLocalizations.of(context)!.unsupportedWalletInput;
      });
      return;
    }

    setState(() {
      _isAdding = true;
      _errorMessage = null;
      _inputKind = kind;
    });

    try {
      if (isLnBits) {
        final connection = await _validateLnBitsConnection(
          LnBitsConnectionInput(
            url: input,
            adminKey: _lnBitsAdminKeyController.text.trim(),
            readOnly: preview.lnBitsConnection?.readOnly ?? false,
          ),
        );
        preview = _WalletInputPreview(
          input: input,
          manuallyEntered: true,
          detectedKind: WalletInputKind.lnBits,
          walletType: WalletType.LNBITS,
          name: preview.name,
          details: preview.details,
          origin: preview.origin,
          lnBitsConnection: connection,
        );
      } else if (input != preview.input || kind != preview.detectedKind) {
        preview = await _resolvePreview(
          input,
          kind,
          true,
          preview.origin,
          preview.cashuMintSuggestion,
          preview.providerId,
        );
        if (!mounted) return;
        setState(() => _preview = preview);
      }
      final customName = _walletNameController.text.trim();
      final wallet = await _createWalletFromPreview(
        preview,
        walletName: customName.isEmpty ? preview.name : customName,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
      _showWalletAdded(wallet);
    } catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = error.toString());
    } finally {
      if (mounted) setState(() => _isAdding = false);
    }
  }

  Future<Wallet> _createWalletFromPreview(
    _WalletInputPreview preview, {
    required String walletName,
  }) async {
    switch (preview.walletType) {
      case WalletType.NWC:
        NostrWalletConnectUri.parseConnectionUri(preview.input);
        final wallet = NwcWallet(
          id: 'nwc-${DateTime.now().microsecondsSinceEpoch}',
          name: walletName,
          supportedUnits: const {'sat'},
          nwcUrl: preview.input,
          providerId: preview.providerId,
        );
        await widget.ndkFlutter.ndk.wallets.addWallet(wallet);
        return wallet;
      case WalletType.BOLT12:
        return _addResolvedBolt12Wallet(
          preview.resolvedOffer!,
          walletName: walletName,
        );
      case WalletType.LNURL:
        return _addLnurlWallet(preview.input, walletName: walletName);
      case WalletType.CASHU:
        return _addCashuWallet(
          preview.input,
          walletName: walletName,
          mintInfo: preview.mintInfo,
        );
      case WalletType.LNBITS:
        final connection = preview.lnBitsConnection!;
        final wallet = widget.ndkFlutter.ndk.wallets.createWallet(
          id: 'lnbits-${DateTime.now().microsecondsSinceEpoch}',
          name: walletName,
          type: WalletType.LNBITS,
          supportedUnits: const {'sat'},
          metadata: {
            LnBitsWallet.urlMetadataKey: connection.url,
            LnBitsWallet.adminKeyMetadataKey: connection.adminKey,
            LnBitsWallet.readOnlyMetadataKey: connection.readOnly,
            LnBitsWallet.remoteWalletIdMetadataKey: ?connection.remoteWalletId,
          },
        );
        await widget.ndkFlutter.ndk.wallets.addWallet(wallet);
        return wallet;
    }
  }

  Future<Bolt12Wallet> _addResolvedBolt12Wallet(
    Bolt12ResolvedOffer resolved, {
    required String walletName,
  }) async {
    final wallet =
        widget.ndkFlutter.ndk.wallets.createWallet(
              id: 'bolt12-${DateTime.now().microsecondsSinceEpoch}',
              name: walletName,
              type: WalletType.BOLT12,
              supportedUnits: const {'sat'},
              metadata: resolved.toMetadata(),
            )
            as Bolt12Wallet;
    await widget.ndkFlutter.ndk.wallets.addWallet(wallet);
    return wallet;
  }

  Future<Wallet> _addLnurlWallet(
    String identifier, {
    required String walletName,
  }) async {
    final wallet = widget.ndkFlutter.ndk.wallets.createWallet(
      id: 'lnurl-${DateTime.now().microsecondsSinceEpoch}',
      name: walletName,
      type: WalletType.LNURL,
      supportedUnits: const {'sat'},
      metadata: {'identifier': identifier},
    );
    await widget.ndkFlutter.ndk.wallets.addWallet(wallet);
    return wallet;
  }

  Future<CashuWallet> _addCashuWallet(
    String mintUrl, {
    required String walletName,
    CashuMintInfo? mintInfo,
  }) async {
    await widget.ndkFlutter.ndk.cashu.addMintToKnownMints(mintUrl: mintUrl);
    final resolvedMintInfo =
        mintInfo ??
        await widget.ndkFlutter.ndk.cashu.getMintInfoNetwork(mintUrl: mintUrl);
    final wallet = CashuWallet(
      id: mintUrl,
      name: walletName,
      mintUrl: mintUrl,
      mintInfo: resolvedMintInfo,
      supportedUnits: resolvedMintInfo.supportedUnits,
    );
    await widget.ndkFlutter.ndk.wallets.addWallet(wallet);
    return wallet;
  }

  void _showWalletAdded(Wallet wallet) {
    final l10n = AppLocalizations.of(widget.parentContext)!;
    final message = switch (wallet.type) {
      WalletType.NWC => l10n.nwcWalletAdded,
      WalletType.BOLT12 => l10n.bolt12WalletAdded,
      WalletType.LNURL => l10n.lnurlWalletAdded,
      WalletType.CASHU => l10n.cashuWalletAdded,
      WalletType.LNBITS => l10n.lnbitsWalletAdded,
    };
    ScaffoldMessenger.of(widget.parentContext).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  Future<void> _launchConnectionOption(NwcConnectionOption option) async {
    try {
      await option.connect(
        widget.parentContext,
        widget.ndkFlutter,
        widget.nwcWalletAuthCoordinator,
      );
    } catch (error) {
      if (!widget.parentContext.mounted) return;
      final l10n = AppLocalizations.of(widget.parentContext)!;
      ScaffoldMessenger.of(widget.parentContext).showSnackBar(
        SnackBar(
          content: Text(l10n.error(error.toString())),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _launchInstalledWallet() async {
    await widget.nwcWalletAuthCoordinator.connectInstalledWallet(
      widget.parentContext,
      config: widget.albyGoConnectConfig,
    );
  }

  Future<void> _launchAlbyGo() async {
    await widget.nwcWalletAuthCoordinator.connectAlbyGo(
      widget.parentContext,
      widget.ndkFlutter,
      config: widget.albyGoConnectConfig,
    );
  }

  Widget _buildConfirmationDialog(
    BuildContext context,
    _WalletInputPreview preview,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final icon = switch (preview.walletType) {
      WalletType.NWC => Icons.account_balance_wallet_outlined,
      WalletType.BOLT12 => Icons.bolt,
      WalletType.LNURL => Icons.alternate_email,
      WalletType.CASHU => Icons.toll_outlined,
      WalletType.LNBITS => Icons.bolt,
    };
    final mintIconUrl =
        preview.cashuMintSuggestion?.iconUrl?.trim().isNotEmpty == true
        ? preview.cashuMintSuggestion!.iconUrl!.trim()
        : preview.mintInfo?.iconUrl?.trim();
    final fallbackIcon = Icon(icon, size: 32, color: colors.onPrimaryContainer);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 720),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: preview.walletType == WalletType.LNBITS
                          ? const NLnBitsIcon(size: 64)
                          : Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: colors.primaryContainer,
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(18),
                                child:
                                    preview.walletType == WalletType.CASHU &&
                                        mintIconUrl?.isNotEmpty == true
                                    ? Image.network(
                                        mintIconUrl!,
                                        width: 64,
                                        height: 64,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, _, _) => fallbackIcon,
                                      )
                                    : fallbackIcon,
                              ),
                            ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      l10n.confirmWalletTitle,
                      style: theme.textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l10n.confirmWalletDescription,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 22),
                    if (preview.walletType == WalletType.LNBITS) ...[
                      if (preview.lnBitsConnection?.readOnly == true) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: colors.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.lock_outline,
                                color: colors.onPrimaryContainer,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  l10n.lnbitsReadOnlyDescription,
                                  style: TextStyle(
                                    color: colors.onPrimaryContainer,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      TextField(
                        controller: _lnBitsAdminKeyController,
                        enabled: !_isAdding,
                        obscureText: true,
                        enableSuggestions: false,
                        autocorrect: false,
                        decoration: InputDecoration(
                          border: const OutlineInputBorder(),
                          labelText: preview.lnBitsConnection?.readOnly == true
                              ? l10n.lnbitsInvoiceReadKey
                              : l10n.lnbitsAdminKey,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _lnBitsUrlController,
                        enabled: !_isAdding,
                        keyboardType: TextInputType.url,
                        autocorrect: false,
                        decoration: InputDecoration(
                          border: const OutlineInputBorder(),
                          labelText: l10n.lnbitsUrl,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ] else if (preview.manuallyEntered) ...[
                      TextField(
                        controller: _inputController,
                        onChanged: _onInputChanged,
                        enabled: !_isAdding,
                        obscureText:
                            classifyWalletInput(_inputController.text) ==
                            WalletInputKind.nwc,
                        enableSuggestions:
                            classifyWalletInput(_inputController.text) !=
                            WalletInputKind.nwc,
                        autocorrect: false,
                        decoration: InputDecoration(
                          border: const OutlineInputBorder(),
                          labelText: l10n.walletInput,
                          errorText: _inputKind == null ? _errorMessage : null,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    TextField(
                      controller: _walletNameController,
                      enabled: !_isAdding,
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        labelText: l10n.walletNameOptional,
                        hintText: l10n.walletNameHint,
                      ),
                    ),
                    const SizedBox(height: 12),
                    for (
                      var index = 0;
                      index < preview.details.length;
                      index++
                    ) ...[
                      if (index > 0)
                        Divider(height: 25, color: colors.outlineVariant),
                      Text(
                        preview.details[index].label,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      SelectableText(
                        preview.details[index].value,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          height: 1.4,
                        ),
                      ),
                    ],
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 20),
                      Text(
                        _errorMessage!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.error,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: colors.outlineVariant)),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isAdding ? null : _cancelPreview,
                        child: Text(l10n.cancel),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: _isAdding ? null : _confirmInput,
                        child: _isAdding
                            ? const SizedBox.square(
                                dimension: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(l10n.confirm),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final preview = _preview;
    if (preview != null) {
      return _buildConfirmationDialog(context, preview);
    }
    if (_isResolvingDetails) {
      return const Dialog(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text('Loading wallet details…'),
            ],
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}

/// Shows a dialog to choose NWC connection method.
///
/// Returns true if a connection method was selected, false if cancelled.
/// Use [albyGoConnectConfig] to override Alby Go app metadata.
Future<bool> showNwcConnectionOptionsDialog(
  BuildContext context,
  NdkFlutter ndkFlutter, {
  AlbyGoConnectConfig albyGoConnectConfig = kDefaultAlbyGoConnectConfig,
  NwcWalletAuthCoordinator? nwcWalletAuthCoordinator,
  NwcUriScanner? nwcUriScanner,
}) async {
  final l10n = AppLocalizations.of(context)!;

  return await showDialog<bool>(
        context: context,
        builder: (dialogContext) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: () async {
                        Navigator.of(dialogContext).pop(false);
                        if (context.mounted) {
                          await showAddWalletTypeDialog(
                            context,
                            ndkFlutter,
                            albyGoConnectConfig: albyGoConnectConfig,
                            nwcWalletAuthCoordinator: nwcWalletAuthCoordinator,
                            nwcUriScanner: nwcUriScanner,
                          );
                        }
                      },
                      icon: const Icon(Icons.arrow_back),
                    ),
                    Expanded(
                      child: Text(
                        l10n.connectNwcTitle,
                        style: Theme.of(context).textTheme.titleLarge,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(dialogContext).pop(false),
                      child: const Icon(Icons.close, size: 24),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.chooseNwcMethod,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                // Grid of connection options
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  alignment: WrapAlignment.center,
                  children: [
                    // Alby Go button (on mobile native platforms, not web)
                    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS))
                      _WalletTypeOptionButton(
                        imageAsset: 'assets/images/albygo.png',
                        label: l10n.albyGoOption,
                        onTap: () async {
                          Navigator.of(dialogContext).pop(true);
                          await (nwcWalletAuthCoordinator ??
                                  NwcWalletAuthCoordinator())
                              .connectAlbyGo(
                                context,
                                ndkFlutter,
                                config: albyGoConnectConfig,
                              );
                        },
                      ),
                    // Manual connection button (with optional QR scanner hook)
                    _WalletTypeOptionButton(
                      icon: Icons.edit,
                      label: l10n.manualOption,
                      onTap: () async {
                        Navigator.of(dialogContext).pop(true);
                        await _showNwcUriInputAndAddWallet(
                          context,
                          ndkFlutter,
                          returnToNwcOptions: true,
                          albyGoConnectConfig: albyGoConnectConfig,
                          nwcWalletAuthCoordinator: nwcWalletAuthCoordinator,
                          nwcUriScanner: nwcUriScanner,
                        );
                      },
                    ),
                    // Faucet button (only in debug mode)
                    if (kDebugMode)
                      _WalletTypeOptionButton(
                        icon: Icons.water_drop,
                        label: l10n.faucetOption,
                        onTap: () async {
                          Navigator.of(dialogContext).pop(true);
                          await _showNwcFaucetDialog(
                            context,
                            ndkFlutter,
                            returnToNwcOptions: true,
                            albyGoConnectConfig: albyGoConnectConfig,
                            nwcWalletAuthCoordinator: nwcWalletAuthCoordinator,
                            nwcUriScanner: nwcUriScanner,
                          );
                        },
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ) ??
      false;
}

/// A styled button for wallet type options
class _WalletTypeOptionButton extends StatelessWidget {
  final IconData? icon;
  final String? imageAsset;
  final String label;
  final VoidCallback onTap;

  const _WalletTypeOptionButton({
    this.icon,
    this.imageAsset,
    required this.label,
    required this.onTap,
  }) : assert(
         icon != null || imageAsset != null,
         'Either icon or imageAsset must be provided',
       );

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: imageAsset != null
                ? Padding(
                    padding: const EdgeInsets.all(16),
                    child: Image.asset(
                      imageAsset!,
                      package: 'ndk_flutter',
                      fit: BoxFit.contain,
                    ),
                  )
                : Icon(
                    icon!,
                    size: 40,
                    color: Theme.of(context).colorScheme.primary,
                  ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

String? _extractNwcUriFromCallback(String receivedUrl) {
  const prefix = Nwc.kNWCProtocolPrefix;
  if (receivedUrl.startsWith(prefix)) {
    return receivedUrl;
  }

  final receivedUri = Uri.tryParse(receivedUrl);
  if (receivedUri == null) return null;

  final candidates = <String>{
    ...receivedUri.queryParameters.values,
    if (receivedUri.fragment.isNotEmpty) receivedUri.fragment,
  };

  for (final rawValue in candidates) {
    if (rawValue.startsWith(prefix)) {
      return rawValue;
    }
    try {
      final decoded = Uri.decodeComponent(rawValue);
      if (decoded.startsWith(prefix)) {
        return decoded;
      }
    } on FormatException {
      // Ignore malformed percent-encoding in callback values.
    }
  }
  return null;
}

bool _matchesReturnTo(String receivedUrl, String expectedReturnTo) {
  if (receivedUrl == expectedReturnTo ||
      receivedUrl.startsWith('$expectedReturnTo?')) {
    return true;
  }

  final receivedUri = Uri.tryParse(receivedUrl);
  final expectedUri = Uri.tryParse(expectedReturnTo);
  if (receivedUri == null || expectedUri == null) return false;

  return receivedUri.scheme == expectedUri.scheme &&
      receivedUri.host == expectedUri.host &&
      receivedUri.path == expectedUri.path;
}

/// Shows NWC URI input dialog and then adds the wallet directly.
Future<void> _showNwcUriInputAndAddWallet(
  BuildContext context,
  NdkFlutter ndkFlutter, {
  bool returnToNwcOptions = false,
  AlbyGoConnectConfig albyGoConnectConfig = kDefaultAlbyGoConnectConfig,
  NwcWalletAuthCoordinator? nwcWalletAuthCoordinator,
  NwcUriScanner? nwcUriScanner,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final result = await showDialog<String?>(
    context: context,
    builder: (context) => _NwcUriInputDialog(nwcUriScanner: nwcUriScanner),
  );

  if (result == _dialogBackResult) {
    if (returnToNwcOptions && context.mounted) {
      await showNwcConnectionOptionsDialog(
        context,
        ndkFlutter,
        albyGoConnectConfig: albyGoConnectConfig,
        nwcWalletAuthCoordinator: nwcWalletAuthCoordinator,
        nwcUriScanner: nwcUriScanner,
      );
    }
    return;
  }

  if (result == null || result.isEmpty || !context.mounted) return;

  final scaffoldMessenger = ScaffoldMessenger.of(context);

  try {
    final walletId = DateTime.now().millisecondsSinceEpoch.toString();
    final nwcWallet = NwcWallet(
      id: walletId,
      name: 'NWC',
      supportedUnits: {'sat'},
      nwcUrl: result,
    );
    await ndkFlutter.ndk.wallets.addWallet(nwcWallet);

    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Text(l10n.nwcWalletAdded),
        backgroundColor: Colors.green,
      ),
    );
  } catch (e) {
    scaffoldMessenger.showSnackBar(
      SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
    );
  }
}

class _NwcUriInputDialog extends StatefulWidget {
  final NwcUriScanner? nwcUriScanner;

  const _NwcUriInputDialog({required this.nwcUriScanner});

  @override
  State<_NwcUriInputDialog> createState() => _NwcUriInputDialogState();
}

class _NwcUriInputDialogState extends State<_NwcUriInputDialog> {
  final _nwcUriController = TextEditingController();
  String? _errorMessage;

  @override
  void dispose() {
    _nwcUriController.dispose();
    super.dispose();
  }

  void _submit(String value, {required bool fromScanner}) {
    final text = value.trim();
    final l10n = AppLocalizations.of(context)!;

    if (text.startsWith(Nwc.kNWCProtocolPrefix)) {
      Navigator.of(context).pop(text);
      return;
    }

    setState(() {
      _errorMessage = fromScanner ? l10n.invalidNwcQrCode : l10n.invalidNwcUri;
    });
  }

  Future<void> _pasteFromClipboard() async {
    final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
    final text = clipboardData?.text;

    if (!mounted) return;
    if (text == null) {
      _submit('', fromScanner: false);
      return;
    }

    _nwcUriController.text = text.trim();
    _submit(text, fromScanner: false);
  }

  Future<void> _scanNwcUri() async {
    final nwcUriScanner = widget.nwcUriScanner;
    if (nwcUriScanner == null) return;

    final scannedUri = await nwcUriScanner(context);
    if (!mounted || scannedUri == null) return;

    _nwcUriController.text = scannedUri.trim();
    _submit(scannedUri, fromScanner: true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(_dialogBackResult),
            icon: const Icon(Icons.arrow_back),
          ),
          Expanded(child: Text(l10n.nwcConnectionUri)),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nwcUriController,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: l10n.nwcConnectionUri,
                hintText: l10n.nwcConnectionUriHint,
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pasteFromClipboard,
                    icon: const Icon(Icons.paste),
                    label: Text(l10n.paste),
                  ),
                ),
                if (widget.nwcUriScanner != null) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _scanNwcUri,
                    icon: const Icon(Icons.qr_code_scanner),
                    tooltip: l10n.scanNwcQrCodeTitle,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        TextButton(
          onPressed: () => _submit(_nwcUriController.text, fromScanner: false),
          child: Text(l10n.add),
        ),
      ],
    );
  }
}

/// Shows a dialog to add an NWC wallet via faucet.
Future<void> _showNwcFaucetDialog(
  BuildContext context,
  NdkFlutter ndkFlutter, {
  bool returnToNwcOptions = false,
  AlbyGoConnectConfig albyGoConnectConfig = kDefaultAlbyGoConnectConfig,
  NwcWalletAuthCoordinator? nwcWalletAuthCoordinator,
  NwcUriScanner? nwcUriScanner,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final parentContext = context;
  final balanceController = TextEditingController(text: '10000');

  await showDialog(
    context: parentContext,
    builder: (dialogContext) {
      return AlertDialog(
        title: Row(
          children: [
            IconButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                if (returnToNwcOptions && parentContext.mounted) {
                  await showNwcConnectionOptionsDialog(
                    parentContext,
                    ndkFlutter,
                    albyGoConnectConfig: albyGoConnectConfig,
                    nwcWalletAuthCoordinator: nwcWalletAuthCoordinator,
                    nwcUriScanner: nwcUriScanner,
                  );
                }
              },
              icon: const Icon(Icons.arrow_back),
            ),
            Expanded(child: Text(l10n.faucetOption)),
            IconButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              icon: const Icon(Icons.close),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.nwcFaucetDescription),
            const SizedBox(height: 16),
            TextField(
              controller: balanceController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: l10n.startingBalance,
                hintText: l10n.startingBalanceHint,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () async {
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(context);

              try {
                final balance = int.tryParse(balanceController.text) ?? 10000;
                final response = await http.post(
                  Uri.parse('https://faucet.nwc.dev?balance=$balance'),
                );

                if (response.statusCode == 200) {
                  final nwcUri = response.body.trim();

                  if (nwcUri.isNotEmpty) {
                    final walletId = DateTime.now().millisecondsSinceEpoch
                        .toString();
                    final nwcWallet = NwcWallet(
                      id: walletId,
                      name: 'NWC Faucet',
                      supportedUnits: {'sat'},
                      nwcUrl: nwcUri,
                    );
                    await ndkFlutter.ndk.wallets.addWallet(nwcWallet);

                    if (context.mounted) {
                      navigator.pop();
                      scaffoldMessenger.showSnackBar(
                        SnackBar(
                          content: Text(l10n.nwcFaucetWalletAdded(balance)),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } else {
                    scaffoldMessenger.showSnackBar(
                      SnackBar(
                        content: Text(l10n.invalidFaucetResponse),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } else {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        'Failed to create wallet: ${response.statusCode}',
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } catch (e) {
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text('${l10n.errorCreatingWallet}: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Text(l10n.add),
          ),
        ],
      );
    },
  );
}
