// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Slovak (`sk`).
class AppLocalizationsSk extends AppLocalizations {
  AppLocalizationsSk([String locale = 'sk']) : super(locale);

  @override
  String get createAccount => 'Vytvorte si účet';

  @override
  String get newHere => 'Ste tu prvýkrát?';

  @override
  String get nostrAddress => 'Nostr adresa';

  @override
  String get publicKey => 'Verejný kľúč';

  @override
  String get privateKey => 'Súkromný kľúč (nezabezpečené)';

  @override
  String get browserExtension => 'Rozšírenie prehliadača';

  @override
  String get connect => 'Pripojiť';

  @override
  String get install => 'Inštalovať';

  @override
  String get logout => 'Odhlásiť sa';

  @override
  String get nostrAddressHint => 'meno@example.com';

  @override
  String get invalidAddress => 'Neplatná adresa';

  @override
  String get unableToConnect => 'Nepodarilo sa pripojiť';

  @override
  String get publicKeyHint => 'npub1...';

  @override
  String get privateKeyHint => 'nsec1...';

  @override
  String get newToNostr => 'Nostr je pre vás nový?';

  @override
  String get getStarted => 'Začať';

  @override
  String get bunker => 'Bunker';

  @override
  String get bunkerAuthentication => 'Overenie cez Bunker';

  @override
  String tapToOpen(String url) {
    return 'Ťuknutím otvoríte: $url';
  }

  @override
  String get showNostrConnectQrcode => 'Zobraziť Nostr Connect QR kód';

  @override
  String get loginWithSignerApp => 'Prihlásiť sa cez podpisovaciu aplikáciu';

  @override
  String get nostrConnectUrl => 'Nostr Connect URL';

  @override
  String get copy => 'Kopírovať';

  @override
  String get addAccount => 'Pridať účet';

  @override
  String get readOnly => 'Len na čítanie';

  @override
  String get nsec => 'Nsec';

  @override
  String get extension => 'Rozšírenie';

  @override
  String get userMetadata => 'Metadáta používateľa';

  @override
  String get shortTextNote => 'Krátka textová poznámka';

  @override
  String get recommendRelay => 'Odporučiť relay';

  @override
  String get follows => 'Sledovaní';

  @override
  String get encryptedDirectMessages => 'Šifrované priame správy';

  @override
  String get eventDeletionRequest => 'Žiadosť o vymazanie udalosti';

  @override
  String get repost => 'Repost';

  @override
  String get reaction => 'Reakcia';

  @override
  String get badgeAward => 'Udelenie odznaku';

  @override
  String get chatMessage => 'Správa v chate';

  @override
  String get groupChatThreadedReply => 'Vláknová odpoveď v skupinovom chate';

  @override
  String get thread => 'Vlákno';

  @override
  String get groupThreadReply => 'Odpoveď v skupinovom vlákne';

  @override
  String get seal => 'Pečať';

  @override
  String get directMessage => 'Priama správa';

  @override
  String get fileMessage => 'Správa so súborom';

  @override
  String get genericRepost => 'Všeobecný repost';

  @override
  String get reactionToWebsite => 'Reakcia na webstránku';

  @override
  String get picture => 'Obrázok';

  @override
  String get videoEvent => 'Video udalosť';

  @override
  String get shortFormPortraitVideoEvent => 'Krátke video na výšku';

  @override
  String get internalReference => 'Interný odkaz';

  @override
  String get externalReference => 'Externý odkaz';

  @override
  String get hardcopyReference => 'Odkaz na tlačenú kópiu';

  @override
  String get promptReference => 'Odkaz na prompt';

  @override
  String get channelCreation => 'Vytvorenie kanála';

  @override
  String get channelMetadata => 'Metadáta kanála';

  @override
  String get channelMessage => 'Správa kanála';

  @override
  String get channelHideMessage => 'Skrytie správy v kanáli';

