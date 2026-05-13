// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'sample_app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class SampleAppLocalizationsDe extends SampleAppLocalizations {
  SampleAppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appName => 'Nostr Developer Kit Demo';

  @override
  String get appBarTitle => 'NDK-Demo';

  @override
  String get tabAccounts => 'Konten';

  @override
  String get tabProfile => 'Profil';

  @override
  String get tabRelays => 'Relays';

  @override
  String get tabBlossom => 'Blossom';

  @override
  String get tabWallets => 'Wallets';

  @override
  String get tabWidgets => 'Widgets';

  @override
  String get profileTooltip => 'Profil';

  @override
  String get loginDialogDefaultTitle => 'Anmelden';

  @override
  String get loginDialogAddAccountTitle => 'Konto hinzufügen';

  @override
  String get closeTooltip => 'Schließen';

  @override
  String get accountsHeading => 'Konten';

  @override
  String get accountsDescription =>
      'Verwalte deine angemeldeten Konten und füge neue hinzu.';

  @override
  String get addAnotherAccount => 'Weiteres Konto hinzufügen';

  @override
  String get logIn => 'Anmelden';

  @override
  String get profileNoAccount => 'Kein Konto angemeldet.';

  @override
  String get profileAbout => 'Über';

  @override
  String profileMetadataError(Object error) {
    return 'Fehler beim Laden der Metadaten: $error';
  }

  @override
  String get relaysLoginRequired =>
      'Melde dich an, um deine Relay-Liste zu sehen.';

  @override
  String get relaysFetchButton => 'Relay-Liste laden';

  @override
  String get relayListHeading => 'Relay-Liste';

  @override
  String relayConfiguredCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count konfigurierte Relays',
      one: '$count konfiguriertes Relay',
    );
    return '$_temp0';
  }

  @override
  String relayConnection(Object state) {
    return 'Verbindung: $state';
  }

  @override
  String get relayRead => 'Lesen';

  @override
  String get relayWrite => 'Schreiben';

  @override
  String get relayStateConnecting => 'Verbinden';

  @override
  String get relayStateOnline => 'Online';

  @override
  String get relayStateOffline => 'Offline';

  @override
  String get relayStateUnknown => 'Unbekannt';

  @override
  String get widgetsPageTitle => 'NDK Flutter Widgets Demo';

  @override
  String get widgetsLoginHint =>
      'Melde dich im Tab „Konten“ an, um personalisierte Widgets zu sehen.';

  @override
  String get widgetsCurrentUser => 'Aktueller Nutzer: ';

  @override
  String get widgetsSizeDefault => 'Standard';

  @override
  String get widgetsSizeLarger => 'Größer';

  @override
  String get widgetsSizeLarge => 'Groß';

  @override
  String get widgetsShowLoginWidget => 'NLogin-Widget anzeigen';

  @override
  String get widgetsLoginWidgetTitle => 'NLogin-Widget';

  @override
  String widgetsRequiresLogin(Object widgetName) {
    return '$widgetName\\n(Anmeldung erforderlich)';
  }

  @override
  String get widgetsSectionNNameDescription =>
      'Zeigt den Nutzernamen aus den Metadaten an und fällt auf ein formatiertes npub zurück.';

  @override
  String get widgetsSectionNPictureDescription =>
      'Zeigt das Profilbild des Nutzers an und fällt auf Initialen zurück.';

  @override
  String get widgetsSectionNBannerDescription =>
      'Zeigt das Bannerbild des Nutzers an und fällt auf einen farbigen Container zurück.';

  @override
  String get widgetsSectionNUserProfileDescription =>
      'Vollständiges Nutzerprofil mit Banner, Bild, Name und NIP-05.';

  @override
  String get widgetsSectionNSwitchAccountDescription =>
      'Kontoverwaltung mit Kontowechsel und Abmeldung.';

  @override
  String get widgetsSectionNLoginDescription =>
      'Login-Widget mit mehreren Authentifizierungsmethoden (NIP-05, npub, nsec, Bunker usw.).';

  @override
  String get widgetsSectionGetColorDescription =>
      'Statische Methode, die deterministische Farben aus Pubkeys erzeugt.';

  @override
  String get blossomPageTitle => 'Blossom Medien- und Dateioperationen';

  @override
  String get blossomImageDemoTitle => 'Bilddemo (getBlob)';

  @override
  String get blossomVideoDemoTitle => 'Videodemo (checkBlob)';

  @override
  String get blossomNoImageYet => 'Noch kein Bild heruntergeladen';

  @override
  String get blossomDownloadImage => 'Bild herunterladen';

  @override
  String get blossomClearImage => 'Bild löschen';

  @override
  String blossomMimeType(Object value) {
    return 'MIME-Typ: $value';
  }

  @override
  String blossomFileSizeBytes(Object value) {
    return 'Größe: $value Byte';
  }

  @override
  String get blossomNoVideoYet => 'Noch kein Video geladen';

  @override
  String get blossomLoadVideo => 'Video laden';

  @override
  String get blossomClearVideo => 'Video löschen';

  @override
  String blossomVideoUrl(Object value) {
    return 'Video-URL: $value';
  }

  @override
  String get blossomUploadTitle => 'Datei vom Datenträger hochladen';

  @override
  String get blossomUploadDescription =>
      'Demonstriert uploadFromFile() mit Streaming-Fortschritt.';

  @override
  String blossomUploadingProgress(Object progress) {
    return 'Hochladen: $progress%';
  }

  @override
  String get blossomUploadSuccess => 'Upload erfolgreich';

  @override
  String blossomSha256(Object value) {
    return 'SHA256: $value';
  }

  @override
  String blossomUrl(Object value) {
    return 'URL: $value';
  }

  @override
  String get blossomNoUploadedFileYet => 'Noch keine Datei hochgeladen';

  @override
  String get blossomPickAndUploadFile => 'Datei auswählen und hochladen';

  @override
  String get clear => 'Löschen';

  @override
  String get blossomDownloadTitle => 'Datei auf Datenträger herunterladen';

  @override
  String get blossomDownloadDescription =>
      'Demonstriert downloadToFile() und speichert direkt auf dem Datenträger.';

  @override
  String get blossomNoDownloadedFileYet => 'Noch keine Datei heruntergeladen';

  @override
  String get blossomDownloadUploadedFile => 'Hochgeladene Datei herunterladen';

  @override
  String blossomSavedTo(Object value) {
    return 'Gespeichert unter: $value';
  }

  @override
  String get blossomUploadFirstToEnableDownload =>
      'Lade zuerst eine Datei hoch, um den Download zu aktivieren.';

  @override
  String get blossomNoUploadedFileToDownload =>
      'Es wurde noch keine Datei zum Herunterladen hochgeladen.';

  @override
  String get blossomDownloadedToBrowser => 'Im Browser heruntergeladen';

  @override
  String get downloadSuccess => 'Download erfolgreich';

  @override
  String errorLabel(Object error) {
    return 'Fehler: $error';
  }

  @override
  String get pendingRequestsLoginRequired =>
      'Bitte melde dich an, um ausstehende Anfragen zu sehen.';

  @override
  String get pendingNoRequests => 'Keine ausstehenden Anfragen';

  @override
  String get pendingUseButtons =>
      'Verwende die Schaltflächen oben, um Anfragen auszulösen.';

  @override
  String get pendingRequestCancelled => 'Anfrage abgebrochen';

  @override
  String get pendingRequestCancelFailed =>
      'Abbrechen der Anfrage fehlgeschlagen';

  @override
  String get pendingHeading => 'Ausstehende Signierer-Anfragen';

  @override
  String get pendingDescription =>
      'Anfragen, die auf die Freigabe durch deinen Signierer warten.';

  @override
  String get pendingTriggerRequests => 'Anfragen auslösen';

  @override
  String get signEvent => 'Event signieren';

  @override
  String get encrypt => 'Verschlüsseln';

  @override
  String get decrypt => 'Entschlüsseln';

  @override
  String pendingSignedResult(Object value) {
    return 'Signiert! ID: $value';
  }

  @override
  String pendingSignFailed(Object error) {
    return 'Signieren fehlgeschlagen: $error';
  }

  @override
  String get pendingEncryptFirst =>
      'Verschlüssele zuerst, um Chiffretext zu erhalten.';

  @override
  String pendingEncryptedResult(Object value) {
    return 'Verschlüsselt: $value';
  }

  @override
  String pendingEncryptFailed(Object error) {
    return 'Verschlüsselung fehlgeschlagen: $error';
  }

  @override
  String pendingDecryptedResult(Object value) {
    return 'Entschlüsselt: $value';
  }

  @override
  String pendingDecryptFailed(Object error) {
    return 'Entschlüsselung fehlgeschlagen: $error';
  }

  @override
  String get pendingMethodSignEvent => 'Event signieren';

  @override
  String get pendingMethodGetPublicKey => 'Öffentlichen Schlüssel abrufen';

  @override
  String get pendingMethodNip04Encrypt => 'NIP-04 verschlüsseln';

  @override
  String get pendingMethodNip04Decrypt => 'NIP-04 entschlüsseln';

  @override
  String get pendingMethodNip44Encrypt => 'NIP-44 verschlüsseln';

  @override
  String get pendingMethodNip44Decrypt => 'NIP-44 entschlüsseln';

  @override
  String get pendingMethodPing => 'Ping';

  @override
  String get pendingMethodConnect => 'Verbinden';

  @override
  String pendingSecondsAgo(int count) {
    return 'vor ${count}s';
  }

  @override
  String pendingMinutesAgo(int count) {
    return 'vor ${count}m';
  }

  @override
  String pendingHoursAgo(int count) {
    return 'vor ${count}h';
  }

  @override
  String pendingEventKind(Object value) {
    return 'Event-Art: $value';
  }

  @override
  String pendingContent(Object value) {
    return 'Inhalt: $value';
  }

  @override
  String pendingCounterparty(Object value) {
    return 'Gegenstelle: $value...';
  }

  @override
  String pendingPlaintext(Object value) {
    return 'Klartext: $value';
  }

  @override
  String pendingCiphertext(Object value) {
    return 'Chiffretext: $value...';
  }

  @override
  String pendingId(Object value) {
    return 'ID: $value';
  }

  @override
  String get cancel => 'Abbrechen';
}
