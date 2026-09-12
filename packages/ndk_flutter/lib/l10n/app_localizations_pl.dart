// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Polish (`pl`).
class AppLocalizationsPl extends AppLocalizations {
  AppLocalizationsPl([String locale = 'pl']) : super(locale);

  @override
  String get lnbitsWalletOption => 'LNbits';

  @override
  String get lnbitsConnectionInstructions =>
      'W LNbits wybierz portfel, który chcesz połączyć, otwórz go, kliknij Dokumentacja API i skopiuj klucz administratora. Wklej go poniżej:';

  @override
  String get lnbitsAdminKey => 'Klucz administratora LNbits';

  @override
  String get lnbitsKeyType => 'Typ klucza LNbits';

  @override
  String get lnbitsInvoiceReadKey => 'Klucz faktur/odczytu LNbits';

  @override
  String get lnbitsReadOnlyDescription =>
      'Portfel tylko do odbioru: wyświetla saldo i historię oraz tworzy faktury. Wysyłanie płatności jest wyłączone.';

  @override
  String get lnbitsUrl => 'Adres URL LNbits';

  @override
  String get lnbitsCredentialsRequired =>
      'Wprowadź klucz administratora i adres URL LNbits.';

  @override
  String get lnbitsWalletAdded => 'Portfel LNbits został dodany';

  @override
  String get walletDetailWalletId => 'Identyfikator portfela';

  @override
  String get saveBackupToFile => 'Zapisz kopię do pliku';

  @override
  String get backupSavedToFile => 'Kopia zapisana do pliku';

  @override
  String get restoreFromFile => 'Przywróć z pliku';

  @override
  String get backupFileReadFailed =>
      'Nie udało się odczytać wybranego pliku kopii zapasowej.';

  @override
  String get fetchingWalletConnectionInfo =>
      'Pobieranie danych połączenia portfela…';

  @override
  String get createAccount => 'Utwórz konto';

  @override
  String get newHere => 'Jesteś tu nowy?';

  @override
  String get nostrAddress => 'Adres Nostr';

  @override
  String get publicKey => 'Klucz publiczny';

  @override
  String get privateKey => 'Klucz prywatny (niebezpieczny)';

  @override
  String get browserExtension => 'Rozszerzenie przeglądarki';

  @override
  String get connect => 'Połącz';

  @override
  String get install => 'Zainstaluj';

  @override
  String get logout => 'Wyloguj';

  @override
  String get nostrAddressHint => 'name@example.com';

  @override
  String get invalidAddress => 'Nieprawidłowy adres';

  @override
  String get unableToConnect => 'Nie można nawiązać połączenia';

  @override
  String get publicKeyHint => 'npub1...';

  @override
  String get privateKeyHint => 'nsec1...';

  @override
  String get newToNostr => 'Nowy w Nostr?';

  @override
  String get getStarted => 'Zacznij';

  @override
  String get bunker => 'Bunker';

  @override
  String get bunkerAuthentication => 'Uwierzytelnianie Bunker';

  @override
  String tapToOpen(String url) {
    return 'Dotknij, aby otworzyć: $url';
  }

  @override
  String get showNostrConnectQrcode => 'Pokaż kod QR Nostr Connect';

  @override
  String get loginWithSignerApp => 'Zaloguj się przez aplikację podpisującą';

  @override
  String get nostrConnectUrl => 'URL Nostr Connect';

  @override
  String get copy => 'Kopiuj';

  @override
  String get addAccount => 'Dodaj konto';

  @override
  String get readOnly => 'Tylko do odczytu';

  @override
  String get nsec => 'Nsec';

  @override
  String get extension => 'Rozszerzenie';

  @override
  String get userMetadata => 'Metadane użytkownika';

  @override
  String get shortTextNote => 'Krótka notatka tekstowa';

  @override
  String get recommendRelay => 'Zalecany przekaźnik';

  @override
  String get follows => 'Obserwowani';

  @override
  String get encryptedDirectMessages => 'Zaszyfrowane wiadomości bezpośrednie';

  @override
  String get eventDeletionRequest => 'Żądanie usunięcia zdarzenia';

  @override
  String get repost => 'Udostępnienie';

  @override
  String get reaction => 'Reakcja';

  @override
  String get badgeAward => 'Przyznanie odznaki';

  @override
  String get chatMessage => 'Wiadomość czatu';

  @override
  String get groupChatThreadedReply => 'Odpowiedź wątkowa czatu grupowego';

  @override
  String get thread => 'Wątek';

  @override
  String get groupThreadReply => 'Odpowiedź w wątku grupowym';

  @override
  String get seal => 'Pieczęć';