  @override
  String get channelMuteUser => 'Stlmenie používateľa v kanáli';

  @override
  String get requestToVanish => 'Žiadosť o zmiznutie';

  @override
  String get chessPgn => 'Šach (PGN)';

  @override
  String get mlsKeyPackage => 'MLS KeyPackage';

  @override
  String get mlsWelcome => 'MLS Welcome';

  @override
  String get mlsGroupEvent => 'MLS skupinová udalosť';

  @override
  String get mergeRequests => 'Merge requesty';

  @override
  String get pollResponse => 'Odpoveď na anketu';

  @override
  String get marketplaceBid => 'Ponuka na trhovisku';

  @override
  String get marketplaceBidConfirmation => 'Potvrdenie ponuky na trhovisku';

  @override
  String get openTimestamps => 'OpenTimestamps';

  @override
  String get giftWrap => 'Gift Wrap';

  @override
  String get fileMetadata => 'Metadáta súboru';

  @override
  String get poll => 'Anketa';

  @override
  String get comment => 'Komentár';

  @override
  String get voiceMessage => 'Hlasová správa';

  @override
  String get voiceMessageComment => 'Komentár k hlasovej správe';

  @override
  String get liveChatMessage => 'Správa v živom chate';

  @override
  String get codeSnippet => 'Úryvok kódu';

  @override
  String get gitPatch => 'Git patch';

  @override
  String get gitPullRequest => 'Git pull request';

  @override
  String get gitStatusUpdate => 'Aktualizácia stavu Git';

  @override
  String get gitIssue => 'Git issue';

  @override
  String get gitIssueUpdate => 'Aktualizácia Git issue';

  @override
  String get status => 'Stav';

  @override
  String get statusUpdate => 'Aktualizácia stavu';

  @override
  String get statusDelete => 'Vymazanie stavu';

  @override
  String get statusReply => 'Odpoveď na stav';

  @override
  String get problemTracker => 'Sledovanie problémov';

  @override
  String get reporting => 'Nahlasovanie';

  @override
  String get label => 'Štítok';

  @override
  String get relayReviews => 'Recenzie relayov';

  @override
  String get aiEmbeddings => 'AI embeddingy / vektorové zoznamy';

  @override
  String get torrent => 'Torrent';

  @override
  String get torrentComment => 'Komentár k torrentu';

  @override
  String get coinjoinPool => 'Coinjoin pool';

  @override
  String get communityPostApproval => 'Schválenie príspevku komunity';

  @override
  String get jobRequest => 'Žiadosť o úlohu';

  @override
  String get jobResult => 'Výsledok úlohy';

  @override
  String get jobFeedback => 'Spätná väzba k úlohe';

  @override
  String get cashuWalletToken => 'Token Cashu peňaženky';

  @override
  String get cashuWalletProofs => 'Dôkazy Cashu peňaženky';

  @override
  String get cashuWalletHistory => 'História Cashu peňaženky';

  @override
  String get geocacheCreate => 'Vytvorenie geokešky';

  @override
  String get geocacheUpdate => 'Aktualizácia geokešky';

  @override
  String get groupControlEvent => 'Riadiaca udalosť skupiny';

  @override
  String get zapGoal => 'Zap cieľ';

  @override
  String get nutzap => 'Nutzap';

  @override
  String get tidalLogin => 'Tidal prihlásenie';

  @override
  String get zapRequest => 'Žiadosť o zap';

  @override
  String get zap => 'Zap';

  @override
  String get highlights => 'Zvýraznenia';

  @override
  String get muteList => 'Zoznam stlmených';

  @override
  String get pinList => 'Zoznam pripnutých';

  @override
  String get relayListMetadata => 'Metadáta zoznamu relayov';

  @override
  String get bookmarkList => 'Zoznam záložiek';

  @override
  String get communitiesList => 'Zoznam komunít';

  @override
  String get publicChatsList => 'Zoznam verejných chatov';

