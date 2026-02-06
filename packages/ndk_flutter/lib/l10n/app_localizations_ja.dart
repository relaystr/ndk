// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get createAccount => 'アカウントを作成';

  @override
  String get newHere => '初めてですか？';

  @override
  String get nostrAddress => 'Nostrアドレス';

  @override
  String get publicKey => '公開鍵';

  @override
  String get privateKey => '秘密鍵（安全ではありません）';

  @override
  String get browserExtension => 'ブラウザ拡張機能';

  @override
  String get connect => '接続';

  @override
  String get install => 'インストール';

  @override
  String get logout => 'ログアウト';

  @override
  String get nostrAddressHint => 'name@example.com';

  @override
  String get invalidAddress => '無効なアドレス';

  @override
  String get unableToConnect => '接続できません';

  @override
  String get publicKeyHint => 'npub1...';

  @override
  String get privateKeyHint => 'nsec1...';

  @override
  String get newToNostr => 'Nostrは初めてですか？';

  @override
  String get getStarted => '始める';

  @override
  String get bunker => 'バンカー';

  @override
  String get bunkerAuthentication => 'バンカー認証';

  @override
  String tapToOpen(String url) {
    return 'タップして開く：$url';
  }

  @override
  String get showNostrConnectQrcode => 'nostr connect QRコードを表示';

  @override
  String get loginWithAmber => 'Amberでログイン';

  @override
  String get nostrConnectUrl => 'Nostr接続URL';

  @override
  String get copy => 'コピー';

  @override
  String get addAccount => 'アカウントを追加';

  @override
  String get readOnly => '読み取り専用';

  @override
  String get nsec => 'Nsec';

  @override
  String get extension => '拡張機能';
}
