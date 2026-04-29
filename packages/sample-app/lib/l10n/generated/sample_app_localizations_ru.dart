// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'sample_app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class SampleAppLocalizationsRu extends SampleAppLocalizations {
  SampleAppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appName => 'Демо Nostr Developer Kit';

  @override
  String get appBarTitle => 'Демо NDK';

  @override
  String get tabAccounts => 'Аккаунты';

  @override
  String get tabProfile => 'Профиль';

  @override
  String get tabRelays => 'Релеи';

  @override
  String get tabBlossom => 'Blossom';

  @override
  String get tabWallets => 'Кошельки';

  @override
  String get tabWidgets => 'Виджеты';

  @override
  String get profileTooltip => 'Профиль';

  @override
  String get loginDialogDefaultTitle => 'Войти';

  @override
  String get loginDialogAddAccountTitle => 'Добавить аккаунт';

  @override
  String get closeTooltip => 'Закрыть';

  @override
  String get accountsHeading => 'Аккаунты';

  @override
  String get accountsDescription =>
      'Управляйте подключенными аккаунтами и добавляйте новые.';

  @override
  String get addAnotherAccount => 'Добавить еще аккаунт';

  @override
  String get logIn => 'Войти';

  @override
  String get profileNoAccount => 'Нет вошедшего аккаунта.';

  @override
  String get profileAbout => 'О профиле';

  @override
  String profileMetadataError(Object error) {
    return 'Ошибка получения метаданных: $error';
  }

  @override
  String get relaysLoginRequired =>
      'Войдите, чтобы увидеть список ваших релеев.';

  @override
  String get relaysFetchButton => 'Получить список релеев';

  @override
  String get relayListHeading => 'Список релеев';

  @override
  String relayConfiguredCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count настроенных релеев',
      many: '$count настроенных релеев',
      few: '$count настроенных релея',
      one: '$count настроенный релей',
    );
    return '$_temp0';
  }

  @override
  String relayConnection(Object state) {
    return 'Подключение: $state';
  }

  @override
  String get relayRead => 'Чтение';

  @override
  String get relayWrite => 'Запись';

  @override
  String get relayStateConnecting => 'Подключение';

  @override
  String get relayStateOnline => 'В сети';

  @override
  String get relayStateOffline => 'Не в сети';

  @override
  String get relayStateUnknown => 'Неизвестно';

  @override
  String get widgetsPageTitle => 'Демо виджетов NDK Flutter';

  @override
  String get widgetsLoginHint =>
      'Войдите через вкладку Аккаунты, чтобы увидеть персонализированные виджеты.';

  @override
  String get widgetsCurrentUser => 'Текущий пользователь: ';

  @override
  String get widgetsSizeDefault => 'По умолчанию';

  @override
  String get widgetsSizeLarger => 'Больше';

  @override
  String get widgetsSizeLarge => 'Большой';

  @override
  String get widgetsShowLoginWidget => 'Показать виджет NLogin';

  @override
  String get widgetsLoginWidgetTitle => 'Виджет NLogin';

  @override
  String widgetsRequiresLogin(Object widgetName) {
    return '$widgetName\\n(требуется вход)';
  }

  @override
  String get widgetsSectionNNameDescription =>
      'Показывает имя пользователя из метаданных, а при отсутствии использует форматированный npub.';

  @override
  String get widgetsSectionNPictureDescription =>
      'Показывает фото профиля пользователя, а при отсутствии использует инициалы.';

  @override
  String get widgetsSectionNBannerDescription =>
      'Показывает баннер пользователя, а при отсутствии использует цветной контейнер.';

  @override
  String get widgetsSectionNUserProfileDescription =>
      'Полный профиль пользователя с баннером, фото, именем и NIP-05.';

  @override
  String get widgetsSectionNSwitchAccountDescription =>
      'Виджет управления аккаунтами с переключением и выходом.';

  @override
  String get widgetsSectionNLoginDescription =>
      'Виджет входа с несколькими способами аутентификации (NIP-05, npub, nsec, bunker и т. д.).';

  @override
  String get widgetsSectionGetColorDescription =>
      'Статический метод, который генерирует детерминированные цвета из pubkey.';

  @override
  String get blossomPageTitle => 'Операции с медиа и файлами Blossom';

  @override
  String get blossomImageDemoTitle => 'Демо изображения (getBlob)';

  @override
  String get blossomVideoDemoTitle => 'Демо видео (checkBlob)';

  @override
  String get blossomNoImageYet => 'Изображение еще не загружено';

  @override
  String get blossomDownloadImage => 'Скачать изображение';

  @override
  String get blossomClearImage => 'Очистить изображение';

  @override
  String blossomMimeType(Object value) {
    return 'MIME-тип: $value';
  }

  @override
  String blossomFileSizeBytes(Object value) {
    return 'Размер: $value байт';
  }

  @override
  String get blossomNoVideoYet => 'Видео еще не загружено';

  @override
  String get blossomLoadVideo => 'Загрузить видео';

  @override
  String get blossomClearVideo => 'Очистить видео';

  @override
  String blossomVideoUrl(Object value) {
    return 'URL видео: $value';
  }

  @override
  String get blossomUploadTitle => 'Загрузить файл с диска';

  @override
  String get blossomUploadDescription =>
      'Показывает uploadFromFile() с потоковым прогрессом.';

  @override
  String blossomUploadingProgress(Object progress) {
    return 'Загрузка: $progress%';
  }

  @override
  String get blossomUploadSuccess => 'Загрузка завершена';

  @override
  String blossomSha256(Object value) {
    return 'SHA256: $value';
  }

  @override
  String blossomUrl(Object value) {
    return 'URL: $value';
  }

  @override
  String get blossomNoUploadedFileYet => 'Файл еще не загружен';

  @override
  String get blossomPickAndUploadFile => 'Выбрать и загрузить файл';

  @override
  String get clear => 'Очистить';

  @override
  String get blossomDownloadTitle => 'Скачать файл на диск';

  @override
  String get blossomDownloadDescription =>
      'Показывает downloadToFile() и сохраняет файл напрямую на диск.';

  @override
  String get blossomNoDownloadedFileYet => 'Файл еще не скачан';

  @override
  String get blossomDownloadUploadedFile => 'Скачать загруженный файл';

  @override
  String blossomSavedTo(Object value) {
    return 'Сохранено в: $value';
  }

  @override
  String get blossomUploadFirstToEnableDownload =>
      'Сначала загрузите файл, чтобы включить скачивание.';

  @override
  String get blossomNoUploadedFileToDownload =>
      'Пока нет загруженного файла для скачивания.';

  @override
  String get blossomDownloadedToBrowser => 'Скачано в браузер';

  @override
  String get downloadSuccess => 'Скачивание завершено';

  @override
  String errorLabel(Object error) {
    return 'Ошибка: $error';
  }

  @override
  String get pendingRequestsLoginRequired =>
      'Войдите, чтобы увидеть ожидающие запросы.';

  @override
  String get pendingNoRequests => 'Нет ожидающих запросов';

  @override
  String get pendingUseButtons =>
      'Используйте кнопки выше, чтобы создать запросы.';

  @override
  String get pendingRequestCancelled => 'Запрос отменен';

  @override
  String get pendingRequestCancelFailed => 'Не удалось отменить запрос';

  @override
  String get pendingHeading => 'Ожидающие запросы подписанта';

  @override
  String get pendingDescription =>
      'Запросы, ожидающие подтверждения от вашего подписанта.';

  @override
  String get pendingTriggerRequests => 'Создать запросы';

  @override
  String get signEvent => 'Подписать событие';

  @override
  String get encrypt => 'Зашифровать';

  @override
  String get decrypt => 'Расшифровать';

  @override
  String pendingSignedResult(Object value) {
    return 'Подписано. ID: $value';
  }

  @override
  String pendingSignFailed(Object error) {
    return 'Не удалось подписать: $error';
  }

  @override
  String get pendingEncryptFirst =>
      'Сначала зашифруйте, чтобы получить шифртекст.';

  @override
  String pendingEncryptedResult(Object value) {
    return 'Зашифровано: $value';
  }

  @override
  String pendingEncryptFailed(Object error) {
    return 'Не удалось зашифровать: $error';
  }

  @override
  String pendingDecryptedResult(Object value) {
    return 'Расшифровано: $value';
  }

  @override
  String pendingDecryptFailed(Object error) {
    return 'Не удалось расшифровать: $error';
  }

  @override
  String get pendingMethodSignEvent => 'Подписать событие';

  @override
  String get pendingMethodGetPublicKey => 'Получить публичный ключ';

  @override
  String get pendingMethodNip04Encrypt => 'Зашифровать NIP-04';

  @override
  String get pendingMethodNip04Decrypt => 'Расшифровать NIP-04';

  @override
  String get pendingMethodNip44Encrypt => 'Зашифровать NIP-44';

  @override
  String get pendingMethodNip44Decrypt => 'Расшифровать NIP-44';

  @override
  String get pendingMethodPing => 'Ping';

  @override
  String get pendingMethodConnect => 'Подключить';

  @override
  String pendingSecondsAgo(int count) {
    return '$countс назад';
  }

  @override
  String pendingMinutesAgo(int count) {
    return '$countм назад';
  }

  @override
  String pendingHoursAgo(int count) {
    return '$countч назад';
  }

  @override
  String pendingEventKind(Object value) {
    return 'Тип события: $value';
  }

  @override
  String pendingContent(Object value) {
    return 'Содержимое: $value';
  }

  @override
  String pendingCounterparty(Object value) {
    return 'Контрагент: $value...';
  }

  @override
  String pendingPlaintext(Object value) {
    return 'Открытый текст: $value';
  }

  @override
  String pendingCiphertext(Object value) {
    return 'Шифртекст: $value...';
  }

  @override
  String pendingId(Object value) {
    return 'ID: $value';
  }

  @override
  String get cancel => 'Отмена';
}
