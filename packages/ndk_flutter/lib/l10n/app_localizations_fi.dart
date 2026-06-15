// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Finnish (`fi`).
class AppLocalizationsFi extends AppLocalizations {
  AppLocalizationsFi([String locale = 'fi']) : super(locale);

  @override
  String get createAccount => 'Luo tili';

  @override
  String get newHere => 'Oletko uusi täällä?';

  @override
  String get nostrAddress => 'Nostr-osoite';

  @override
  String get publicKey => 'Julkinen avain';

  @override
  String get privateKey => 'Yksityinen avain (turvaton)';

  @override
  String get browserExtension => 'Selainlaajennus';

  @override
  String get connect => 'Yhdistä';

  @override
  String get install => 'Asenna';

  @override
  String get logout => 'Kirjaudu ulos';

  @override
  String get nostrAddressHint => 'nimi@esimerkki.com';

  @override
  String get invalidAddress => 'Virheellinen osoite';

  @override
  String get unableToConnect => 'Yhdistäminen epäonnistui';

  @override
  String get publicKeyHint => 'npub1...';

  @override
  String get privateKeyHint => 'nsec1...';

  @override
  String get newToNostr => 'Uusi Nostrissa?';

  @override
  String get getStarted => 'Aloita';

  @override
  String get bunker => 'Bunkkeri';

  @override
  String get bunkerAuthentication => 'Bunkkeri-todennus';

  @override
  String tapToOpen(String url) {
    return 'Avaa napauttamalla: $url';
  }

  @override
  String get showNostrConnectQrcode => 'Näytä Nostr Connect -QR-koodi';

  @override
  String get loginWithSignerApp => 'Kirjaudu allekirjoitussovelluksella';

  @override
  String get nostrConnectUrl => 'Nostr Connect -URL';

  @override
  String get copy => 'Kopioi';

  @override
  String get addAccount => 'Lisää tili';

  @override
  String get readOnly => 'Vain luku';

  @override
  String get nsec => 'Nsec';

  @override
  String get extension => 'Laajennus';

  @override
  String get userMetadata => 'Käyttäjän metatiedot';

  @override
  String get shortTextNote => 'Lyhyt tekstiviesti';

  @override
  String get recommendRelay => 'Suosittele välittäjää';

  @override
  String get follows => 'Seuraa';

  @override
  String get encryptedDirectMessages => 'Salatut suorat viestit';

  @override
  String get eventDeletionRequest => 'Tapahtuman poistopyyntö';

  @override
  String get repost => 'Uudelleenjulkaisu';

  @override
  String get reaction => 'Reaktio';

  @override
  String get badgeAward => 'Merkkipalkinto';

  @override
  String get chatMessage => 'Chat-viesti';

  @override
  String get groupChatThreadedReply => 'Ryhmächatin ketjutettu vastaus';

  @override
  String get thread => 'Ketju';

  @override
  String get groupThreadReply => 'Ryhmän ketjuvastaus';

  @override
  String get seal => 'Sinetti';

  @override
  String get directMessage => 'Suora viesti';

  @override
  String get fileMessage => 'Tiedostoviesti';

  @override
  String get genericRepost => 'Yleinen uudelleenjulkaisu';

  @override
  String get reactionToWebsite => 'Reaktio verkkosivustoon';

  @override
  String get picture => 'Kuva';

  @override
  String get videoEvent => 'Videotapahtuma';

  @override
  String get shortFormPortraitVideoEvent => 'Lyhyt pystyvideotapahtuma';

  @override
  String get internalReference => 'Sisäinen viite';

  @override
  String get externalReference => 'Ulkoinen viite';

  @override
  String get hardcopyReference => 'Paperinen viite';

  @override
  String get promptReference => 'Kehoteviite';

  @override
  String get channelCreation => 'Kanavan luonti';

  @override
  String get channelMetadata => 'Kanavan metatiedot';

  @override
  String get channelMessage => 'Kanavaviesti';

  @override
  String get channelHideMessage => 'Kanavan piilota viesti';

  @override
  String get channelMuteUser => 'Kanavan mykistä käyttäjä';

  @override
  String get requestToVanish => 'Pyyntö hävitä';

  @override
  String get chessPgn => 'Shakki (PGN)';

  @override
  String get mlsKeyPackage => 'MLS KeyPackage';