  @override
  String get directMessage => 'Wiadomość bezpośrednia';

  @override
  String get fileMessage => 'Wiadomość z plikiem';

  @override
  String get genericRepost => 'Ogólne udostępnienie';

  @override
  String get reactionToWebsite => 'Reakcja na stronę internetową';

  @override
  String get picture => 'Zdjęcie';

  @override
  String get videoEvent => 'Zdarzenie wideo';

  @override
  String get shortFormPortraitVideoEvent => 'Krótkie wideo pionowe';

  @override
  String get internalReference => 'Odwołanie wewnętrzne';

  @override
  String get externalReference => 'Odwołanie zewnętrzne';

  @override
  String get hardcopyReference => 'Odwołanie do wydruku';

  @override
  String get promptReference => 'Odwołanie do podpowiedzi';

  @override
  String get channelCreation => 'Tworzenie kanału';

  @override
  String get channelMetadata => 'Metadane kanału';

  @override
  String get channelMessage => 'Wiadomość kanału';

  @override
  String get channelHideMessage => 'Ukrycie wiadomości kanału';

  @override
  String get channelMuteUser => 'Wyciszenie użytkownika kanału';

  @override
  String get requestToVanish => 'Żądanie zniknięcia';

  @override
  String get chessPgn => 'Szachy (PGN)';

  @override
  String get mlsKeyPackage => 'Pakiet kluczy MLS';

  @override
  String get mlsWelcome => 'Powitanie MLS';

  @override
  String get mlsGroupEvent => 'Zdarzenie grupy MLS';

  @override
  String get mergeRequests => 'Żądania scalenia';

  @override
  String get pollResponse => 'Odpowiedź na ankietę';

  @override
  String get marketplaceBid => 'Oferta rynkowa';

  @override
  String get marketplaceBidConfirmation => 'Potwierdzenie oferty rynkowej';

  @override
  String get openTimestamps => 'OpenTimestamps';

  @override
  String get giftWrap => 'Opakowanie prezentu';

  @override
  String get fileMetadata => 'Metadane pliku';

  @override
  String get poll => 'Ankieta';

  @override
  String get comment => 'Komentarz';

  @override
  String get voiceMessage => 'Wiadomość głosowa';

  @override
  String get voiceMessageComment => 'Komentarz do wiadomości głosowej';

  @override
  String get liveChatMessage => 'Wiadomość czatu na żywo';

  @override
  String get codeSnippet => 'Fragment kodu';

  @override
  String get gitPatch => 'Łatka Git';

  @override
  String get gitPullRequest => 'Żądanie ściągnięcia Git';

  @override
  String get gitStatusUpdate => 'Aktualizacja statusu Git';

  @override
  String get gitIssue => 'Problem Git';

  @override
  String get gitIssueUpdate => 'Aktualizacja problemu Git';

  @override
  String get status => 'Status';

  @override
  String get statusUpdate => 'Aktualizacja statusu';

  @override
  String get statusDelete => 'Usunięcie statusu';

  @override
  String get statusReply => 'Odpowiedź na status';

  @override
  String get problemTracker => 'Śledzenie problemów';

  @override
  String get reporting => 'Raportowanie';

  @override
  String get label => 'Etykieta';

  @override
  String get relayReviews => 'Recenzje przekaźników';

  @override
  String get aiEmbeddings => 'Osadzenia AI / Listy wektorów';

  @override
  String get torrent => 'Torrent';

  @override
  String get torrentComment => 'Komentarz do torrentu';

  @override
  String get coinjoinPool => 'Pula Coinjoin';

  @override
  String get communityPostApproval => 'Zatwierdzenie wpisu społeczności';

  @override
  String get jobRequest => 'Zlecenie pracy';

  @override
  String get jobResult => 'Wynik pracy';

  @override
  String get jobFeedback => 'Opinia o pracy';

  @override
  String get cashuWalletToken => 'Token portfela Cashu';

  @override
  String get cashuWalletProofs => 'Dowody portfela Cashu';

  @override
  String get cashuWalletHistory => 'Historia portfela Cashu';

  @override
  String get geocacheCreate => 'Utwórz geoskrzynkę';

  @override
  String get geocacheUpdate => 'Aktualizacja geoskrzynki';

  @override
  String get groupControlEvent => 'Zdarzenie kontroli grupy';

  @override
  String get zapGoal => 'Cel Zap';

  @override
  String get nutzap => 'Nutzap';

  @override
  String get tidalLogin => 'Logowanie Tidal';

  @override
  String get zapRequest => 'Żądanie Zap';

  @override
  String get zap => 'Zap';