  @override
  String get blockedRelaysList => 'Zoznam blokovaných relayov';

  @override
  String get searchRelaysList => 'Zoznam vyhľadávacích relayov';

  @override
  String get userGroups => 'Skupiny používateľa';

  @override
  String get favoritesList => 'Zoznam obľúbených';

  @override
  String get privateEventsList => 'Zoznam súkromných udalostí';

  @override
  String get interestsList => 'Zoznam záujmov';

  @override
  String get mediaFollowsList => 'Zoznam sledovaných médií';

  @override
  String get peopleFollowsList => 'Zoznam sledovaných ľudí';

  @override
  String get userEmojiList => 'Zoznam emoji používateľa';

  @override
  String get dmRelayList => 'Zoznam DM relayov';

  @override
  String get keyPackageRelayList => 'Zoznam KeyPackage relayov';

  @override
  String get userServerList => 'Zoznam serverov používateľa';

  @override
  String get fileStorageServerList => 'Zoznam serverov na ukladanie súborov';

  @override
  String get relayMonitorAnnouncement => 'Oznámenie monitora relayov';

  @override
  String get roomPresence => 'Prítomnosť v miestnosti';

  @override
  String get proxyAnnouncement => 'Oznámenie proxy';

  @override
  String get transportMethodAnnouncement => 'Oznámenie spôsobu prenosu';

  @override
  String get walletInfo => 'Informácie o peňaženke';

  @override
  String get cashuWalletEvent => 'Udalosť Cashu peňaženky';

  @override
  String get lightningPubRpc => 'Lightning Pub RPC';

  @override
  String get clientAuthentication => 'Autentifikácia klienta';

  @override
  String get walletRequest => 'Žiadosť peňaženky';

  @override
  String get walletResponse => 'Odpoveď peňaženky';

  @override
  String get nostrConnectEvent => 'Nostr Connect';

  @override
  String get blobsStoredOnMediaservers => 'Bloby uložené na mediaserveroch';

  @override
  String get httpAuth => 'HTTP autentifikácia';

  @override
  String get categorizedPeopleList => 'Kategorizovaný zoznam ľudí';

  @override
  String get categorizedBookmarkList => 'Kategorizovaný zoznam záložiek';

  @override
  String get categorizedRelayList => 'Kategorizovaný zoznam relayov';

  @override
  String get bookmarkSets => 'Sady záložiek';

  @override
  String get curationSets => 'Kurátorské sady';

  @override
  String get videoSets => 'Sady videí';

  @override
  String get kindMuteSets => 'Sady stlmených kindov';

  @override
  String get profileBadges => 'Odznaky profilu';

  @override
  String get badgeDefinition => 'Definícia odznaku';

  @override
  String get interestSets => 'Sady záujmov';

  @override
  String get createOrUpdateStall => 'Vytvoriť alebo aktualizovať stánok';

  @override
  String get createOrUpdateProduct => 'Vytvoriť alebo aktualizovať produkt';

  @override
  String get marketplaceUiUx => 'UI/UX trhoviska';

  @override
  String get productSoldAsAuction => 'Produkt predávaný ako aukcia';

  @override
  String get longFormContent => 'Dlhoformátový obsah';

  @override
  String get draftLongFormContent => 'Koncept dlhoformátového obsahu';

  @override
  String get emojiSets => 'Sady emoji';

  @override
  String get curatedPublicationItem => 'Položka kurátorskej publikácie';

  @override
  String get curatedPublicationDraft => 'Koncept kurátorskej publikácie';

  @override
  String get releaseArtifactSets => 'Sady artefaktov vydania';

  @override
  String get applicationSpecificData => 'Dáta špecifické pre aplikáciu';

  @override
  String get relayDiscovery => 'Objavovanie relayov';

  @override
  String get appCurationSets => 'Kurátorské sady aplikácií';

  @override
  String get liveEvent => 'Živá udalosť';

  @override
  String get userStatus => 'Stav používateľa';