  @override
  String get mlsWelcome => 'MLS Welcome';

  @override
  String get mlsGroupEvent => 'MLS Group Event';

  @override
  String get mergeRequests => 'Yhdistämispyynnöt';

  @override
  String get pollResponse => 'Äänestyksen vastaus';

  @override
  String get marketplaceBid => 'Markkinapaikan tarjous';

  @override
  String get marketplaceBidConfirmation => 'Markkinapaikan tarjousvahvistus';

  @override
  String get openTimestamps => 'OpenTimestamps';

  @override
  String get giftWrap => 'Lahjapaketti';

  @override
  String get fileMetadata => 'Tiedoston metatiedot';

  @override
  String get poll => 'Äänestys';

  @override
  String get comment => 'Kommentti';

  @override
  String get voiceMessage => 'Ääniviesti';

  @override
  String get voiceMessageComment => 'Ääniviestikommentti';

  @override
  String get liveChatMessage => 'Live-chat-viesti';

  @override
  String get codeSnippet => 'Koodinpätkä';

  @override
  String get gitPatch => 'Git-korjaus';

  @override
  String get gitPullRequest => 'Git Pull Request';

  @override
  String get gitStatusUpdate => 'Git-tilapäivitys';

  @override
  String get gitIssue => 'Git-ongelma';

  @override
  String get gitIssueUpdate => 'Git-ongelman päivitys';

  @override
  String get status => 'Tila';

  @override
  String get statusUpdate => 'Tilapäivitys';

  @override
  String get statusDelete => 'Tilan poisto';

  @override
  String get statusReply => 'Tilavastaus';

  @override
  String get problemTracker => 'Ongelmanseuranta';

  @override
  String get reporting => 'Raportointi';

  @override
  String get label => 'Tarra';

  @override
  String get relayReviews => 'Välittäjäarvostelut';

  @override
  String get aiEmbeddings => 'AI-sulautukset / vektoriluettelot';

  @override
  String get torrent => 'Torrent';

  @override
  String get torrentComment => 'Torrent-kommentti';

  @override
  String get coinjoinPool => 'Coinjoin-pooli';

  @override
  String get communityPostApproval => 'Yhteisön julkaisun hyväksyntä';

  @override
  String get jobRequest => 'Työpyyntö';

  @override
  String get jobResult => 'Työn tulos';

  @override
  String get jobFeedback => 'Työpalaute';

  @override
  String get cashuWalletToken => 'Cashu-lompakkovarmenteet';

  @override
  String get cashuWalletProofs => 'Cashu-lompakontodistukset';

  @override
  String get cashuWalletHistory => 'Cashu-lompakon historia';

  @override
  String get geocacheCreate => 'Geocachen luonti';

  @override
  String get geocacheUpdate => 'Geocachen päivitys';

  @override
  String get groupControlEvent => 'Ryhmän hallintatapahtuma';

  @override
  String get zapGoal => 'Zap-tavoite';

  @override
  String get nutzap => 'Nutzap';

  @override
  String get tidalLogin => 'Tidal-kirjautuminen';

  @override
  String get zapRequest => 'Zap-pyyntö';

  @override
  String get zap => 'Zap';

  @override
  String get highlights => 'Kohokohdat';

  @override
  String get muteList => 'Mykistysluettelo';

  @override
  String get pinList => 'Kiinnitysluettelo';

  @override
  String get relayListMetadata => 'Välittäjäluettelon metatiedot';

  @override
  String get bookmarkList => 'Kirjanmerkkiluettelo';

  @override
  String get communitiesList => 'Yhteisöluettelo';

  @override
  String get publicChatsList => 'Julkisten chatien luettelo';

  @override
  String get blockedRelaysList => 'Estettyjen välittäjien luettelo';

  @override
  String get searchRelaysList => 'Hakuvälittäjien luettelo';

  @override
  String get userGroups => 'Käyttäjäryhmät';

  @override
  String get favoritesList => 'Suosikkiluettelo';

  @override
  String get privateEventsList => 'Yksityisten tapahtumien luettelo';

  @override
  String get interestsList => 'Kiinnostusluettelo';

  @override
  String get mediaFollowsList => 'Median seurantalista';

  @override
  String get peopleFollowsList => 'Henkilöiden seurantalista';