  @override
  String get highlights => 'Wyróżnienia';

  @override
  String get muteList => 'Lista wyciszenia';

  @override
  String get pinList => 'Lista przypiętych';

  @override
  String get relayListMetadata => 'Metadane listy przekaźników';

  @override
  String get bookmarkList => 'Lista zakładek';

  @override
  String get communitiesList => 'Lista społeczności';

  @override
  String get publicChatsList => 'Lista publicznych czatów';

  @override
  String get blockedRelaysList => 'Lista zablokowanych przekaźników';

  @override
  String get searchRelaysList => 'Lista przekaźników wyszukiwania';

  @override
  String get userGroups => 'Grupy użytkownika';

  @override
  String get favoritesList => 'Lista ulubionych';

  @override
  String get privateEventsList => 'Lista prywatnych zdarzeń';

  @override
  String get interestsList => 'Lista zainteresowań';

  @override
  String get mediaFollowsList => 'Lista obserwowanych mediów';

  @override
  String get peopleFollowsList => 'Lista obserwowanych osób';

  @override
  String get userEmojiList => 'Lista emoji użytkownika';

  @override
  String get dmRelayList => 'Lista przekaźników DM';

  @override
  String get keyPackageRelayList => 'Lista przekaźników pakietów kluczy';

  @override
  String get userServerList => 'Lista serwerów użytkownika';

  @override
  String get fileStorageServerList => 'Lista serwerów przechowywania plików';

  @override
  String get relayMonitorAnnouncement => 'Ogłoszenie monitora przekaźnika';

  @override
  String get roomPresence => 'Obecność w pokoju';

  @override
  String get proxyAnnouncement => 'Ogłoszenie proxy';

  @override
  String get transportMethodAnnouncement => 'Ogłoszenie metody transportu';

  @override
  String get walletInfo => 'Informacje o portfelu';

  @override
  String get cashuWalletEvent => 'Zdarzenie portfela Cashu';

  @override
  String get lightningPubRpc => 'Lightning Pub RPC';

  @override
  String get clientAuthentication => 'Uwierzytelnianie klienta';

  @override
  String get walletRequest => 'Żądanie portfela';

  @override
  String get walletResponse => 'Odpowiedź portfela';

  @override
  String get nostrConnectEvent => 'Nostr Connect';

  @override
  String get blobsStoredOnMediaservers =>
      'Bloby przechowywane na serwerach mediów';

  @override
  String get httpAuth => 'Uwierzytelnianie HTTP';

  @override
  String get categorizedPeopleList => 'Skategoryzowana lista osób';

  @override
  String get categorizedBookmarkList => 'Skategoryzowana lista zakładek';

  @override
  String get categorizedRelayList => 'Skategoryzowana lista przekaźników';

  @override
  String get bookmarkSets => 'Zestawy zakładek';

  @override
  String get curationSets => 'Zestawy kuracji';

  @override
  String get videoSets => 'Zestawy wideo';

  @override
  String get kindMuteSets => 'Zestawy wyciszenia typów';

  @override
  String get profileBadges => 'Odznaki profilu';

  @override
  String get badgeDefinition => 'Definicja odznaki';

  @override
  String get interestSets => 'Zestawy zainteresowań';

  @override
  String get createOrUpdateStall => 'Utwórz lub zaktualizuj stoisko';

  @override
  String get createOrUpdateProduct => 'Utwórz lub zaktualizuj produkt';

  @override
  String get marketplaceUiUx => 'Interfejs rynku';

  @override
  String get productSoldAsAuction => 'Produkt sprzedany na aukcji';

  @override
  String get longFormContent => 'Treść długa';

  @override
  String get draftLongFormContent => 'Wersja robocza treści długiej';

  @override
  String get emojiSets => 'Zestawy emoji';

  @override
  String get curatedPublicationItem => 'Wyselekcjonowany element publikacji';

  @override
  String get curatedPublicationDraft =>
      'Wersja robocza wyselekcjonowanej publikacji';

  @override
  String get releaseArtifactSets => 'Zestawy artefaktów wydania';

  @override
  String get applicationSpecificData => 'Dane specyficzne dla aplikacji';

  @override
  String get relayDiscovery => 'Odkrywanie przekaźników';

  @override
  String get appCurationSets => 'Zestawy kuracji aplikacji';

  @override
  String get liveEvent => 'Wydarzenie na żywo';

  @override
  String get userStatus => 'Status użytkownika';

  @override
  String get slideSet => 'Zestaw slajdów';

  @override
  String get classifiedListing => 'Ogłoszenie klasyfikowane';

