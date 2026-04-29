// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'sample_app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Polish (`pl`).
class SampleAppLocalizationsPl extends SampleAppLocalizations {
  SampleAppLocalizationsPl([String locale = 'pl']) : super(locale);

  @override
  String get appName => 'Demo Nostr Developer Kit';

  @override
  String get appBarTitle => 'Demo NDK';

  @override
  String get tabAccounts => 'Konta';

  @override
  String get tabProfile => 'Profil';

  @override
  String get tabRelays => 'Relaye';

  @override
  String get tabBlossom => 'Blossom';

  @override
  String get tabWallets => 'Portfele';

  @override
  String get tabWidgets => 'Widgety';

  @override
  String get profileTooltip => 'Profil';

  @override
  String get loginDialogDefaultTitle => 'Zaloguj się';

  @override
  String get loginDialogAddAccountTitle => 'Dodaj konto';

  @override
  String get closeTooltip => 'Zamknij';

  @override
  String get accountsHeading => 'Konta';

  @override
  String get accountsDescription =>
      'Zarządzaj zalogowanymi kontami i dodawaj nowe.';

  @override
  String get addAnotherAccount => 'Dodaj kolejne konto';

  @override
  String get logIn => 'Zaloguj się';

  @override
  String get profileNoAccount => 'Brak zalogowanego konta.';

  @override
  String get profileAbout => 'O profilu';

  @override
  String profileMetadataError(Object error) {
    return 'Błąd pobierania metadanych: $error';
  }

  @override
  String get relaysLoginRequired => 'Zaloguj się, aby zobaczyć listę relayów.';

  @override
  String get relaysFetchButton => 'Pobierz listę relayów';

  @override
  String get relayListHeading => 'Lista relayów';