  @override
  String get userEmojiList => 'Käyttäjän emojiluettelo';

  @override
  String get dmRelayList => 'DM-välittäjäluettelo';

  @override
  String get keyPackageRelayList => 'KeyPackage-välittäjäluettelo';

  @override
  String get userServerList => 'Käyttäjäpalvelinluettelo';

  @override
  String get fileStorageServerList => 'Tiedostotallennuspalvelinluettelo';

  @override
  String get relayMonitorAnnouncement => 'Välittäjänvalvojan ilmoitus';

  @override
  String get roomPresence => 'Huoneen läsnäolo';

  @override
  String get proxyAnnouncement => 'Välityspalvelimen ilmoitus';

  @override
  String get transportMethodAnnouncement => 'Kuljetustavan ilmoitus';

  @override
  String get walletInfo => 'Lompakon tiedot';

  @override
  String get cashuWalletEvent => 'Cashu-lompakotapahtuma';

  @override
  String get lightningPubRpc => 'Lightning Pub RPC';

  @override
  String get clientAuthentication => 'Asiakkaan todennus';

  @override
  String get walletRequest => 'Lompakkopyyntö';

  @override
  String get walletResponse => 'Lompakon vastaus';

  @override
  String get nostrConnectEvent => 'Nostr Connect';

  @override
  String get blobsStoredOnMediaservers =>
      'Mediapalvelimille tallennetut blobit';

  @override
  String get httpAuth => 'HTTP-todennus';

  @override
  String get categorizedPeopleList => 'Luokiteltu henkilöluettelo';

  @override
  String get categorizedBookmarkList => 'Luokiteltu kirjanmerkkiluettelo';

  @override
  String get categorizedRelayList => 'Luokiteltu välittäjäluettelo';

  @override
  String get bookmarkSets => 'Kirjanmerkkisarjat';

  @override
  String get curationSets => 'Kuraattorisarjat';

  @override
  String get videoSets => 'Videosarjat';

  @override
  String get kindMuteSets => 'Tyyppimykistysjoukot';

  @override
  String get profileBadges => 'Profiilimerkit';

  @override
  String get badgeDefinition => 'Merkkien määritelmä';

  @override
  String get interestSets => 'Kiinnostussarjat';

  @override
  String get createOrUpdateStall => 'Luo tai päivitä koju';

  @override
  String get createOrUpdateProduct => 'Luo tai päivitä tuote';

  @override
  String get marketplaceUiUx => 'Markkinapaikan UI/UX';

  @override
  String get productSoldAsAuction => 'Tuote myyty huutokaupassa';

  @override
  String get longFormContent => 'Pitkämuotoinen sisältö';

  @override
  String get draftLongFormContent => 'Pitkämuotoisen sisällön luonnos';

  @override
  String get emojiSets => 'Emojisarjat';

  @override
  String get curatedPublicationItem => 'Kuraattorin julkaisu';

  @override
  String get curatedPublicationDraft => 'Kuraattorin julkaisuluonnos';

  @override
  String get releaseArtifactSets => 'Julkaisuartifacttisarjat';

  @override
  String get applicationSpecificData => 'Sovelluskohtaiset tiedot';

  @override
  String get relayDiscovery => 'Välittäjän löytäminen';

  @override
  String get appCurationSets => 'Sovelluskuraattorisarjat';

  @override
  String get liveEvent => 'Live-tapahtuma';

  @override
  String get userStatus => 'Käyttäjän tila';

  @override
  String get slideSet => 'Diasarja';

  @override
  String get classifiedListing => 'Luokiteltu ilmoitus';

  @override
  String get draftClassifiedListing => 'Luokitellun ilmoituksen luonnos';

  @override
  String get repositoryAnnouncement => 'Varaston ilmoitus';

  @override
  String get repositoryStateAnnouncement => 'Varaston tilan ilmoitus';

  @override
  String get wikiArticle => 'Wiki-artikkeli';

  @override
  String get redirects => 'Uudelleenohjaukset';

  @override
  String get draftEvent => 'Luonnostapahtuma';

  @override
  String get linkSet => 'Linkkisarja';

  @override
  String get feed => 'Syöte';

  @override
  String get dateBasedCalendarEvent =>
      'Päivämäärään perustuva kalenteritapahtuma';