  @override
  String get draftClassifiedListing =>
      'Wersja robocza ogłoszenia klasyfikowanego';

  @override
  String get repositoryAnnouncement => 'Ogłoszenie repozytorium';

  @override
  String get repositoryStateAnnouncement => 'Ogłoszenie stanu repozytorium';

  @override
  String get wikiArticle => 'Artykuł Wiki';

  @override
  String get redirects => 'Przekierowania';

  @override
  String get draftEvent => 'Wersja robocza zdarzenia';

  @override
  String get linkSet => 'Zestaw linków';

  @override
  String get feed => 'Kanał';

  @override
  String get dateBasedCalendarEvent => 'Wydarzenie kalendarza (data)';

  @override
  String get timeBasedCalendarEvent => 'Wydarzenie kalendarza (czas)';

  @override
  String get calendar => 'Kalendarz';

  @override
  String get calendarEventRsvp => 'RSVP na wydarzenie kalendarza';

  @override
  String get handlerRecommendation => 'Rekomendacja obsługi';

  @override
  String get handlerInformation => 'Informacje o obsłudze';

  @override
  String get softwareApplication => 'Aplikacja';

  @override
  String get videoView => 'Widok wideo';

  @override
  String get communityDefinition => 'Definicja społeczności';

  @override
  String get geocacheListing => 'Wpis geoskrzynki';

  @override
  String get mintAnnouncement => 'Ogłoszenie mennicy';

  @override
  String get mintQuote => 'Wycena mennicy';

  @override
  String get peerToPeerOrder => 'Zamówienie peer-to-peer';

  @override
  String get groupMetadata => 'Metadane grupy';

  @override
  String get groupAdminMetadata => 'Metadane administratora grupy';

  @override
  String get groupMemberMetadata => 'Metadane członka grupy';

  @override
  String get groupAdminsList => 'Lista administratorów grupy';

  @override
  String get groupMembersList => 'Lista członków grupy';

  @override
  String get groupRoles => 'Role grupy';

  @override
  String get groupPermissions => 'Uprawnienia grupy';

  @override
  String get groupChatMessage => 'Wiadomość czatu grupowego';

  @override
  String get groupChatThread => 'Wątek czatu grupowego';

  @override
  String get groupPinned => 'Przypięte w grupie';

  @override
  String get starterPacks => 'Pakiety startowe';

  @override
  String get mediaStarterPacks => 'Medialne pakiety startowe';

  @override
  String get webBookmarks => 'Zakładki internetowe';

  @override
  String unknownEventKind(int kind) {
    return 'Typ zdarzenia $kind';
  }

  @override
  String get walletsTitle => 'Portfele';

  @override
  String get recentActivityTitle => 'Ostatnia aktywność';

  @override
  String get addCashuWallet => 'Dodaj portfel Cashu';

  @override
  String get addNwcWallet => 'Dodaj portfel NWC';

  @override
  String get addLnurlWallet => 'Dodaj portfel LNURL';

  @override
  String get addCashuTooltip => 'Dodaj portfel Cashu';

  @override
  String get addNwcTooltip => 'Dodaj portfel NWC';

  @override
  String get addLnurlTooltip => 'Dodaj portfel LNURL';

  @override
  String get addCashuWalletTitle => 'Dodaj portfel Cashu';

  @override
  String get enterMintUrl =>
      'Wprowadź adres URL mennicy, aby dodać portfel Cashu.';

  @override
  String get mintUrl => 'URL mennicy';

  @override
  String get mintUrlHint => 'https://mint.example.com';

  @override
  String get pleaseEnterMintUrl => 'Proszę wprowadzić adres URL mennicy';

  @override
  String get cashuWalletAdded => 'Portfel Cashu dodany pomyślnie!';

  @override
  String get failedToAddMint =>
      'Nie udało się dodać mennicy. Sprawdź adres URL i spróbuj ponownie.';

  @override
  String get addNwcWalletTitle => 'Dodaj portfel NWC';

  @override
  String get faucet => 'Kran';

  @override
  String get manual => 'Ręcznie';

  @override
  String get nwcFaucetDescription =>
      'Utwórz testowy portfel z sats z kranu NWC.';

  @override
  String get startingBalance => 'Saldo początkowe';

  @override
  String get startingBalanceHint => '10000';

  @override
  String get nwcConnectionUri => 'URI połączenia NWC';

  @override
  String get nwcConnectionUriHint => 'nostr+walletconnect://...';

  @override
  String get nwcWalletAdded => 'Portfel NWC dodany pomyślnie!';

  @override
  String nwcFaucetWalletAdded(int balance) {
    return 'Portfel NWC dodany z saldem $balance sats!';
  }