  @override
  String get slideSet => 'Sada snímok';

  @override
  String get classifiedListing => 'Inzerát';

  @override
  String get draftClassifiedListing => 'Koncept inzerátu';

  @override
  String get repositoryAnnouncement => 'Oznámenie repozitára';

  @override
  String get repositoryStateAnnouncement => 'Oznámenie stavu repozitára';

  @override
  String get wikiArticle => 'Wiki článok';

  @override
  String get redirects => 'Presmerovania';

  @override
  String get draftEvent => 'Koncept udalosti';

  @override
  String get linkSet => 'Sada odkazov';

  @override
  String get feed => 'Feed';

  @override
  String get dateBasedCalendarEvent => 'Kalendárová udalosť podľa dátumu';

  @override
  String get timeBasedCalendarEvent => 'Kalendárová udalosť podľa času';

  @override
  String get calendar => 'Kalendár';

  @override
  String get calendarEventRsvp => 'RSVP na kalendárovú udalosť';

  @override
  String get handlerRecommendation => 'Odporúčanie handlera';

  @override
  String get handlerInformation => 'Informácie o handleri';

  @override
  String get softwareApplication => 'Softvérová aplikácia';

  @override
  String get videoView => 'Zhliadnutie videa';

  @override
  String get communityDefinition => 'Definícia komunity';

  @override
  String get geocacheListing => 'Záznam geokešky';

  @override
  String get mintAnnouncement => 'Oznámenie mintu';

  @override
  String get mintQuote => 'Ponuka mintu';

  @override
  String get peerToPeerOrder => 'Peer-to-peer objednávka';

  @override
  String get groupMetadata => 'Metadáta skupiny';

  @override
  String get groupAdminMetadata => 'Metadáta administrátora skupiny';

  @override
  String get groupMemberMetadata => 'Metadáta člena skupiny';

  @override
  String get groupAdminsList => 'Zoznam administrátorov skupiny';

  @override
  String get groupMembersList => 'Zoznam členov skupiny';

  @override
  String get groupRoles => 'Roly skupiny';

  @override
  String get groupPermissions => 'Oprávnenia skupiny';

  @override
  String get groupChatMessage => 'Správa skupinového chatu';

  @override
  String get groupChatThread => 'Vlákno skupinového chatu';

  @override
  String get groupPinned => 'Pripnuté v skupine';

  @override
  String get starterPacks => 'Štartovacie balíčky';

  @override
  String get mediaStarterPacks => 'Mediálne štartovacie balíčky';

  @override
  String get webBookmarks => 'Webové záložky';

  @override
  String unknownEventKind(int kind) {
    return 'Druh udalosti $kind';
  }

  @override
  String get walletsTitle => 'Peňaženky';

  @override
  String get recentActivityTitle => 'Nedávna aktivita';

  @override
  String get addCashuWallet => 'Pridať Cashu peňaženku';

  @override
  String get addNwcWallet => 'Pridať NWC peňaženku';

  @override
  String get addLnurlWallet => 'Pridať LNURL peňaženku';

  @override
  String get addCashuTooltip => 'Pridať Cashu peňaženku';

  @override
  String get addNwcTooltip => 'Pridať NWC peňaženku';

  @override
  String get addLnurlTooltip => 'Pridať LNURL peňaženku';

  @override
  String get addCashuWalletTitle => 'Pridať Cashu peňaženku';

  @override
  String get enterMintUrl => 'Zadajte URL mintu na pridanie Cashu peňaženky.';

  @override
  String get mintUrl => 'URL mintu';

  @override
  String get mintUrlHint => 'https://mint.example.com';

  @override
  String get pleaseEnterMintUrl => 'Zadajte URL mintu';

  @override
  String get cashuWalletAdded => 'Cashu peňaženka bola úspešne pridaná!';

  @override
  String get failedToAddMint =>
      'Nepodarilo sa pridať mint. Skontrolujte URL a skúste to znova.';

