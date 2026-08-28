// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'sample_app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class SampleAppLocalizationsIt extends SampleAppLocalizations {
  SampleAppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get appName => 'Demo di Nostr Developer Kit';

  @override
  String get appBarTitle => 'Demo NDK';

  @override
  String get tabAccounts => 'Account';

  @override
  String get tabProfile => 'Profilo';

  @override
  String get tabRelays => 'Relay';

  @override
  String get tabBlossom => 'Blossom';

  @override
  String get tabWallets => 'Wallet';

  @override
  String get tabWidgets => 'Widget';

  @override
  String get profileTooltip => 'Profilo';

  @override
  String get loginDialogDefaultTitle => 'Accedi';

  @override
  String get loginDialogAddAccountTitle => 'Aggiungi account';

  @override
  String get closeTooltip => 'Chiudi';

  @override
  String get accountsHeading => 'Account';

  @override
  String get accountsDescription =>
      'Gestisci gli account connessi e aggiungine di nuovi.';

  @override
  String get addAnotherAccount => 'Aggiungi un altro account';

  @override
  String get logIn => 'Accedi';

  @override
  String get profileNoAccount => 'Nessun account connesso.';

  @override
  String get profileAbout => 'Informazioni';

  @override
  String profileMetadataError(Object error) {
    return 'Errore durante il recupero dei metadati: $error';
  }

  @override
  String get relaysLoginRequired => 'Accedi per vedere la tua lista di relay.';

  @override
  String get relaysFetchButton => 'Recupera la lista dei relay';

  @override
  String get relayListHeading => 'Lista dei relay';

  @override
  String relayConfiguredCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count relay configurati',
      one: '$count relay configurato',
    );
    return '$_temp0';
  }

  @override
  String relayConnection(Object state) {
    return 'Connessione: $state';
  }

  @override
  String get relayRead => 'Lettura';

  @override
  String get relayWrite => 'Scrittura';

  @override
  String get relayStateConnecting => 'Connessione in corso';

  @override
  String get relayStateOnline => 'Online';

  @override
  String get relayStateOffline => 'Offline';

  @override
  String get relayStateUnknown => 'Sconosciuto';

  @override
  String get widgetsPageTitle => 'Demo dei widget NDK Flutter';

  @override
  String get widgetsLoginHint =>
      'Accedi dalla scheda Account per vedere widget personalizzati.';

  @override
  String get widgetsCurrentUser => 'Utente corrente: ';

  @override
  String get widgetsSizeDefault => 'Predefinito';

  @override
  String get widgetsSizeLarger => 'Più grande';

  @override
  String get widgetsSizeLarge => 'Grande';

  @override
  String get widgetsShowLoginWidget => 'Mostra il widget NLogin';

  @override
  String get widgetsLoginWidgetTitle => 'Widget NLogin';

  @override
  String widgetsRequiresLogin(Object widgetName) {
    return '$widgetName\\n(accesso richiesto)';
  }

  @override
  String get widgetsSectionNNameDescription =>
      'Mostra il nome utente dai metadati, con fallback a un npub formattato.';

  @override
  String get widgetsSectionNPictureDescription =>
      'Mostra l’immagine del profilo con fallback alle iniziali.';

  @override
  String get widgetsSectionNBannerDescription =>
      'Mostra l’immagine banner dell’utente con fallback a un contenitore colorato.';

  @override
  String get widgetsSectionNUserProfileDescription =>
      'Profilo utente completo con banner, immagine, nome e NIP-05.';

  @override
  String get widgetsSectionNSwitchAccountDescription =>
      'Widget di gestione account con cambio account e logout.';

  @override
  String get widgetsSectionNLoginDescription =>
      'Widget di accesso con più metodi di autenticazione (NIP-05, npub, nsec, bunker, ecc.).';

  @override
  String get widgetsSectionGetColorDescription =>
      'Metodo statico che genera colori deterministici dalle pubkey.';

  @override
  String get blossomPageTitle => 'Operazioni media e file di Blossom';

  @override
  String get blossomImageDemoTitle => 'Demo immagine (getBlob)';

  @override
  String get blossomVideoDemoTitle => 'Demo video (checkBlob)';

  @override
  String get blossomNoImageYet => 'Nessuna immagine scaricata finora';

  @override
  String get blossomDownloadImage => 'Scarica immagine';

  @override
  String get blossomClearImage => 'Cancella immagine';

  @override
  String blossomMimeType(Object value) {
    return 'Tipo MIME: $value';
  }

  @override
  String blossomFileSizeBytes(Object value) {
    return 'Dimensione: $value byte';
  }

  @override
  String get blossomNoVideoYet => 'Nessun video caricato finora';

  @override
  String get blossomLoadVideo => 'Carica video';

  @override
  String get blossomClearVideo => 'Cancella video';

  @override
  String blossomVideoUrl(Object value) {
    return 'URL video: $value';
  }

  @override
  String get blossomUploadTitle => 'Carica file dal disco';

  @override
  String get blossomUploadDescription =>
      'Dimostra uploadFromFile() con avanzamento in streaming.';

  @override
  String blossomUploadingProgress(Object progress) {
    return 'Caricamento: $progress%';
  }

  @override
  String get blossomUploadSuccess => 'Caricamento riuscito';

  @override
  String blossomSha256(Object value) {
    return 'SHA256: $value';
  }

  @override
  String blossomUrl(Object value) {
    return 'URL: $value';
  }

  @override
  String get blossomNoUploadedFileYet => 'Nessun file caricato finora';

  @override
  String get blossomPickAndUploadFile => 'Scegli e carica file';

  @override
  String get clear => 'Cancella';

  @override
  String get blossomDownloadTitle => 'Scarica file su disco';

  @override
  String get blossomDownloadDescription =>
      'Dimostra downloadToFile() e salva direttamente su disco.';

  @override
  String get blossomNoDownloadedFileYet => 'Nessun file scaricato finora';

  @override
  String get blossomDownloadUploadedFile => 'Scarica il file caricato';

  @override
  String blossomSavedTo(Object value) {
    return 'Salvato in: $value';
  }

  @override
  String get blossomUploadFirstToEnableDownload =>
      'Carica prima un file per abilitare il download.';

  @override
  String get blossomNoUploadedFileToDownload =>
      'Nessun file caricato da scaricare.';

  @override
  String get blossomDownloadedToBrowser => 'Scaricato nel browser';

  @override
  String get downloadSuccess => 'Download riuscito';

  @override
  String errorLabel(Object error) {
    return 'Errore: $error';
  }

  @override
  String get pendingRequestsLoginRequired =>
      'Accedi per vedere le richieste in sospeso.';

  @override
  String get pendingNoRequests => 'Nessuna richiesta in sospeso';

  @override
  String get pendingUseButtons =>
      'Usa i pulsanti sopra per attivare richieste.';

  @override
  String get pendingRequestCancelled => 'Richiesta annullata';

  @override
  String get pendingRequestCancelFailed => 'Impossibile annullare la richiesta';

  @override
  String get pendingHeading => 'Richieste del firmatario in sospeso';

  @override
  String get pendingDescription =>
      'Richieste in attesa di approvazione dal tuo firmatario.';

  @override
  String get pendingTriggerRequests => 'Attiva richieste';

  @override
  String get signEvent => 'Firma evento';

  @override
  String get encrypt => 'Cifra';

  @override
  String get decrypt => 'Decifra';

  @override
  String pendingSignedResult(Object value) {
    return 'Firmato. ID: $value';
  }

  @override
  String pendingSignFailed(Object error) {
    return 'Firma non riuscita: $error';
  }

  @override
  String get pendingEncryptFirst =>
      'Cifra prima per ottenere il testo cifrato.';

  @override
  String pendingEncryptedResult(Object value) {
    return 'Cifrato: $value';
  }

  @override
  String pendingEncryptFailed(Object error) {
    return 'Cifratura non riuscita: $error';
  }

  @override
  String pendingDecryptedResult(Object value) {
    return 'Decifrato: $value';
  }

  @override
  String pendingDecryptFailed(Object error) {
    return 'Decifratura non riuscita: $error';
  }

  @override
  String get pendingMethodSignEvent => 'Firma evento';

  @override
  String get pendingMethodGetPublicKey => 'Ottieni chiave pubblica';

  @override
  String get pendingMethodNip04Encrypt => 'Cifra NIP-04';

  @override
  String get pendingMethodNip04Decrypt => 'Decifra NIP-04';

  @override
  String get pendingMethodNip44Encrypt => 'Cifra NIP-44';

  @override
  String get pendingMethodNip44Decrypt => 'Decifra NIP-44';

  @override
  String get pendingMethodPing => 'Ping';

  @override
  String get pendingMethodConnect => 'Connetti';

  @override
  String pendingSecondsAgo(int count) {
    return '${count}s fa';
  }

  @override
  String pendingMinutesAgo(int count) {
    return '${count}m fa';
  }

  @override
  String pendingHoursAgo(int count) {
    return '${count}h fa';
  }

  @override
  String pendingEventKind(Object value) {
    return 'Tipo evento: $value';
  }

  @override
  String pendingContent(Object value) {
    return 'Contenuto: $value';
  }

  @override
  String pendingCounterparty(Object value) {
    return 'Controparte: $value...';
  }

  @override
  String pendingPlaintext(Object value) {
    return 'Testo in chiaro: $value';
  }

  @override
  String pendingCiphertext(Object value) {
    return 'Testo cifrato: $value...';
  }

  @override
  String pendingId(Object value) {
    return 'ID: $value';
  }

  @override
  String get cancel => 'Annulla';
}
