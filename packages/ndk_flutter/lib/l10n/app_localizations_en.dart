// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get createAccount => 'Create your account';

  @override
  String get newHere => 'Are you new here?';

  @override
  String get nostrAddress => 'Nostr Address';

  @override
  String get publicKey => 'Public Key';

  @override
  String get privateKey => 'Private Key (insecure)';

  @override
  String get browserExtension => 'Browser extension';

  @override
  String get connect => 'Connect';

  @override
  String get install => 'Install';

  @override
  String get logout => 'Logout';

  @override
  String get nostrAddressHint => 'name@example.com';

  @override
  String get invalidAddress => 'Invalid Address';

  @override
  String get unableToConnect => 'Unable to connect';

  @override
  String get publicKeyHint => 'npub1...';

  @override
  String get privateKeyHint => 'nsec1...';

  @override
  String get newToNostr => 'New to Nostr?';

  @override
  String get getStarted => 'Get Started';

  @override
  String get bunker => 'Bunker';

  @override
  String get bunkerAuthentication => 'Bunker Authentication';

  @override
  String tapToOpen(String url) {
    return 'Tap to open: $url';
  }

  @override
  String get showNostrConnectQrcode => 'Show nostr connect qrcode';

  @override
  String get loginWithAmber => 'Login with amber';

  @override
  String get nostrConnectUrl => 'Nostr connect URL';

  @override
  String get copy => 'Copy';

  @override
  String get addAccount => 'Add account';

  @override
  String get readOnly => 'Read-only';

  @override
  String get nsec => 'Nsec';

  @override
  String get extension => 'Extension';
}