  @override
  String get timeBasedCalendarEvent => 'Aikaan perustuva kalenteritapahtuma';

  @override
  String get calendar => 'Kalenteri';

  @override
  String get calendarEventRsvp => 'Kalenteritapahtuman RSVP';

  @override
  String get handlerRecommendation => 'Käsittelijän suositus';

  @override
  String get handlerInformation => 'Käsittelijän tiedot';

  @override
  String get softwareApplication => 'Sovellus';

  @override
  String get videoView => 'Videonäkymä';

  @override
  String get communityDefinition => 'Yhteisön määritelmä';

  @override
  String get geocacheListing => 'Geocache-luettelo';

  @override
  String get mintAnnouncement => 'Mint-ilmoitus';

  @override
  String get mintQuote => 'Mint-tarjous';

  @override
  String get peerToPeerOrder => 'Vertaisverkkotilaus';

  @override
  String get groupMetadata => 'Ryhmän metatiedot';

  @override
  String get groupAdminMetadata => 'Ryhmän ylläpitäjän metatiedot';

  @override
  String get groupMemberMetadata => 'Ryhmän jäsenen metatiedot';

  @override
  String get groupAdminsList => 'Ryhmän ylläpitäjien luettelo';

  @override
  String get groupMembersList => 'Ryhmän jäsenluettelo';

  @override
  String get groupRoles => 'Ryhmän roolit';

  @override
  String get groupPermissions => 'Ryhmän oikeudet';

  @override
  String get groupChatMessage => 'Ryhmän chat-viesti';

  @override
  String get groupChatThread => 'Ryhmän chat-ketju';

  @override
  String get groupPinned => 'Ryhmän kiinnitetty';

  @override
  String get starterPacks => 'Aloituspaketit';

  @override
  String get mediaStarterPacks => 'Media-aloituspaketit';

  @override
  String get webBookmarks => 'Verkkokirjanmerkit';

  @override
  String unknownEventKind(int kind) {
    return 'Tapahtumatyyppi $kind';
  }

  @override
  String get walletsTitle => 'Lompakot';

  @override
  String get recentActivityTitle => 'Viimeaikainen toiminta';

  @override
  String get addCashuWallet => 'Lisää Cashu-lompakko';

  @override
  String get addNwcWallet => 'Lisää NWC-lompakko';

  @override
  String get addLnurlWallet => 'Lisää LNURL-lompakko';

  @override
  String get addCashuTooltip => 'Lisää Cashu-lompakko';

  @override
  String get addNwcTooltip => 'Lisää NWC-lompakko';

  @override
  String get addLnurlTooltip => 'Lisää LNURL-lompakko';

  @override
  String get addCashuWalletTitle => 'Lisää Cashu-lompakko';

  @override
  String get enterMintUrl => 'Anna mint URL lisätäksesi Cashu-lompakon.';

  @override
  String get mintUrl => 'Mint URL';

  @override
  String get mintUrlHint => 'https://mint.example.com';

  @override
  String get pleaseEnterMintUrl => 'Anna mint URL';

  @override
  String get cashuWalletAdded => 'Cashu-lompakko lisätty onnistuneesti!';

  @override
  String get failedToAddMint =>
      'Mintin lisääminen epäonnistui. Tarkista URL ja yritä uudelleen.';

  @override
  String get addNwcWalletTitle => 'Lisää NWC-lompakko';

  @override
  String get faucet => 'Hana';

  @override
  String get manual => 'Manuaalinen';

  @override
  String get nwcFaucetDescription => 'Luo testilompakko satseilla NWC-hanasta.';

  @override
  String get startingBalance => 'Aloitussaldo';

  @override
  String get startingBalanceHint => '10000';

  @override
  String get nwcConnectionUri => 'NWC-yhteys-URI';

  @override
  String get nwcConnectionUriHint => 'nostr+walletconnect://...';

  @override
  String get nwcWalletAdded => 'NWC-lompakko lisätty onnistuneesti!';

  @override
  String nwcFaucetWalletAdded(int balance) {
    return 'NWC-hanalompakko lisätty $balance satilla!';
  }

  @override
  String get invalidFaucetResponse => 'Virheellinen vastaus hanasta';

  @override
  String get errorCreatingWallet => 'Virhe lompakon luomisessa';

  @override
  String get addLnurlWalletTitle => 'Lisää LNURL-lompakko';

