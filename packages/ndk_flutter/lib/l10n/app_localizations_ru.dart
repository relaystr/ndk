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

  @override
  String get userMetadata => 'Метаданные пользователя';

  @override
  String get shortTextNote => 'Короткая заметка';

  @override
  String get recommendRelay => 'Рекомендовать реле';

  @override
  String get follows => 'Подписки';

  @override
  String get encryptedDirectMessages => 'Зашифрованные сообщения';

  @override
  String get eventDeletionRequest => 'Запрос на удаление';

  @override
  String get repost => 'Репост';

  @override
  String get reaction => 'Реакция';

  @override
  String get badgeAward => 'Награда значком';

  @override
  String get chatMessage => 'Сообщение чата';

  @override
  String get groupChatThreadedReply => 'Ответ в треде группы';

  @override
  String get thread => 'Тред';

  @override
  String get groupThreadReply => 'Ответ в треде группы';

  @override
  String get seal => 'Печать';

  @override
  String get directMessage => 'Личное сообщение';

  @override
  String get fileMessage => 'Файловое сообщение';

  @override
  String get genericRepost => 'Общий репост';

  @override
  String get reactionToWebsite => 'Реакция на сайт';

  @override
  String get picture => 'Изображение';

  @override
  String get videoEvent => 'Видео событие';

  @override
  String get shortFormPortraitVideoEvent => 'Короткое вертикальное видео';

  @override
  String get internalReference => 'Внутренняя ссылка';

  @override
  String get externalReference => 'Внешняя ссылка';

  @override
  String get hardcopyReference => 'Печатная ссылка';

  @override
  String get promptReference => 'Ссылка на промпт';

  @override
  String get channelCreation => 'Создание канала';

  @override
  String get channelMetadata => 'Метаданные канала';

  @override
  String get channelMessage => 'Сообщение канала';

  @override
  String get channelHideMessage => 'Скрыть сообщение канала';

  @override
  String get channelMuteUser => 'Заглушить пользователя';

  @override
  String get requestToVanish => 'Запрос на удаление';

  @override
  String get chessPgn => 'Шахматы (PGN)';

  @override
  String get mlsKeyPackage => 'MLS пакет ключей';

  @override
  String get mlsWelcome => 'MLS приветствие';

  @override
  String get mlsGroupEvent => 'MLS групповое событие';

  @override
  String get mergeRequests => 'Запросы на слияние';

  @override
  String get pollResponse => 'Ответ на опрос';

  @override
  String get marketplaceBid => 'Ставка на маркетплейсе';

  @override
  String get marketplaceBidConfirmation => 'Подтверждение ставки';

  @override
  String get openTimestamps => 'OpenTimestamps';

  @override
  String get giftWrap => 'Подарочная упаковка';

  @override
  String get fileMetadata => 'Метаданные файла';

  @override
  String get poll => 'Опрос';

  @override
  String get comment => 'Комментарий';

  @override
  String get voiceMessage => 'Голосовое сообщение';

  @override
  String get voiceMessageComment => 'Комментарий голосом';

  @override
  String get liveChatMessage => 'Сообщение живого чата';

  @override
  String get codeSnippet => 'Фрагмент кода';

  @override
  String get gitPatch => 'Git патч';

  @override
  String get gitPullRequest => 'Git Pull Request';

  @override
  String get gitStatusUpdate => 'Обновление статуса Git';

  @override
  String get gitIssue => 'Git Issue';

  @override
  String get gitIssueUpdate => 'Обновление Git Issue';

  @override
  String get status => 'Статус';

  @override
  String get statusUpdate => 'Обновление статуса';

  @override
  String get statusDelete => 'Удаление статуса';

  @override
  String get statusReply => 'Ответ на статус';

  @override
  String get problemTracker => 'Трекер проблем';

  @override
  String get reporting => 'Жалоба';

  @override
  String get label => 'Метка';

  @override
  String get relayReviews => 'Отзывы о реле';

  @override
  String get aiEmbeddings => 'AI эмбеддинги / Векторные списки';

  @override
  String get torrent => 'Торрент';

  @override
  String get torrentComment => 'Комментарий торрента';

  @override
  String get coinjoinPool => 'Coinjoin пул';

  @override
  String get communityPostApproval => 'Одобрение поста сообщества';

  @override
  String get jobRequest => 'Запрос задания';

  @override
  String get jobResult => 'Результат задания';

  @override
  String get jobFeedback => 'Отзыв о задании';

  @override
  String get cashuWalletToken => 'Токен кошелька Cashu';

  @override
  String get cashuWalletProofs => 'Доказательства Cashu';

  @override
  String get cashuWalletHistory => 'История кошелька Cashu';

  @override
  String get geocacheCreate => 'Создание геокеша';

  @override
  String get geocacheUpdate => 'Обновление геокеша';

  @override
  String get groupControlEvent => 'Событие управления группой';

  @override
  String get zapGoal => 'Цель Zap';

  @override
  String get nutzap => 'Nutzap';

  @override
  String get tidalLogin => 'Вход в Tidal';

  @override
  String get zapRequest => 'Запрос Zap';

  @override
  String get zap => 'Zap';

  @override
  String get highlights => 'Выделения';

  @override
  String get muteList => 'Список заглушённых';

  @override
  String get pinList => 'Закреплённый список';

  @override
  String get relayListMetadata => 'Метаданные списка реле';

  @override
  String get bookmarkList => 'Список закладок';

  @override
  String get communitiesList => 'Список сообществ';

  @override
  String get publicChatsList => 'Список публичных чатов';

  @override
  String get blockedRelaysList => 'Список заблокированных реле';

  @override
  String get searchRelaysList => 'Список поисковых реле';

  @override
  String get userGroups => 'Группы пользователя';

  @override
  String get favoritesList => 'Список избранного';

  @override
  String get privateEventsList => 'Список приватных событий';

  @override
  String get interestsList => 'Список интересов';

  @override
  String get mediaFollowsList => 'Список подписок на медиа';

  @override
  String get peopleFollowsList => 'Список подписок на людей';

  @override
  String get userEmojiList => 'Список эмодзи пользователя';

  @override
  String get dmRelayList => 'Список DM реле';

  @override
  String get keyPackageRelayList => 'Список реле KeyPackage';

  @override
  String get userServerList => 'Список серверов пользователя';

  @override
  String get fileStorageServerList => 'Список серверов хранения';

  @override
  String get relayMonitorAnnouncement => 'Объявление монитора реле';

  @override
  String get roomPresence => 'Присутствие в комнате';

  @override
  String get proxyAnnouncement => 'Объявление прокси';

  @override
  String get transportMethodAnnouncement => 'Объявление транспорта';

  @override
  String get walletInfo => 'Информация о кошельке';

  @override
  String get cashuWalletEvent => 'Событие кошелька Cashu';

  @override
  String get lightningPubRpc => 'Lightning Pub RPC';

  @override
  String get clientAuthentication => 'Аутентификация клиента';

  @override
  String get walletRequest => 'Запрос кошелька';

  @override
  String get walletResponse => 'Ответ кошелька';

  @override
  String get nostrConnectEvent => 'Nostr Connect';

  @override
  String get blobsStoredOnMediaservers => 'Blob на медиасерверах';

  @override
  String get httpAuth => 'HTTP аутентификация';

  @override
  String get categorizedPeopleList => 'Категоризованный список людей';

  @override
  String get categorizedBookmarkList => 'Категоризованные закладки';

  @override
  String get categorizedRelayList => 'Категоризованный список реле';

  @override
  String get bookmarkSets => 'Наборы закладок';

  @override
  String get curationSets => 'Наборы кураций';

  @override
  String get videoSets => 'Наборы видео';

  @override
  String get kindMuteSets => 'Наборы заглушённых типов';

  @override
  String get profileBadges => 'Значки профиля';

  @override
  String get badgeDefinition => 'Определение значка';

  @override
  String get interestSets => 'Наборы интересов';

  @override
  String get createOrUpdateStall => 'Создать/обновить стенд';

  @override
  String get createOrUpdateProduct => 'Создать/обновить товар';

  @override
  String get marketplaceUiUx => 'Интерфейс маркетплейса';

  @override
  String get productSoldAsAuction => 'Товар на аукционе';

  @override
  String get longFormContent => 'Длинный контент';

  @override
  String get draftLongFormContent => 'Черновик длинного контента';

  @override
  String get emojiSets => 'Наборы эмодзи';

  @override
  String get curatedPublicationItem => 'Курированная публикация';

  @override
  String get curatedPublicationDraft => 'Черновик публикации';

  @override
  String get releaseArtifactSets => 'Наборы артефактов релиза';

  @override
  String get applicationSpecificData => 'Данные приложения';

  @override
  String get relayDiscovery => 'Обнаружение реле';

  @override
  String get appCurationSets => 'Наборы кураций приложений';

  @override
  String get liveEvent => 'Прямой эфир';

  @override
  String get userStatus => 'Статус пользователя';

  @override
  String get slideSet => 'Набор слайдов';

  @override
  String get classifiedListing => 'Объявление';

  @override
  String get draftClassifiedListing => 'Черновик объявления';

  @override
  String get repositoryAnnouncement => 'Объявление репозитория';

  @override
  String get repositoryStateAnnouncement => 'Состояние репозитория';

  @override
  String get wikiArticle => 'Wiki статья';

  @override
  String get redirects => 'Перенаправления';

  @override
  String get draftEvent => 'Черновик события';

  @override
  String get linkSet => 'Набор ссылок';

  @override
  String get feed => 'Лента';

  @override
  String get dateBasedCalendarEvent => 'Событие по дате';

  @override
  String get timeBasedCalendarEvent => 'Событие по времени';

  @override
  String get calendar => 'Календарь';

  @override
  String get calendarEventRsvp => 'RSVP события';

  @override
  String get handlerRecommendation => 'Рекомендация обработчика';

  @override
  String get handlerInformation => 'Информация обработчика';

  @override
  String get softwareApplication => 'Программное приложение';

  @override
  String get videoView => 'Просмотр видео';

  @override
  String get communityDefinition => 'Определение сообщества';

  @override
  String get geocacheListing => 'Список геокешей';

  @override
  String get mintAnnouncement => 'Объявление минта';

  @override
  String get mintQuote => 'Котировка минта';

  @override
  String get peerToPeerOrder => 'P2P заказ';

  @override
  String get groupMetadata => 'Метаданные группы';

  @override
  String get groupAdminMetadata => 'Метаданные админа группы';

  @override
  String get groupMemberMetadata => 'Метаданные участника';

  @override
  String get groupAdminsList => 'Список админов группы';

  @override
  String get groupMembersList => 'Список участников группы';

  @override
  String get groupRoles => 'Роли группы';

  @override
  String get groupPermissions => 'Разрешения группы';

  @override
  String get groupChatMessage => 'Сообщение группового чата';

  @override
  String get groupChatThread => 'Тред группового чата';

  @override
  String get groupPinned => 'Закреплённое в группе';

  @override
  String get starterPacks => 'Стартовые паки';

  @override
  String get mediaStarterPacks => 'Медиа стартовые паки';

  @override
  String get webBookmarks => 'Веб-закладки';

  @override
  String unknownEventKind(int kind) {
    return 'Тип события $kind';
  }
}