  @override
  String get addNwcWalletTitle => 'Pridať NWC peňaženku';

  @override
  String get faucet => 'Faucet';

  @override
  String get manual => 'Manuálne';

  @override
  String get nwcFaucetDescription =>
      'Vytvorte testovaciu peňaženku so satmi z NWC faucetu.';

  @override
  String get startingBalance => 'Počiatočný zostatok';

  @override
  String get startingBalanceHint => '10000';

  @override
  String get nwcConnectionUri => 'URI pripojenia NWC';

  @override
  String get nwcConnectionUriHint => 'nostr+walletconnect://...';

  @override
  String get nwcWalletAdded => 'NWC peňaženka bola úspešne pridaná!';

  @override
  String nwcFaucetWalletAdded(int balance) {
    return 'NWC faucet peňaženka pridaná s $balance satmi!';
  }

  @override
  String get invalidFaucetResponse => 'Neplatná odpoveď z faucetu';

  @override
  String get errorCreatingWallet => 'Chyba pri vytváraní peňaženky';

  @override
  String get addLnurlWalletTitle => 'Pridať LNURL peňaženku';

  @override
  String get enterLnurlIdentifier =>
      'Zadajte svoj LNURL identifikátor (user@domain.com).';

  @override
  String get lnurlIdentifierHint => 'user@example.com';

  @override
  String get pleaseEnterValidIdentifier =>
      'Zadajte platný identifikátor (user@domain.com)';

  @override
  String get lnurlWalletAdded => 'LNURL peňaženka bola úspešne pridaná!';

  @override
  String get cancel => 'Zrušiť';

  @override
  String get add => 'Pridať';

  @override
  String get send => 'Odoslať';

  @override
  String get receive => 'Prijať';

  @override
  String get setAsDefaultForReceiving =>
      'Nastaviť ako predvolenú na prijímanie';

  @override
  String get setAsDefaultForSending => 'Nastaviť ako predvolenú na odosielanie';

  @override
  String get defaultForReceiving => 'Predvolená na prijímanie';

  @override
  String get defaultForSending => 'Predvolená na odosielanie';

  @override
  String get defaultWalletForReceivingTooltip =>
      'Táto peňaženka je predvolená na prijímanie platieb.';

  @override
  String get defaultWalletForSendingTooltip =>
      'Táto peňaženka je predvolená na odosielanie platieb.';

  @override
  String get sendOptionsTitle => 'Možnosti odoslania';

  @override
  String get sendByToken => 'Odoslať tokenom';

  @override
  String get sendByTokenDescription => 'Vytvoriť Cashu token na odoslanie';

  @override
  String get sendByLightning => 'Odoslať cez Lightning';

  @override
  String get sendByLightningDescription => 'Zaplatiť Lightning faktúru';

  @override
  String get payInvoiceTitle => 'Zaplatiť faktúru';

  @override
  String get invoice => 'Faktúra';

  @override
  String get invoiceHint => 'lnbc...';

  @override
  String get pleaseEnterInvoice => 'Zadajte faktúru';

  @override
  String get invoicePaid => 'Faktúra zaplatená!';

  @override
  String paymentFailed(String message) {
    return 'Platba zlyhala: $message';
  }

  @override
  String get receiveOptionsTitle => 'Možnosti prijatia';

  @override
  String get receiveByToken => 'Prijať tokenom';

  @override
  String get receiveByTokenDescription => 'Prijať Cashu token';

  @override
  String get receiveByLightning => 'Prijať cez Lightning';

  @override
  String get receiveByLightningDescription => 'Vytvoriť Lightning faktúru';

  @override
  String get receiveByTokenTitle => 'Prijať tokenom';

  @override
  String get token => 'Token';

  @override
  String get tokenHint => 'Sem vložte token...';

  @override
  String get pleaseEnterToken => 'Zadajte token';

  @override
  String get tokenReceived => 'Token prijatý!';