  @override
  String get enterLnurlIdentifier =>
      'Anna LNURL-tunnisteesi (kayttaja@domain.com).';

  @override
  String get lnurlIdentifierHint => 'kayttaja@esimerkki.com';

  @override
  String get pleaseEnterValidIdentifier =>
      'Anna kelvollinen tunniste (kayttaja@domain.com)';

  @override
  String get lnurlWalletAdded => 'LNURL-lompakko lisätty onnistuneesti!';

  @override
  String get cancel => 'Peruuta';

  @override
  String get add => 'Lisää';

  @override
  String get send => 'Lähetä';

  @override
  String get receive => 'Vastaanota';

  @override
  String get setAsDefaultForReceiving => 'Aseta oletukseksi vastaanottamiseen';

  @override
  String get setAsDefaultForSending => 'Aseta oletukseksi lähettämiseen';

  @override
  String get defaultForReceiving => 'Oletus vastaanottamiseen';

  @override
  String get defaultForSending => 'Oletus lähettämiseen';

  @override
  String get defaultWalletForReceivingTooltip =>
      'Tämä lompakko on oletus vastaanottaessa maksuja.';

  @override
  String get defaultWalletForSendingTooltip =>
      'Tämä lompakko on oletus lähettäessä maksuja.';

  @override
  String get sendOptionsTitle => 'Lähetysvaihtoehdot';

  @override
  String get sendByToken => 'Lähetä tokenilla';

  @override
  String get sendByTokenDescription => 'Luo Cashu-token lähettääksesi';

  @override
  String get sendByLightning => 'Lähetä Lightningilla';

  @override
  String get sendByLightningDescription => 'Maksa Lightning-lasku';

  @override
  String get payInvoiceTitle => 'Maksa lasku';

  @override
  String get invoice => 'Lasku';

  @override
  String get invoiceHint => 'lnbc...';

  @override
  String get pleaseEnterInvoice => 'Anna lasku';

  @override
  String get invoicePaid => 'Lasku maksettu!';

  @override
  String paymentFailed(String message) {
    return 'Maksu epäonnistui: $message';
  }

  @override
  String get receiveOptionsTitle => 'Vastaanottovaihtoehdot';

  @override
  String get receiveByToken => 'Vastaanota tokenilla';

  @override
  String get receiveByTokenDescription => 'Vastaanota Cashu-token';

  @override
  String get receiveByLightning => 'Vastaanota Lightningilla';

  @override
  String get receiveByLightningDescription => 'Luo Lightning-lasku';

  @override
  String get receiveByTokenTitle => 'Vastaanota tokenilla';

  @override
  String get token => 'Token';

  @override
  String get tokenHint => 'Liitä token tähän...';

  @override
  String get pleaseEnterToken => 'Anna token';

  @override
  String get tokenReceived => 'Token vastaanotettu!';

  @override
  String get createInvoiceTitle => 'Luo lasku';

  @override
  String get amount => 'Määrä';

  @override
  String get amountHint => '100';

  @override
  String get pleaseEnterValidAmount => 'Anna kelvollinen määrä';

  @override
  String get tokenCopiedToClipboard => 'Token kopioitu leikepöydälle!';

  @override
  String get invoiceCreatedAndCopied => 'Lasku luotu ja kopioitu!';

  @override
  String get invoiceTrackingTitle => 'Lightning-lasku';

  @override
  String get invoiceCreatedMessage => 'Lasku luotu ja kopioitu!';

  @override
  String get close => 'Sulje';

  @override
  String get copyAgain => 'Kopioi uudelleen';

  @override
  String get copied => 'Kopioitu!';

  @override
  String get paymentReceived => 'Maksu vastaanotettu!';

  @override
  String get waitingForPayment => 'Odotetaan maksua...';

  @override
  String get paid => 'Maksettu!';

  @override
  String get createToken => 'Luo token';

  @override
  String get pay => 'Maksa';

  @override
  String get create => 'Luo';

  @override
  String get pendingTransactions => 'Odottaa';

  @override
  String get recentTransactions => 'Viimeaikaiset tapahtumat';

  @override
  String get noRecentTransactions => 'Ei viimeaikaisia tapahtumia';

  @override
  String get noWalletsYet => 'Ei lompakoita vielä';