  @override
  String get invalidFaucetResponse => 'Nieprawidłowa odpowiedź z kranu';

  @override
  String get errorCreatingWallet => 'Błąd podczas tworzenia portfela';

  @override
  String get addLnurlWalletTitle => 'Dodaj portfel LNURL';

  @override
  String get enterLnurlIdentifier =>
      'Wprowadź swój identyfikator LNURL (użytkownik@domena.com).';

  @override
  String get lnurlIdentifierHint => 'user@example.com';

  @override
  String get pleaseEnterValidIdentifier =>
      'Proszę wprowadzić prawidłowy identyfikator (użytkownik@domena.com)';

  @override
  String get lnurlWalletAdded => 'Portfel LNURL dodany pomyślnie!';

  @override
  String get cancel => 'Anuluj';

  @override
  String get add => 'Dodaj';

  @override
  String get send => 'Wyślij';

  @override
  String get receive => 'Otrzymaj';

  @override
  String get setAsDefaultForReceiving => 'Ustaw jako domyślny do odbierania';

  @override
  String get setAsDefaultForSending => 'Ustaw jako domyślny do wysyłania';

  @override
  String get defaultForReceiving => 'Domyślny do odbierania';

  @override
  String get defaultForSending => 'Domyślny do wysyłania';

  @override
  String get defaultWalletForReceivingTooltip =>
      'Ten portfel jest domyślny do odbierania płatności.';

  @override
  String get defaultWalletForSendingTooltip =>
      'Ten portfel jest domyślny do wysyłania płatności.';

  @override
  String get sendOptionsTitle => 'Opcje wysyłania';

  @override
  String get sendByToken => 'Wyślij tokenem';

  @override
  String get sendByTokenDescription => 'Utwórz token Cashu do wysłania';

  @override
  String get sendByLightning => 'Wyślij przez Lightning';

  @override
  String get sendByLightningDescription => 'Zapłać fakturę Lightning';

  @override
  String get payInvoiceTitle => 'Zapłać fakturę';

  @override
  String get sendToWallet => 'Send to Wallet';

  @override
  String get sendToWalletDescription => 'Transfer to another compatible wallet';

  @override
  String get noCompatibleReceivingWallets => 'No compatible receiving wallets';

  @override
  String get noCompatibleReceivingWalletsDescription =>
      'Add or connect another wallet that can receive a payment supported by this wallet.';

  @override
  String get destinationWallet => 'Destination wallet';

  @override
  String walletTransferSubmitted(String walletName) {
    return 'Payment sent to $walletName';
  }

  @override
  String get invoice => 'Faktura';

  @override
  String get invoiceHint => 'lnbc...';

  @override
  String get pleaseEnterInvoice => 'Proszę wprowadzić fakturę';

  @override
  String get invoicePaid => 'Faktura opłacona!';

  @override
  String paymentFailed(String message) {
    return 'Płatność nieudana: $message';
  }

  @override
  String get receiveOptionsTitle => 'Opcje odbierania';

  @override
  String get receiveByToken => 'Otrzymaj tokenem';

  @override
  String get receiveByTokenDescription => 'Otrzymaj token Cashu';

  @override
  String get receiveByLightning => 'Otrzymaj przez Lightning';

  @override
  String get receiveByLightningDescription => 'Utwórz fakturę Lightning';

  @override
  String get receiveByTokenTitle => 'Otrzymaj tokenem';

  @override
  String get token => 'Token';

  @override
  String get tokenHint => 'Wklej token tutaj...';

  @override
  String get pleaseEnterToken => 'Proszę wprowadzić token';

  @override
  String get tokenReceived => 'Token odebrany!';

  @override
  String get createInvoiceTitle => 'Utwórz fakturę';

  @override
  String get amount => 'Kwota';

  @override
  String get amountHint => '100';

  @override
  String get pleaseEnterValidAmount => 'Proszę wprowadzić prawidłową kwotę';

  @override
  String get tokenCopiedToClipboard => 'Token skopiowany do schowka!';

  @override
  String get invoiceCreatedAndCopied => 'Faktura utworzona i skopiowana!';

  @override
  String get invoiceTrackingTitle => 'Faktura Lightning';

  @override
  String get invoiceCreatedMessage => 'Faktura utworzona i skopiowana!';

  @override
  String get close => 'Zamknij';

  @override
  String get copyAgain => 'Kopiuj ponownie';

  @override
  String get copied => 'Skopiowano!';

  @override
  String get paymentReceived => 'Płatność odebrana!';

  @override
  String get waitingForPayment => 'Oczekiwanie na płatność...';