  @override
  String relayConfiguredCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count skonfigurowanych relayów',
      many: '$count skonfigurowanych relayów',
      few: '$count skonfigurowane relaye',
      one: '$count skonfigurowany relay',
    );
    return '$_temp0';
  }

  @override
  String relayConnection(Object state) {
    return 'Połączenie: $state';
  }

  @override
  String get relayRead => 'Odczyt';

  @override
  String get relayWrite => 'Zapis';

  @override
  String get relayStateConnecting => 'Łączenie';

  @override
  String get relayStateOnline => 'Online';

  @override
  String get relayStateOffline => 'Offline';

  @override
  String get relayStateUnknown => 'Nieznany';

  @override
  String get widgetsPageTitle => 'Demo widgetów NDK Flutter';

  @override
  String get widgetsLoginHint =>
      'Zaloguj się z karty Konta, aby zobaczyć spersonalizowane widgety.';

  @override
  String get widgetsCurrentUser => 'Bieżący użytkownik: ';

  @override
  String get widgetsSizeDefault => 'Domyślny';

  @override
  String get widgetsSizeLarger => 'Większy';

  @override
  String get widgetsSizeLarge => 'Duży';

  @override
  String get widgetsShowLoginWidget => 'Pokaż widget NLogin';

  @override
  String get widgetsLoginWidgetTitle => 'Widget NLogin';

  @override
  String widgetsRequiresLogin(Object widgetName) {
    return '$widgetName\\n(wymaga logowania)';
  }

  @override
  String get widgetsSectionNNameDescription =>
      'Wyświetla nazwę użytkownika z metadanych, a w razie braku sformatowany npub.';

  @override
  String get widgetsSectionNPictureDescription =>
      'Wyświetla zdjęcie profilowe użytkownika, a w razie braku inicjały.';

  @override
  String get widgetsSectionNBannerDescription =>
      'Wyświetla banner użytkownika, a w razie braku kolorowy kontener.';

  @override
  String get widgetsSectionNUserProfileDescription =>
      'Pełny profil użytkownika z bannerem, zdjęciem, nazwą i NIP-05.';

  @override
  String get widgetsSectionNSwitchAccountDescription =>
      'Widget zarządzania kontami z przełączaniem i wylogowaniem.';

  @override
  String get widgetsSectionNLoginDescription =>
      'Widget logowania z wieloma metodami uwierzytelniania (NIP-05, npub, nsec, bunker itd.).';

  @override
  String get widgetsSectionGetColorDescription =>
      'Statyczna metoda generująca deterministyczne kolory z pubkeyów.';

  @override
  String get blossomPageTitle => 'Operacje na mediach i plikach Blossom';

  @override
  String get blossomImageDemoTitle => 'Demo obrazu (getBlob)';

  @override
  String get blossomVideoDemoTitle => 'Demo wideo (checkBlob)';

  @override
  String get blossomNoImageYet => 'Nie pobrano jeszcze obrazu';

  @override
  String get blossomDownloadImage => 'Pobierz obraz';

  @override
  String get blossomClearImage => 'Wyczyść obraz';

  @override
  String blossomMimeType(Object value) {
    return 'Typ MIME: $value';
  }

  @override
  String blossomFileSizeBytes(Object value) {
    return 'Rozmiar: $value bajtów';
  }

  @override
  String get blossomNoVideoYet => 'Nie załadowano jeszcze wideo';

  @override
  String get blossomLoadVideo => 'Załaduj wideo';

  @override
  String get blossomClearVideo => 'Wyczyść wideo';

  @override
  String blossomVideoUrl(Object value) {
    return 'URL wideo: $value';
  }

  @override
  String get blossomUploadTitle => 'Prześlij plik z dysku';

  @override
  String get blossomUploadDescription =>
      'Demonstruje uploadFromFile() z postępem strumieniowym.';

  @override
  String blossomUploadingProgress(Object progress) {
    return 'Przesyłanie: $progress%';
  }

  @override
  String get blossomUploadSuccess => 'Przesyłanie zakończone';

  @override
  String blossomSha256(Object value) {
    return 'SHA256: $value';
  }

  @override
  String blossomUrl(Object value) {
    return 'URL: $value';
  }

  @override
  String get blossomNoUploadedFileYet => 'Nie przesłano jeszcze pliku';

  @override
  String get blossomPickAndUploadFile => 'Wybierz i prześlij plik';

  @override
  String get clear => 'Wyczyść';

  @override
  String get blossomDownloadTitle => 'Pobierz plik na dysk';

  @override
  String get blossomDownloadDescription =>
      'Demonstruje downloadToFile() i zapisuje bezpośrednio na dysku.';

  @override
  String get blossomNoDownloadedFileYet => 'Nie pobrano jeszcze pliku';

  @override
  String get blossomDownloadUploadedFile => 'Pobierz przesłany plik';

  @override
  String blossomSavedTo(Object value) {
    return 'Zapisano do: $value';
  }

  @override
  String get blossomUploadFirstToEnableDownload =>
      'Najpierw prześlij plik, aby włączyć pobieranie.';

  @override
  String get blossomNoUploadedFileToDownload =>
      'Nie ma jeszcze przesłanego pliku do pobrania.';

  @override
  String get blossomDownloadedToBrowser => 'Pobrano do przeglądarki';

  @override
  String get downloadSuccess => 'Pobieranie zakończone';

  @override
  String errorLabel(Object error) {
    return 'Błąd: $error';
  }

  @override
  String get pendingRequestsLoginRequired =>
      'Zaloguj się, aby zobaczyć oczekujące żądania.';

  @override
  String get pendingNoRequests => 'Brak oczekujących żądań';

  @override
  String get pendingUseButtons =>
      'Użyj przycisków powyżej, aby wywołać żądania.';

  @override
  String get pendingRequestCancelled => 'Żądanie anulowane';

  @override
  String get pendingRequestCancelFailed => 'Nie udało się anulować żądania';

  @override
  String get pendingHeading => 'Oczekujące żądania podpisującego';

  @override
  String get pendingDescription =>
      'Żądania oczekujące na zatwierdzenie przez podpisującego.';

  @override
  String get pendingTriggerRequests => 'Wywołaj żądania';

  @override
  String get signEvent => 'Podpisz wydarzenie';

  @override
  String get encrypt => 'Szyfruj';

  @override
  String get decrypt => 'Deszyfruj';

  @override
  String pendingSignedResult(Object value) {
    return 'Podpisano. ID: $value';
  }

  @override
  String pendingSignFailed(Object error) {
    return 'Podpisywanie nie powiodło się: $error';
  }

  @override
  String get pendingEncryptFirst =>
      'Najpierw zaszyfruj, aby uzyskać szyfrogram.';

  @override
  String pendingEncryptedResult(Object value) {
    return 'Zaszyfrowano: $value';
  }

  @override
  String pendingEncryptFailed(Object error) {
    return 'Szyfrowanie nie powiodło się: $error';
  }

  @override
  String pendingDecryptedResult(Object value) {
    return 'Odszyfrowano: $value';
  }

  @override
  String pendingDecryptFailed(Object error) {
    return 'Deszyfrowanie nie powiodło się: $error';
  }

  @override
  String get pendingMethodSignEvent => 'Podpisz wydarzenie';

  @override
  String get pendingMethodGetPublicKey => 'Pobierz klucz publiczny';

  @override
  String get pendingMethodNip04Encrypt => 'Szyfruj NIP-04';

  @override
  String get pendingMethodNip04Decrypt => 'Deszyfruj NIP-04';

  @override
  String get pendingMethodNip44Encrypt => 'Szyfruj NIP-44';

  @override
  String get pendingMethodNip44Decrypt => 'Deszyfruj NIP-44';

  @override
  String get pendingMethodPing => 'Ping';

  @override
  String get pendingMethodConnect => 'Połącz';

  @override
  String pendingSecondsAgo(int count) {
    return '${count}s temu';
  }

  @override
  String pendingMinutesAgo(int count) {
    return '${count}m temu';
  }

  @override
  String pendingHoursAgo(int count) {
    return '${count}h temu';
  }

  @override
  String pendingEventKind(Object value) {
    return 'Typ wydarzenia: $value';
  }

  @override
  String pendingContent(Object value) {
    return 'Treść: $value';
  }

  @override
  String pendingCounterparty(Object value) {
    return 'Druga strona: $value...';
  }

  @override
  String pendingPlaintext(Object value) {
    return 'Tekst jawny: $value';
  }

  @override
  String pendingCiphertext(Object value) {
    return 'Szyfrogram: $value...';
  }

  @override
  String pendingId(Object value) {
    return 'ID: $value';
  }

  @override
  String get cancel => 'Anuluj';
}
