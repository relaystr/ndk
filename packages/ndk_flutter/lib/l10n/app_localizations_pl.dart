// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Polish (`pl`).
class AppLocalizationsPl extends AppLocalizations {
  AppLocalizationsPl([String locale = 'pl']) : super(locale);

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
  String get loginWithAmber => 'Zaloguj się przez Amber';

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
      'Utwórz testowy portfel z satoshi z kranu NWC.';

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
    return 'Portfel NWC dodany z saldem $balance satoshi!';
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
  String get sats => 'satoshi';

  @override
  String get selected => 'WYBRANY';

  @override
  String get receiveOnlyWallet => 'Portfel tylko do odbioru';

  @override
  String receiveRange(int min, int max) {
    return 'Odbiór: $min - $max satoshi';
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
  String get chooseWalletType => 'Wybierz typ portfela';

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
}