  @override
  String get paid => 'Zapłacono!';

  @override
  String get createToken => 'Utwórz token';

  @override
  String get pay => 'Zapłać';

  @override
  String get create => 'Utwórz';

  @override
  String get pendingTransactions => 'Oczekujące';

  @override
  String get backupSeedWarning => 'Utwórz kopię frazy odzyskiwania cashu';

  @override
  String get backupSeedTitle => 'Kopia frazy odzyskiwania cashu';

  @override
  String get backupSeedInstructions =>
      'Zapisz te słowa w kolejności i przechowuj je w bezpiecznym miejscu. To jedyny sposób na odzyskanie środków cashu w razie utraty tego urządzenia.';

  @override
  String get backupSeedConfirm =>
      'Zapisałem moją frazę odzyskiwania i bezpiecznie ją przechowuję';

  @override
  String get backupSeedDone => 'Utworzyłem kopię';

  @override
  String get reclaimPendingFunds => 'Odzyskaj oczekujące środki';

  @override
  String get reclaimPendingTitle => 'Odzyskaj oczekujące środki';

  @override
  String get recentTransactions => 'Ostatnie transakcje';

  @override
  String get noRecentTransactions => 'Brak ostatnich transakcji';

  @override
  String get noWalletsYet => 'Brak portfeli';

  @override
  String get noWalletsAvailable => 'Brak dostępnych portfeli';

  @override
  String get tapToAddWallet => 'Dotknij +, aby dodać';

  @override
  String get delete => 'Usuń';

  @override
  String error(String message) {
    return 'Błąd: $message';
  }

  @override
  String get unknownWalletType => 'Nieznany';

  @override
  String get cashuWallet => 'Cashu';

  @override
  String get nwcWallet => 'NWC';

  @override
  String get lnurlWallet => 'LNURL';

  @override
  String get nwcWalletSubtitle => 'Portfel NWC';

  @override
  String get balance => 'Saldo';

  @override
  String get sats => 'sats';

  @override
  String get selected => 'WYBRANY';

  @override
  String get receiveOnlyWallet => 'Portfel tylko do odbioru';

  @override
  String receiveRange(int min, int max) {
    return 'Odbiór: $min - $max sats';
  }

  @override
  String get limitsUnavailable => 'Limity niedostępne';

  @override
  String get tokenCopied => 'Token skopiowany';

  @override
  String get deleteWalletConfirmation => 'Usunąć Portfel?';

  @override
  String get deleteWalletConfirmationMessage =>
      'Czy na pewno chcesz usunąć ten portfel? Tej operacji nie można cofnąć.';

  @override
  String get addWalletTitle => 'Dodaj portfel';

  @override
  String get addWalletDescription =>
      'Zeskanuj obsługiwany kod QR portfela, wklej dane lub połącz się przez aplikację portfela.';

  @override
  String get scanWalletQrCode => 'Skanuj kod QR portfela';

  @override
  String get connectWithWallet => 'Połącz z portfelem';

  @override
  String get chooseWalletApp => 'Wybierz aplikację portfela';

  @override
  String get oneClickConnect => 'Połącz jednym kliknięciem';

  @override
  String get chooseWallet => 'Wybierz portfel';

  @override
  String get albyWalletOption => 'Alby';

  @override
  String get albyCloudOption => 'Alby Cloud';

  @override
  String get coinosWalletOption => 'Coinos';

  @override
  String get manualNwcConnection => 'Ręczne połączenie NWC';

  @override
  String walletConnectionFinishIn(String walletName) {
    return 'Dokończ połączenie w $walletName';
  }

  @override
  String walletConnectionConnecting(String walletName) {
    return 'Łączenie z $walletName…';
  }

  @override
  String walletConnectionConnected(String walletName) {
    return 'Połączono z $walletName';
  }

  @override
  String walletConnectionFailed(String walletName) {
    return 'Nie udało się połączyć z $walletName';
  }

  @override
  String get retry => 'Spróbuj ponownie';

  @override
  String get chooseAnotherWallet => 'Wybierz inny portfel';

  @override
  String get chooseWalletAppDescription =>
      'Zatwierdź połączenie NWC w zainstalowanym portfelu';

  @override
  String get walletInput => 'Adres lub połączenie portfela';

  @override
  String get walletInputHint =>
      'NWC, adres Lightning/BIP353, oferta BOLT12/BIP321 lub adres HTTPS mintu Cashu';

  @override
  String get unsupportedWalletInput =>
      'Ten adres lub typ połączenia portfela nie jest obsługiwany.';

  @override
  String get detected => 'Wykryto';

