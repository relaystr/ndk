// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get createAccount => 'Создать аккаунт';

  @override
  String get newHere => 'Вы здесь новенький?';

  @override
  String get nostrAddress => 'Адрес Nostr';

  @override
  String get publicKey => 'Публичный ключ';

  @override
  String get privateKey => 'Приватный ключ (небезопасно)';

  @override
  String get browserExtension => 'Расширение браузера';

  @override
  String get connect => 'Подключить';

  @override
  String get install => 'Установить';

  @override
  String get logout => 'Выйти';

  @override
  String get nostrAddressHint => 'имя@пример.com';

  @override
  String get invalidAddress => 'Неверный адрес';

  @override
  String get unableToConnect => 'Не удается подключиться';

  @override
  String get publicKeyHint => 'npub1...';

  @override
  String get privateKeyHint => 'nsec1...';

  @override
  String get newToNostr => 'Новичок в Nostr?';

  @override
  String get getStarted => 'Начать';

  @override
  String get bunker => 'Бункер';

  @override
  String get bunkerAuthentication => 'Аутентификация Bunker';

  @override
  String tapToOpen(String url) {
    return 'Нажмите, чтобы открыть: $url';
  }

  @override
  String get showNostrConnectQrcode => 'Показать QR-код nostr connect';

  @override
  String get loginWithAmber => 'Войти через Amber';

  @override
  String get nostrConnectUrl => 'URL подключения Nostr';

  @override
  String get copy => 'Копировать';

  @override
  String get addAccount => 'Добавить аккаунт';

  @override
  String get readOnly => 'Только чтение';

  @override
  String get nsec => 'Nsec';

  @override
  String get extension => 'Расширение';
}