  @override
  String get createInvoiceTitle => 'Vytvoriť faktúru';

  @override
  String get amount => 'Suma';

  @override
  String get amountHint => '100';

  @override
  String get pleaseEnterValidAmount => 'Zadajte platnú sumu';

  @override
  String get tokenCopiedToClipboard => 'Token skopírovaný do schránky!';

  @override
  String get invoiceCreatedAndCopied => 'Faktúra vytvorená a skopírovaná!';

  @override
  String get invoiceTrackingTitle => 'Lightning faktúra';

  @override
  String get invoiceCreatedMessage => 'Faktúra vytvorená a skopírovaná!';

  @override
  String get close => 'Zavrieť';

  @override
  String get copyAgain => 'Kopírovať znova';

  @override
  String get copied => 'Skopírované!';

  @override
  String get paymentReceived => 'Platba prijatá!';

  @override
  String get waitingForPayment => 'Čaká sa na platbu...';

  @override
  String get paid => 'Zaplatené!';

  @override
  String get createToken => 'Vytvoriť token';

  @override
  String get pay => 'Zaplatiť';

  @override
  String get create => 'Vytvoriť';

  @override
  String get pendingTransactions => 'Čakajúce';

  @override
  String get backupSeedWarning => 'Zálohujte si frázu na obnovenie Cashu';

  @override
  String get backupSeedTitle => 'Zálohovať frázu na obnovenie Cashu';

  @override
  String get backupSeedInstructions =>
      'Zapíšte si tieto slová v uvedenom poradí a uložte ich na bezpečné miesto. Sú jediným spôsobom, ako obnoviť vaše Cashu prostriedky pri strate tohto zariadenia.';

  @override
  String get backupSeedConfirm =>
      'Zapísal(a) som si frázu na obnovenie a bezpečne som ju uložil(a)';

  @override
  String get backupSeedDone => 'Mám ju zálohovanú';

  @override
  String get reclaimPendingFunds => 'Získať späť čakajúce prostriedky';

  @override
  String get reclaimPendingTitle => 'Získať späť čakajúce prostriedky';

  @override
  String get recentTransactions => 'Nedávne transakcie';

  @override
  String get noRecentTransactions => 'Žiadne nedávne transakcie';

  @override
  String get noWalletsYet => 'Zatiaľ žiadne peňaženky';

  @override
  String get noWalletsAvailable => 'Žiadne dostupné peňaženky';

  @override
  String get tapToAddWallet => 'Ťuknite na + a pridajte peňaženku';

  @override
  String get delete => 'Vymazať';

  @override
  String error(String message) {
    return 'Chyba: $message';
  }

  @override
  String get unknownWalletType => 'Neznáma';

  @override
  String get cashuWallet => 'Cashu';

  @override
  String get nwcWallet => 'NWC';

  @override
  String get lnurlWallet => 'LNURL';

  @override
  String get nwcWalletSubtitle => 'NWC peňaženka';

  @override
  String get balance => 'Zostatok';

  @override
  String get sats => 'sats';

  @override
  String get selected => 'VYBRANÁ';

  @override
  String get receiveOnlyWallet => 'Peňaženka len na prijímanie';

  @override
  String receiveRange(int min, int max) {
    return 'Prijímanie: $min - $max sats';
  }

  @override
  String get limitsUnavailable => 'Limity nedostupné';

  @override
  String get tokenCopied => 'Token skopírovaný';

  @override
  String get deleteWalletConfirmation => 'Vymazať peňaženku?';

  @override
  String get deleteWalletConfirmationMessage =>
      'Naozaj chcete vymazať túto peňaženku? Túto akciu nie je možné vrátiť späť.';

  @override
  String get addWalletTitle => 'Pridať peňaženku';

  @override
  String get chooseWalletType => 'Vyberte typ peňaženky';

  @override
  String get nwcWalletTypeTitle => 'Nostr Wallet Connect';