  @override
  String get lightningAddressInputType => 'Adres Lightning lub BIP353';

  @override
  String get manualWalletSetup => 'Skonfiguruj ręcznie';

  @override
  String get chooseWalletType => 'Wybierz typ portfela';

  @override
  String get nwcWalletTypeTitle => 'Nostr Wallet Connect';

  @override
  String get nwcWalletTypeSubtitle => 'Polacz z portfelem zdalnym przez NWC';

  @override
  String get lnurlWalletTypeTitle => 'Adres Lightning (LNURL)';

  @override
  String get lnurlWalletTypeSubtitle =>
      'Uzyj adresu Lightning (LNURL) tylko do odbierania';

  @override
  String get cashuWalletTypeTitle => 'Cashu';

  @override
  String get chooseCashuMint => 'Wybierz mint Cashu';

  @override
  String get cashuMintRatingsNotice =>
      'Oceny społeczności pochodzą z podpisanych recenzji Nostr. Wysoka ocena nie gwarantuje bezpieczeństwa mintu.';

  @override
  String get cashuMintDiscoveryFailed =>
      'Nie udało się wczytać propozycji mintów.';

  @override
  String get noCashuMintSuggestions =>
      'Nie znaleziono dostępnych propozycji mintów.';

  @override
  String get noRatingsYet => 'Brak ocen';

  @override
  String cashuMintRating(String rating, int count) {
    return '★ $rating · $count recenzji';
  }

  @override
  String get enterMintUrlManually => 'Wprowadź ręcznie adres URL mintu';

  @override
  String get cashuWalletTypeSubtitle =>
      'Uzyj portfela ecash opartego na mennicy Cashu';

  @override
  String get cashuOption => 'Cashu';

  @override
  String get nwcOption => 'NWC';

  @override
  String get lnurlOption => 'LNURL';

  @override
  String get connectNwcTitle => 'Połącz NWC';

  @override
  String get chooseNwcMethod => 'Wybierz metodę połączenia';

  @override
  String get albyGoOption => 'Alby Go';

  @override
  String get manualOption => 'Ręcznie';

  @override
  String get faucetOption => 'Kran';

  @override
  String get invalidNwcQrCode => 'Nieprawidłowy kod QR NWC';

  @override
  String get scanNwcQrCodeTitle => 'Skanuj kod QR NWC';

  @override
  String get cameraNotAvailable => 'Kamera niedostępna';

  @override
  String get scanNwcInstructions => 'Zeskanuj kod QR z aplikacji portfela NWC';

  @override
  String get invalidNwcUri => 'Nieprawidłowy URI NWC';

  @override
  String get paste => 'Wklej';

  @override
  String get clearInput => 'Wyczyść pole';

  @override
  String get pasteOrEnter => 'Wklej lub wpisz';

  @override
  String get fromYourProfile => 'Z twojego profilu';

  @override
  String get orEnterManually => 'Lub wprowadź ręcznie:';

  @override
  String get renameWallet => 'Zmień nazwę';

  @override
  String get pickColor => 'Wybierz kolor';

  @override
  String get deleteWallet => 'Usuń';

  @override
  String get walletName => 'Nazwa portfela';

  @override
  String get walletNameHint => 'Wprowadź nazwę portfela';

  @override
  String get save => 'Zapisz';

  @override
  String get walletRenamed => 'Zmieniono nazwę portfela';

  @override
  String budgetUsedOf(int used, int total) {
    final intl.NumberFormat usedNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String usedString = usedNumberFormat.format(used);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return 'Budżet: $usedString / $totalString';
  }

  @override
  String budgetRenewsIn(int days) {
    return 'Odnowienie za $days dni';
  }

  @override
  String get budgetDaily => 'Codziennie';

  @override
  String get budgetWeekly => 'Tygodniowo';

  @override
  String get budgetMonthly => 'Miesięcznie';

  @override
  String get budgetYearly => 'Rocznie';

  @override
  String get budgetNever => 'Nigdy';

  @override
  String get backup => 'Backup';

  @override
  String get restore => 'Restore';

  @override
  String get cashuBackupTitle => 'Cashu Backup';

  @override
  String get cashuBackupWarning =>
      'This backup contains your ecash proofs, which are bearer funds. Keep it private and store it somewhere safe. Your seed phrase is backed up separately.';

  @override
  String get generatingBackup => 'Generating backup...';

  @override
  String get copyBackup => 'Copy backup';

  @override
  String get backupCopiedToClipboard => 'Backup copied to clipboard';

  @override
  String get cashuRestoreTitle => 'Restore Cashu Backup';

  @override
  String get backupJson => 'Backup JSON';

