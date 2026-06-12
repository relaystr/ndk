import 'package:flutter/material.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk_flutter/ndk_flutter.dart';
import 'package:ndk_flutter/widgets/login/nostr_connect_dialog_view.dart';
import 'package:ndk_flutter/l10n/app_localizations.dart';
import 'package:toastification/toastification.dart';
import 'package:url_launcher/url_launcher.dart';

class LoginController extends ChangeNotifier {
  NdkFlutter ndkFlutter;
  void Function()? onLoggedIn;

  Ndk get ndk => ndkFlutter.ndk;

  final nip05FieldController = TextEditingController();
  bool _isFetchingNip05 = false;
  bool get isFetchingNip05 => _isFetchingNip05;
  set isFetchingNip05(bool value) {
    _isFetchingNip05 = value;
    notifyListeners();
  }

  int _nip05LoginError = 0;
  int get nip05LoginError => _nip05LoginError;
  set nip05LoginError(int value) {
    _nip05LoginError = value;
    notifyListeners();
  }

  final bunkerFieldController = TextEditingController();
  bool _isBunkerLoading = false;
  bool get isBunkerLoading => _isBunkerLoading;
  set isBunkerLoading(bool value) {
    _isBunkerLoading = value;
    notifyListeners();
  }

  NostrConnect? nostrConnect;
  bool isNostrConnectDialogOpen = false;
  List<ToastificationItem> challengeToasts = [];

  bool _isWaitingForExternalSigner = false;
  bool get isWaitingForExternalSigner => _isWaitingForExternalSigner;
  set isWaitingForExternalSigner(bool value) {
    _isWaitingForExternalSigner = value;
    notifyListeners();
  }

  bool get isValidBunkerUrl {
    final bunkerText = bunkerFieldController.text.trim();

    try {
      final uri = Uri.parse(bunkerText);

      // Check if scheme is bunker
      if (uri.scheme != 'bunker') return false;

      // Check if host (pubkey) is valid hex (64 characters)
      if (uri.host.length != 64) return false;
      if (!RegExp(r'^[a-fA-F0-9]+$').hasMatch(uri.host)) return false;

      // Check if at least one relay parameter exists
      if (!uri.queryParameters.containsKey('relay')) return false;

      return true;
    } catch (e) {
      return false;
    }
  }

  LoginController({
    required this.ndkFlutter,
    this.onLoggedIn,
    this.nostrConnect,
  });

  Future<void> loginWithBunkerUrl(BuildContext context) async {
    isBunkerLoading = true;

    try {
      final bunkerConnection = await ndk.accounts.loginWithBunkerUrl(
        bunkerUrl: bunkerFieldController.text.trim(),
        bunkers: ndk.bunkers,
        authCallback: (challenge) => showBunkerAuthToast(challenge, context),
      );

      isBunkerLoading = false;

      if (bunkerConnection == null) return;

      await loggedIn();
    } catch (e) {
      //
    }
  }

  Future<void> loginWithExternalSigner() async {
    isWaitingForExternalSigner = true;
    try {
      const signer = Nip55Signer();

      final isInstalled = await signer.isAppInstalled();

      if (!isInstalled) {
        isWaitingForExternalSigner = false;
        launchUrl(Uri.parse('https://github.com/greenart7c3/Amber'));
        return;
      }

      final loginResult = await signer.login();
      if (loginResult == null) {
        isWaitingForExternalSigner = false;
        return;
      }

      final externalSigner = Nip55EventSigner(
        publicKey: loginResult.pubkey,
        // pin the signer captured at login so later requests can be silent
        nip55Signer: Nip55Signer(package: loginResult.package),
      );

      ndk.accounts.loginExternalSigner(signer: externalSigner);

      isWaitingForExternalSigner = false;

      await loggedIn();
    } finally {
      isWaitingForExternalSigner = false;
    }
  }

  Future<void> loggedIn() async {
    await ndkFlutter.saveAccountsState();

    for (var toast in challengeToasts) {
      toastification.dismiss(toast);
    }
    challengeToasts.clear();

    if (onLoggedIn != null) onLoggedIn!();
  }

  void showNostrConnectQrcode(BuildContext context) async {
    if (nostrConnect == null) return;

    openNostrConnectDialog(context);

    try {
      final bunkerSettings = await ndk.accounts.loginWithNostrConnect(
        nostrConnect: nostrConnect!,
        bunkers: ndk.bunkers,
        // authCallback: (challenge) => showBunkerAuthToast(challenge),
      );

      if (isNostrConnectDialogOpen) {
        Navigator.of(context).pop();
        isNostrConnectDialogOpen = false;
      }

      if (bunkerSettings == null) return;

      await loggedIn();
    } catch (e) {
      if (isNostrConnectDialogOpen) {
        Navigator.of(context).pop();
        isNostrConnectDialogOpen = false;
      }
    }
  }

  void openNostrConnectDialog(BuildContext context) async {
    if (nostrConnect == null) return;

    isNostrConnectDialogOpen = true;
    await showDialog(
      context: context,
      builder: (_) => NostrConnectDialogView(
        nostrConnectURL: nostrConnect!.nostrConnectURL,
      ),
    );
    isNostrConnectDialogOpen = false;
  }

  void showBunkerAuthToast(String challenge, BuildContext context) {
    final newToast = toastification.show(
      context: context,
      title: Text(AppLocalizations.of(context)!.bunkerAuthentication),
      description: Text(AppLocalizations.of(context)!.tapToOpen(challenge)),
      alignment: Alignment.bottomRight,
      type: ToastificationType.info,
      style: ToastificationStyle.flat,
      showProgressBar: true,
      closeOnClick: false,
      callbacks: ToastificationCallbacks(
        onTap: (toastItem) => launchUrl(Uri.parse(challenge)),
      ),
    );

    challengeToasts.add(newToast);
  }
}
