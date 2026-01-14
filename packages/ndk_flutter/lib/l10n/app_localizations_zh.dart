// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get createAccount => '创建账户';

  @override
  String get newHere => '您是新用户吗？';

  @override
  String get nostrAddress => 'Nostr 地址';

  @override
  String get publicKey => '公钥';

  @override
  String get privateKey => '私钥（不安全）';

  @override
  String get browserExtension => '浏览器扩展';

  @override
  String get connect => '连接';

  @override
  String get install => '安装';

  @override
  String get logout => '退出登录';

  @override
  String get nostrAddressHint => 'name@example.com';

  @override
  String get invalidAddress => '无效地址';

  @override
  String get unableToConnect => '无法连接';

  @override
  String get publicKeyHint => 'npub1...';

  @override
  String get privateKeyHint => 'nsec1...';

  @override
  String get newToNostr => '初次使用 Nostr？';

  @override
  String get getStarted => '开始使用';

  @override
  String get bunker => 'Bunker';

  @override
  String get bunkerAuthentication => 'Bunker 身份验证';

  @override
  String tapToOpen(String url) {
    return '点击打开：$url';
  }

  @override
  String get showNostrConnectQrcode => '显示 nostr connect 二维码';

  @override
  String get loginWithAmber => '使用 Amber 登录';

  @override
  String get nostrConnectUrl => 'Nostr 连接 URL';

  @override
  String get copy => '复制';

  @override
  String get addAccount => '添加账户';

  @override
  String get readOnly => '只读';

  @override
  String get nsec => 'Nsec';

  @override
  String get extension => '扩展';
}