  @override
  String get nwcWalletTypeSubtitle => 'Pripojiť vzdialenú peňaženku cez NWC';

  @override
  String get lnurlWalletTypeTitle => 'Lightning adresa (LNURL)';

  @override
  String get lnurlWalletTypeSubtitle =>
      'Použiť Lightning adresu (LNURL) len na prijímanie';

  @override
  String get cashuWalletTypeTitle => 'Cashu';

  @override
  String get cashuWalletTypeSubtitle =>
      'Použiť ecash peňaženku podporovanú Cashu mintom';

  @override
  String get cashuOption => 'Cashu';

  @override
  String get nwcOption => 'NWC';

  @override
  String get lnurlOption => 'LNURL';

  @override
  String get connectNwcTitle => 'Pripojiť NWC';

  @override
  String get chooseNwcMethod => 'Vyberte spôsob pripojenia';

  @override
  String get albyGoOption => 'Alby Go';

  @override
  String get manualOption => 'Manuálne';

  @override
  String get faucetOption => 'Faucet';

  @override
  String get invalidNwcQrCode => 'Neplatný NWC QR kód';

  @override
  String get scanNwcQrCodeTitle => 'Naskenovať NWC QR kód';

  @override
  String get cameraNotAvailable => 'Kamera nie je dostupná';

  @override
  String get scanNwcInstructions =>
      'Naskenujte QR kód z vašej NWC peňaženkovej aplikácie';

  @override
  String get invalidNwcUri => 'Neplatné NWC URI';

  @override
  String get paste => 'Vložiť';

  @override
  String get fromYourProfile => 'Z vášho profilu';

  @override
  String get orEnterManually => 'Alebo zadajte manuálne:';

  @override
  String get renameWallet => 'Premenovať';

  @override
  String get pickColor => 'Vybrať farbu';

  @override
  String get deleteWallet => 'Vymazať';

  @override
  String get walletName => 'Názov peňaženky';

  @override
  String get walletNameHint => 'Zadajte názov peňaženky';

  @override
  String get save => 'Uložiť';

  @override
  String get walletRenamed => 'Peňaženka premenovaná';

  @override
  String budgetUsedOf(int used, int total) {
    final intl.NumberFormat usedNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String usedString = usedNumberFormat.format(used);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return 'Rozpočet: $usedString / $totalString';
  }

  @override
  String budgetRenewsIn(int days) {
    return 'Obnoví sa o $days dní';
  }

  @override
  String get budgetDaily => 'Denne';

  @override
  String get budgetWeekly => 'Týždenne';

  @override
  String get budgetMonthly => 'Mesačne';

  @override
  String get budgetYearly => 'Ročne';

  @override
  String get budgetNever => 'Nikdy';

  @override
  String get backup => 'Zálohovať';

  @override
  String get restore => 'Obnoviť';

  @override
  String get cashuBackupTitle => 'Cashu záloha';

  @override
  String get cashuBackupWarning =>
      'Táto záloha obsahuje vaše ecash dôkazy, ktoré sú prostriedkami na doručiteľa. Udržujte ju v súkromí a uložte na bezpečné miesto. Vaša seed fráza sa zálohuje samostatne.';

  @override
  String get generatingBackup => 'Generuje sa záloha...';

  @override
  String get copyBackup => 'Kopírovať zálohu';

  @override
  String get backupCopiedToClipboard => 'Záloha skopírovaná do schránky';

  @override
  String get cashuRestoreTitle => 'Obnoviť Cashu zálohu';

  @override
  String get backupJson => 'JSON zálohy';

  @override
  String get backupJsonHint => 'Sem vložte JSON zálohy';

  @override
  String get pleaseEnterBackup => 'Zadajte zálohu';

  @override
  String get restoringBackup => 'Obnovuje sa záloha...';

  @override
  String restoreSuccess(int count) {
    return 'Obnovených $count dôkazov zo zálohy';
  }
}