  @override
  String get backupJsonHint => 'Paste your backup JSON here';

  @override
  String get pleaseEnterBackup => 'Please enter a backup';

  @override
  String get restoringBackup => 'Restoring backup...';

  @override
  String restoreSuccess(int count) {
    return 'Restored $count proofs from backup';
  }

  @override
  String get bolt12Wallet => 'Portfel BOLT12';

  @override
  String get bolt12WalletSubtitle => 'Reusable Lightning offer';

  @override
  String get bolt12PrivateOfferSubtitle => 'Reusable private offer';

  @override
  String get anyAmount => 'Any amount';

  @override
  String get blindedRoute => 'Blinded';

  @override
  String fromAmountSats(String amount) {
    return 'From $amount sats';
  }

  @override
  String fromAmountMsats(String amount) {
    return 'From $amount msats';
  }

  @override
  String fromCurrencyAmount(String amount, String currency) {
    return 'From $amount $currency';
  }

  @override
  String bolt12Expires(String date) {
    return 'Expires $date';
  }

  @override
  String get bolt12WalletTypeTitle => 'Oferta BOLT12';

  @override
  String get bip353WalletTypeTitle => 'BIP353';

  @override
  String get lnurlProtocol => 'LNURL';

  @override
  String get bolt12WalletTypeSubtitle =>
      'Receive-only wallet using a reusable offer';

  @override
  String get addBolt12WalletTitle => 'Dodaj portfel BOLT12';

  @override
  String get enterBolt12Input =>
      'Wprowadź lub zeskanuj ofertę lno, URI bitcoin:?lno=… albo adres BIP353.';

  @override
  String get bolt12Input => 'Cel płatności BOLT12';

  @override
  String get bolt12InputHint =>
      'lno1…, bitcoin:?lno=… lub użytkownik@domena.com';

  @override
  String get walletNameOptional => 'Nazwa portfela (opcjonalna)';

  @override
  String get scanBolt12QrCodeTitle => 'Skanuj kod QR BOLT12';

  @override
  String get invalidBolt12QrCode =>
      'The QR code is not a BOLT12, BIP321, or BIP353 payment target.';

  @override
  String get pleaseEnterBolt12Input =>
      'Wprowadź ofertę BOLT12 lub adres BIP353.';

  @override
  String get bolt12WalletAdded => 'Dodano portfel BOLT12!';

  @override
  String get bolt12OfferTitle => 'Receive with BOLT12';

  @override
  String get bolt12OfferInstructions =>
      'Share this reusable offer to receive a Lightning payment.';

  @override
  String get confirm => 'Potwierdź';

  @override
  String get reviewWallet => 'Sprawdź portfel';

  @override
  String get confirmWalletTitle => 'Potwierdź portfel';

  @override
  String get confirmWalletDescription =>
      'Sprawdź te dane przed dodaniem portfela.';

  @override
  String get walletDetailType => 'Typ portfela';

  @override
  String get walletDetailAddress => 'Adres';

  @override
  String get walletDetailDomain => 'Domena';

  @override
  String get walletDetailUrl => 'URL';

  @override
  String get walletDetailPublicKey => 'Klucz publiczny';

  @override
  String get walletDetailRelay => 'Przekaźnik';

  @override
  String get walletDetailRelays => 'Przekaźniki';

  @override
  String get walletDetailSecret => 'Sekret połączenia';

  @override
  String get walletSecretHidden => 'Obecny i ukryty ze względów bezpieczeństwa';

  @override
  String get walletDetailDescription => 'Opis';

  @override
  String get walletDetailDetails => 'Szczegóły';

  @override
  String get walletDetailIssuer => 'Wystawca';

  @override
  String get walletDetailAmount => 'Kwota';

  @override
  String get walletDetailCurrency => 'Waluta';

  @override
  String get walletDetailExpiry => 'Wygasa';

  @override
  String get walletDetailNodeId => 'ID węzła';

  @override
  String get walletDetailOffer => 'Oferta BOLT12';

  @override
  String get walletDetailVersion => 'Wersja';

  @override
  String get walletDetailUnits => 'Obsługiwane jednostki';

  @override
  String get walletDetailContact => 'Kontakt';

  @override
  String get walletDetailTerms => 'Warunki korzystania';

  @override
  String get walletDetailMessage => 'Wiadomość';

  @override
  String get walletDetailCommunityRating => 'Ocena społeczności';

  @override
  String get walletDetailCommunityReviews => 'Najnowsze recenzje społeczności';

  @override
  String get refreshBalance => 'Odśwież saldo';

  @override
  String get balanceRefreshed => 'Saldo odświeżone';
}
