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

  @override
  String get walletsTitle => 'Кошельки';

  @override
  String get recentActivityTitle => 'Недавняя Активность';

  @override
  String get addCashuWallet => 'Добавить Кошелёк Cashu';

  @override
  String get addNwcWallet => 'Добавить Кошелёк NWC';

  @override
  String get addLnurlWallet => 'Добавить Кошелёк LNURL';

  @override
  String get addCashuTooltip => 'Добавить Кошелёк Cashu';

  @override
  String get addNwcTooltip => 'Добавить Кошелёк NWC';

  @override
  String get addLnurlTooltip => 'Добавить Кошелёк LNURL';

  @override
  String get addCashuWalletTitle => 'Добавить Кошелёк Cashu';

  @override
  String get enterMintUrl => 'Введите URL минта для добавления кошелька Cashu.';

  @override
  String get mintUrl => 'URL Минта';

  @override
  String get mintUrlHint => 'https://mint.example.com';

  @override
  String get pleaseEnterMintUrl => 'Пожалуйста, введите URL минта';

  @override
  String get cashuWalletAdded => 'Кошелёк Cashu успешно добавлен!';

  @override
  String get failedToAddMint => 'Не удалось добавить минт. Пожалуйста, проверьте URL и попробуйте снова.';

  @override
  String get addNwcWalletTitle => 'Добавить Кошелёк NWC';

  @override
  String get faucet => 'Кран';

  @override
  String get manual => 'Вручную';

  @override
  String get nwcFaucetDescription => 'Создайте тестовый кошелёк с сатами из крана NWC.';

  @override
  String get startingBalance => 'Начальный Баланс';

  @override
  String get startingBalanceHint => '10000';

  @override
  String get nwcConnectionUri => 'URI Подключения NWC';

  @override
  String get nwcConnectionUriHint => 'nostr+walletconnect://...';

  @override
  String get nwcWalletAdded => 'Кошелёк NWC успешно добавлен!';

  @override
  String nwcFaucetWalletAdded(int balance) {
    return 'Кошелёк крана NWC добавлен с $balance сатами!';
  }

  @override
  String get invalidFaucetResponse => 'Неверный ответ от крана';

  @override
  String get errorCreatingWallet => 'Ошибка создания кошелька';

  @override
  String get addLnurlWalletTitle => 'Добавить Кошелёк LNURL';

  @override
  String get enterLnurlIdentifier => 'Введите ваш LNURL идентификатор (user@domain.com).';

  @override
  String get lnurlIdentifierHint => 'user@example.com';

  @override
  String get pleaseEnterValidIdentifier => 'Пожалуйста, введите действительный идентификатор (user@domain.com)';

  @override
  String get lnurlWalletAdded => 'Кошелёк LNURL успешно добавлен!';

  @override
  String get cancel => 'Отмена';

  @override
  String get add => 'Добавить';

  @override
  String get send => 'Отправить';

  @override
  String get receive => 'Получить';

  @override
  String get setAsDefaultForReceiving => 'Сделать по умолчанию для получения';

  @override
  String get setAsDefaultForSending => 'Сделать по умолчанию для отправки';

  @override
  String get defaultForReceiving => 'По умолчанию для получения';

  @override
  String get defaultForSending => 'По умолчанию для отправки';

  @override
  String get defaultWalletForReceivingTooltip => 'Этот кошелёк используется по умолчанию для получения платежей.';

  @override
  String get defaultWalletForSendingTooltip => 'Этот кошелёк используется по умолчанию для отправки платежей.';

  @override
  String get sendOptionsTitle => 'Опции Отправки';

  @override
  String get sendByToken => 'Отправить Токеном';

  @override
  String get sendByTokenDescription => 'Создать токен Cashu для отправки';

  @override
  String get sendByLightning => 'Отправить через Lightning';

  @override
  String get sendByLightningDescription => 'Оплатить Lightning-счёт';

  @override
  String get payInvoiceTitle => 'Оплатить Счёт';

  @override
  String get invoice => 'Счёт';

  @override
  String get invoiceHint => 'lnbc...';

  @override
  String get pleaseEnterInvoice => 'Пожалуйста, введите счёт';

  @override
  String get invoicePaid => 'Счёт оплачен!';

  @override
  String paymentFailed(String message) {
    return 'Оплата не удалась: $message';
  }

  @override
  String get receiveOptionsTitle => 'Опции Получения';

  @override
  String get receiveByToken => 'Получить Токеном';

  @override
  String get receiveByTokenDescription => 'Получить токен Cashu';

  @override
  String get receiveByLightning => 'Получить через Lightning';

  @override
  String get receiveByLightningDescription => 'Создать Lightning-счёт';

  @override
  String get receiveByTokenTitle => 'Получить Токеном';

  @override
  String get token => 'Токен';

  @override
  String get tokenHint => 'Вставьте токен здесь...';

  @override
  String get pleaseEnterToken => 'Пожалуйста, введите токен';

  @override
  String get tokenReceived => 'Токен получен!';

  @override
  String get createInvoiceTitle => 'Создать Счёт';

  @override
  String get amount => 'Сумма';

  @override
  String get amountHint => '100';

  @override
  String get pleaseEnterValidAmount => 'Пожалуйста, введите действительную сумму';

  @override
  String get tokenCopiedToClipboard => 'Токен скопирован в буфер обмена!';

  @override
  String get invoiceCreatedAndCopied => 'Счёт создан и скопирован!';

  @override
  String get invoiceTrackingTitle => 'Lightning Счёт';

  @override
  String get invoiceCreatedMessage => 'Счёт создан и скопирован!';

  @override
  String get close => 'Закрыть';

  @override
  String get copyAgain => 'Копировать Снова';

  @override
  String get copied => 'Скопировано!';

  @override
  String get paymentReceived => 'Платёж получен!';

  @override
  String get waitingForPayment => 'Ожидание платежа...';

  @override
  String get paid => 'Оплачено!';

  @override
  String get createToken => 'Создать Токен';

  @override
  String get pay => 'Оплатить';

  @override
  String get create => 'Создать';

  @override
  String get pendingTransactions => 'В Ожидании';

  @override
  String get recentTransactions => 'Недавние Транзакции';

  @override
  String get noRecentTransactions => 'Нет недавних транзакций';

  @override
  String get noWalletsYet => 'Пока нет кошельков';

  @override
  String get noWalletsAvailable => 'Нет доступных кошельков';

  @override
  String get tapToAddWallet => 'Нажмите + чтобы добавить';

  @override
  String get delete => 'Удалить';

  @override
  String error(String message) {
    return 'Ошибка: $message';
  }

  @override
  String get unknownWalletType => 'Неизвестно';

  @override
  String get cashuWallet => 'Cashu';

  @override
  String get nwcWallet => 'NWC';

  @override
  String get lnurlWallet => 'LNURL';

  @override
  String get nwcWalletSubtitle => 'Кошелёк NWC';

  @override
  String get balance => 'Баланс';

  @override
  String get sats => 'саты';

  @override
  String get selected => 'ВЫБРАНО';

  @override
  String get receiveOnlyWallet => 'Кошелёк только для получения';

  @override
  String receiveRange(int min, int max) {
    return 'Получить: $min - $max сат';
  }

  @override
  String get limitsUnavailable => 'Лимиты недоступны';

  @override
  String get tokenCopied => 'Токен скопирован';

  @override
  String get deleteWalletConfirmation => 'Удалить Кошелёк?';

  @override
  String get deleteWalletConfirmationMessage => 'Вы уверены, что хотите удалить этот кошелёк? Это действие нельзя отменить.';

  @override
  String get addWalletTitle => 'Добавить Кошелёк';

  @override
  String get chooseWalletType => 'Выберите тип кошелька';

  @override
  String get nwcWalletTypeTitle => 'Nostr Wallet Connect';

  @override
  String get nwcWalletTypeSubtitle => 'Подключиться к удаленному кошельку через NWC';

  @override
  String get lnurlWalletTypeTitle => 'LNURL / Lightning-адрес';

  @override
  String get lnurlWalletTypeSubtitle => 'Использовать кастодиальный кошелек с LNURL или Lightning-адресом';

  @override
  String get cashuWalletTypeTitle => 'Cashu';

  @override
  String get cashuWalletTypeSubtitle => 'Использовать ecash-кошелек на базе монетного двора Cashu';

  @override
  String get cashuOption => 'Cashu';

  @override
  String get nwcOption => 'NWC';

  @override
  String get lnurlOption => 'LNURL';

  @override
  String get connectNwcTitle => 'Подключить NWC';

  @override
  String get chooseNwcMethod => 'Выберите способ подключения';

  @override
  String get albyGoOption => 'Alby Go';

  @override
  String get manualOption => 'Вручную';

  @override
  String get faucetOption => 'Кран';

  @override
  String get invalidNwcQrCode => 'Неверный QR-код NWC';

  @override
  String get scanNwcQrCodeTitle => 'Сканировать QR-код NWC';

  @override
  String get cameraNotAvailable => 'Камера недоступна';

  @override
  String get scanNwcInstructions => 'Отсканируйте QR-код из приложения кошелька NWC';

  @override
  String get invalidNwcUri => 'Неверный URI NWC';

  @override
  String get paste => 'Вставить';

  @override
  String get fromYourProfile => 'Из вашего профиля';

  @override
  String get orEnterManually => 'Или введите вручную:';

  @override
  String get renameWallet => 'Переименовать';

  @override
  String get pickColor => 'Выбрать цвет';

  @override
  String get deleteWallet => 'Удалить';

  @override
  String get walletName => 'Название кошелька';

  @override
  String get walletNameHint => 'Введите название кошелька';

  @override
  String get save => 'Сохранить';

  @override
  String get walletRenamed => 'Кошелек переименован';

  @override
  String budgetUsedOf(int used, int total) {
    final intl.NumberFormat usedNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String usedString = usedNumberFormat.format(used);
    final intl.NumberFormat totalNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return 'Бюджет: $usedString / $totalString';
  }

  @override
  String budgetRenewsIn(int days) {
    return 'Обновление через $days дн.';
  }

  @override
  String get budgetDaily => 'Ежедневно';

  @override
  String get budgetWeekly => 'Еженедельно';

  @override
  String get budgetMonthly => 'Ежемесячно';

  @override
  String get budgetYearly => 'Ежегодно';

  @override
  String get budgetNever => 'Никогда';
}