  @override
  String get noWalletsAvailable => 'Ei lompakoita saatavilla';

  @override
  String get tapToAddWallet => 'Napauta + lisätäksesi';

  @override
  String get delete => 'Poista';

  @override
  String error(String message) {
    return 'Virhe: $message';
  }

  @override
  String get unknownWalletType => 'Tuntematon';

  @override
  String get cashuWallet => 'Cashu';

  @override
  String get nwcWallet => 'NWC';

  @override
  String get lnurlWallet => 'LNURL';

  @override
  String get nwcWalletSubtitle => 'NWC-lompakko';

  @override
  String get balance => 'Saldo';

  @override
  String get sats => 'sats';

  @override
  String get selected => 'VALITTU';

  @override
  String get receiveOnlyWallet => 'Vastaanottava lompakko';

  @override
  String receiveRange(int min, int max) {
    return 'Vastaanota: $min - $max sats';
  }

  @override
  String get limitsUnavailable => 'Rajat eivät saatavilla';

  @override
  String get tokenCopied => 'Token kopioitu';

  @override
  String get deleteWalletConfirmation => 'Poista lompakko?';

  @override
  String get deleteWalletConfirmationMessage =>
      'Oletko varma, että haluat poistaa tämän lompakon? Tätä toimintoa ei voi kumota.';

  @override
  String get addWalletTitle => 'Lisää lompakko';

  @override
  String get chooseWalletType => 'Valitse lompakon tyyppi';

  @override
  String get nwcWalletTypeTitle => 'Nostr Wallet Connect';

  @override
  String get nwcWalletTypeSubtitle => 'Yhdistä etälompakkoon NWC:llä';

  @override
  String get lnurlWalletTypeTitle => 'LNURL / Lightning-osoite';

  @override
  String get lnurlWalletTypeSubtitle =>
      'Käytä hallinnoitua lompakkoa LNURL:llä tai Lightning-osoitteella';

  @override
  String get cashuWalletTypeTitle => 'Cashu';

  @override
  String get cashuWalletTypeSubtitle =>
      'Käytä ecash-lompakkoa Cashu-mintin tukemana';

  @override
  String get cashuOption => 'Cashu';

  @override
  String get nwcOption => 'NWC';

  @override
  String get lnurlOption => 'LNURL';

  @override
  String get connectNwcTitle => 'Yhdistä NWC';

  @override
  String get chooseNwcMethod => 'Valitse yhteystapa';

  @override
  String get albyGoOption => 'Alby Go';

  @override
  String get manualOption => 'Manuaalinen';

  @override
  String get faucetOption => 'Hana';

  @override
  String get invalidNwcQrCode => 'Virheellinen NWC QR-koodi';

  @override
  String get scanNwcQrCodeTitle => 'Skannaa NWC QR-koodi';

  @override
  String get cameraNotAvailable => 'Kamera ei saatavilla';

  @override
  String get scanNwcInstructions =>
      'Skannaa QR-koodi NWC-lompakkosovelluksestasi';

  @override
  String get invalidNwcUri => 'Virheellinen NWC URI';

  @override
  String get paste => 'Liitä';

  @override
  String get fromYourProfile => 'Profiilistasi';

  @override
  String get orEnterManually => 'Tai syötä manuaalisesti:';

  @override
  String get renameWallet => 'Nimeä uudelleen';

  @override
  String get pickColor => 'Valitse väri';

  @override
  String get deleteWallet => 'Poista';

  @override
  String get walletName => 'Lompakon nimi';

  @override
  String get walletNameHint => 'Syötä lompakon nimi';

  @override
  String get save => 'Tallenna';

  @override
  String get walletRenamed => 'Lompakko nimetty uudelleen';

  @override
  String budgetUsedOf(int used, int total) {
    final intl.NumberFormat usedNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String usedString = usedNumberFormat.format(used);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return 'Budjetti: $usedString / $totalString';
  }

  @override
  String budgetRenewsIn(int days) {
    return 'Uusii $days päivän kuluttua';
  }

  @override
  String get budgetDaily => 'Päivittäin';

  @override
  String get budgetWeekly => 'Viikoittain';

  @override
  String get budgetMonthly => 'Kuukausittain';

  @override
  String get budgetYearly => 'Vuosittain';

  @override
  String get budgetNever => 'Ei koskaan';
}
