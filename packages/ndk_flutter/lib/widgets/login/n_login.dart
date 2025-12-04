import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/bip340.dart';
import 'package:ndk_flutter/ndk_flutter.dart';
import 'package:ndk_flutter/widgets/login/login_controller.dart';
import 'package:nip07_event_signer/nip07_event_signer.dart';
import 'package:nip19/nip19.dart';
import 'package:ndk_flutter/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

class NLogin extends StatefulWidget {
  final Ndk ndk;
  final void Function()? onLoggedIn;
  final bool enableAccountCreation;
  final bool enableNip05Login;
  final bool enableNpubLogin;
  final bool enableNsecLogin;
  final bool enableNip07Login;
  final bool enableBunkerLogin;
  final bool enableAmberLogin;
  final bool enablePubkeyLogin;
  final NostrConnect? nostrConnect;
  final String? nsecLabelText;
  final String getStartedUrl;

  bool get enableNostrConnectLogin => nostrConnect != null;

  const NLogin({
    super.key,
    required this.ndk,
    this.onLoggedIn,
    this.enableAccountCreation = true,
    this.enableNip05Login = true,
    this.enableNpubLogin = true,
    this.enableNsecLogin = true,
    this.enableNip07Login = true,
    this.enableBunkerLogin = true,
    this.enableAmberLogin = true,
    this.enablePubkeyLogin = true,
    this.nostrConnect,
    this.nsecLabelText,
    this.getStartedUrl = 'https://nstart.me/',
  });

  @override
  State<NLogin> createState() => _NLoginState();
}

class _NLoginState extends State<NLogin> {
  late LoginController controller;

  @override
  void initState() {
    super.initState();
    controller = LoginController(
      ndk: widget.ndk,
      onLoggedIn: widget.onLoggedIn,
      nostrConnect: widget.nostrConnect,
    );
    controller.addListener(_updateUI);
  }

  @override
  void dispose() {
    controller.removeListener(_updateUI);
    controller.dispose();
    super.dispose();
  }

  void _updateUI() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    const double bottomPadding = 16;

    final createAccountView = Padding(
      padding: EdgeInsetsGeometry.only(bottom: bottomPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AppLocalizations.of(context)!.newToNostr,
            style: Theme.of(context).textTheme.labelLarge,
          ),
          SizedBox(height: 8),
          FilledButton(
            onPressed: () async {
              await launchUrl(Uri.parse(widget.getStartedUrl));
            },
            child: Text(AppLocalizations.of(context)!.getStarted),
          ),
        ],
      ),
    );

    final nip05View = Padding(
      padding: EdgeInsetsGeometry.only(bottom: bottomPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AppLocalizations.of(context)!.nostrAddress,
            style: Theme.of(context).textTheme.labelLarge,
          ),
          TextField(
            controller: controller.nip05FieldController,
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context)!.nostrAddressHint,
              suffixIcon: !controller.isFetchingNip05
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: IconButton(
                        onPressed: () => loginWithNip05(
                          controller.nip05FieldController.text,
                        ),
                        icon: Icon(Icons.arrow_forward),
                      ),
                    )
                  : Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(),
                      ),
                    ),
              errorText: [
                null,
                AppLocalizations.of(context)!.invalidAddress,
                AppLocalizations.of(context)!.unableToConnect,
              ][controller.nip05LoginError],
            ),
            onChanged: nip05Change,
            onSubmitted: loginWithNip05,
          ),
        ],
      ),
    );

    final npubView = Padding(
      padding: EdgeInsetsGeometry.only(bottom: bottomPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AppLocalizations.of(context)!.publicKey,
            style: Theme.of(context).textTheme.labelLarge,
          ),
          TextField(
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context)!.publicKeyHint,
            ),
            onChanged: loginWithNpub,
          ),
        ],
      ),
    );

    final nsecView = Padding(
      padding: EdgeInsetsGeometry.only(bottom: bottomPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.nsecLabelText ?? AppLocalizations.of(context)!.privateKey,
            style: Theme.of(context).textTheme.labelLarge,
          ),
          TextField(
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context)!.privateKeyHint,
            ),
            onChanged: loginWithNsec,
          ),
        ],
      ),
    );

    final nip07View = Padding(
      padding: EdgeInsetsGeometry.only(bottom: bottomPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AppLocalizations.of(context)!.browserExtension,
            style: Theme.of(context).textTheme.labelLarge,
          ),
          SizedBox(height: 8),
          FilledButton.icon(
            onPressed: loginWithNip07,
            label: Text(
              Nip07EventSigner().canSign()
                  ? AppLocalizations.of(context)!.connect
                  : AppLocalizations.of(context)!.install,
            ),
            icon: Icon(Icons.extension_outlined),
          ),
        ],
      ),
    );

    final bunkerView = Padding(
      padding: EdgeInsetsGeometry.only(bottom: bottomPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AppLocalizations.of(context)!.bunker,
            style: Theme.of(context).textTheme.labelLarge,
          ),
          if (widget.enableBunkerLogin)
            TextField(
              controller: controller.bunkerFieldController,
              decoration: InputDecoration(hintText: "bunker://"),
              onChanged: (_) => setState(() {}),
            ),
          if (widget.enableBunkerLogin)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: FilledButton(
                onPressed:
                    controller.isValidBunkerUrl && !controller.isBunkerLoading
                    ? () => controller.loginWithBunkerUrl(context)
                    : null,
                child: Text(
                  controller.isBunkerLoading
                      ? "Loading..."
                      : "Login with bunker",
                ),
              ),
            ),
          if (widget.enableNostrConnectLogin)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: TextButton.icon(
                onPressed: () => controller.showNostrConnectQrcode(context),
                label: Text(
                  AppLocalizations.of(context)!.showNostrConnectQrcode,
                ),
                icon: Icon(Icons.qr_code_2),
              ),
            ),
        ],
      ),
    );

    final amberView = Padding(
      padding: EdgeInsetsGeometry.only(bottom: bottomPadding),
      child: FilledButton.icon(
        onPressed: controller.isWaitingForAmber
            ? null
            : controller.loginWithAmber,
        label: Text(AppLocalizations.of(context)!.loginWithAmber),
        icon: Icon(Icons.diamond),
      ),
    );

    final isAndroid = defaultTargetPlatform == TargetPlatform.android;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.enablePubkeyLogin && widget.enableNip05Login) nip05View,
        if (widget.enablePubkeyLogin && widget.enableNpubLogin) npubView,
        if (widget.enableNsecLogin) nsecView,
        if (widget.enableNip07Login && kIsWeb) nip07View,
        if (widget.enableBunkerLogin || widget.enableNostrConnectLogin)
          bunkerView,
        if (widget.enableAmberLogin && isAndroid) amberView,
        if (widget.enableAccountCreation) createAccountView,
      ],
    );
  }

  Future<void> loginWithNpub(String npub) async {
    String? pubkey;
    try {
      pubkey = Nip19.npubToHex(npub);
    } catch (e) {
      return;
    }

    if (widget.ndk.accounts.hasAccount(pubkey)) {
      widget.ndk.accounts.switchAccount(pubkey: pubkey);
    } else {
      widget.ndk.accounts.loginPublicKey(pubkey: pubkey);
    }

    await controller.loggedIn();
  }

  Future<void> loginWithNsec(String nsec) async {
    String? privateKey;
    String? pubkey;
    try {
      privateKey = Nip19.nsecToHex(nsec);
      pubkey = Bip340.getPublicKey(privateKey);
    } catch (e) {
      return;
    }

    if (widget.ndk.accounts.hasAccount(pubkey)) {
      widget.ndk.accounts.switchAccount(pubkey: pubkey);
    } else {
      widget.ndk.accounts.loginPrivateKey(pubkey: pubkey, privkey: privateKey);
    }

    await controller.loggedIn();
  }

  void nip05Change(String _) {
    controller.nip05LoginError = 0;
  }

  Future<void> loginWithNip05(String nip05) async {
    if (!RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    ).hasMatch(nip05)) {
      controller.nip05LoginError = 1;
      return;
    }

    controller.isFetchingNip05 = true;
    final nip05Result = await NdkFlutter.fetchNip05(nip05);
    controller.isFetchingNip05 = false;

    final pubkey = nip05Result.pubkey;
    if (pubkey == null) {
      controller.nip05LoginError = 2;
      return;
    }

    if (widget.ndk.accounts.hasAccount(pubkey)) {
      widget.ndk.accounts.switchAccount(pubkey: pubkey);
    } else {
      widget.ndk.accounts.loginPublicKey(pubkey: pubkey);
    }

    await controller.loggedIn();
  }

  Future<void> loginWithNip07() async {
    final signer = Nip07EventSigner();

    if (!signer.canSign()) {
      await launchUrl(
        Uri.parse(
          'https://chromewebstore.google.com/detail/nos2x/kpgefcfmnafjgpblomihpgmejjdanjjp',
        ),
      );
      return;
    }

    final pubkey = await signer.getPublicKeyAsync();

    if (widget.ndk.accounts.hasAccount(pubkey)) {
      widget.ndk.accounts.switchAccount(pubkey: pubkey);
    } else {
      widget.ndk.accounts.loginExternalSigner(signer: signer);
    }

    await controller.loggedIn();
  }
}
