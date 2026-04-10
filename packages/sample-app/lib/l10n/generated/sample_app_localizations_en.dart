// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'sample_app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class SampleAppLocalizationsEn extends SampleAppLocalizations {
  SampleAppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Nostr Developer Kit Demo';

  @override
  String get appBarTitle => 'NDK Demo';

  @override
  String get tabAccounts => 'Accounts';

  @override
  String get tabProfile => 'Profile';

  @override
  String get tabRelays => 'Relays';

  @override
  String get tabBlossom => 'Blossom';

  @override
  String get tabWallets => 'Wallets';

  @override
  String get tabWidgets => 'Widgets';

  @override
  String get profileTooltip => 'Profile';

  @override
  String get loginDialogDefaultTitle => 'Log in';

  @override
  String get loginDialogAddAccountTitle => 'Add account';

  @override
  String get closeTooltip => 'Close';

  @override
  String get accountsHeading => 'Accounts';

  @override
  String get accountsDescription =>
      'Manage your logged accounts and add new ones.';

  @override
  String get addAnotherAccount => 'Add Another Account';

  @override
  String get logIn => 'Log In';

  @override
  String get profileNoAccount => 'No account logged in.';

  @override
  String get profileAbout => 'About';

  @override
  String profileMetadataError(Object error) {
    return 'Error fetching metadata: $error';
  }

  @override
  String get relaysLoginRequired => 'Log in to view your relay list.';

  @override
  String get relaysFetchButton => 'Fetch relay list';

  @override
  String get relayListHeading => 'Relay List';

  @override
  String relayConfiguredCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count configured relays',
      one: '$count configured relay',
    );
    return '$_temp0';
  }

  @override
  String relayConnection(Object state) {
    return 'Connection: $state';
  }

  @override
  String get relayRead => 'Read';

  @override
  String get relayWrite => 'Write';

  @override
  String get relayStateConnecting => 'Connecting';

  @override
  String get relayStateOnline => 'Online';

  @override
  String get relayStateOffline => 'Offline';

  @override
  String get relayStateUnknown => 'Unknown';

  @override
  String get widgetsPageTitle => 'NDK Flutter Widgets Demo';

  @override
  String get widgetsLoginHint =>
      'Log in from the Accounts tab to see personalized widgets.';

  @override
  String get widgetsCurrentUser => 'Current user: ';

  @override
  String get widgetsSizeDefault => 'Default';

  @override
  String get widgetsSizeLarger => 'Larger';

  @override
  String get widgetsSizeLarge => 'Large';

  @override
  String get widgetsShowLoginWidget => 'Show NLogin Widget';

  @override
  String get widgetsLoginWidgetTitle => 'NLogin Widget';

  @override
  String widgetsRequiresLogin(Object widgetName) {
    return '$widgetName\\n(requires login)';
  }

  @override
  String get widgetsSectionNNameDescription =>
      'Displays user name from metadata, falls back to formatted npub.';

  @override
  String get widgetsSectionNPictureDescription =>
      'Displays user profile picture with fallback to initials.';

  @override
  String get widgetsSectionNBannerDescription =>
      'Displays user banner image with fallback to a colored container.';

  @override
  String get widgetsSectionNUserProfileDescription =>
      'Complete user profile with banner, picture, name, and NIP-05.';

  @override
  String get widgetsSectionNSwitchAccountDescription =>
      'Account management widget with switching and logout.';

  @override
  String get widgetsSectionNLoginDescription =>
      'Login widget with multiple auth methods (NIP-05, npub, nsec, bunker, etc.).';

  @override
  String get widgetsSectionGetColorDescription =>
      'Static method that generates deterministic colors from pubkeys.';

  @override
  String get blossomPageTitle => 'Blossom Media & File Operations';

  @override
  String get blossomImageDemoTitle => 'Image Demo (getBlob)';

  @override
  String get blossomVideoDemoTitle => 'Video Demo (checkBlob)';

  @override
  String get blossomNoImageYet => 'No image downloaded yet';

  @override
  String get blossomDownloadImage => 'Download Image';

  @override
  String get blossomClearImage => 'Clear Image';

  @override
  String blossomMimeType(Object value) {
    return 'Mime Type: $value';
  }

  @override
  String blossomFileSizeBytes(Object value) {
    return 'Size: $value bytes';
  }

  @override
  String get blossomNoVideoYet => 'No video loaded yet';

  @override
  String get blossomLoadVideo => 'Load Video';

  @override
  String get blossomClearVideo => 'Clear Video';

  @override
  String blossomVideoUrl(Object value) {
    return 'Video URL: $value';
  }

  @override
  String get blossomUploadTitle => 'Upload File from Disk';

  @override
  String get blossomUploadDescription =>
      'Demonstrates uploadFromFile() with streaming progress.';

  @override
  String blossomUploadingProgress(Object progress) {
    return 'Uploading: $progress%';
  }

  @override
  String get blossomUploadSuccess => 'Upload successful';

  @override
  String blossomSha256(Object value) {
    return 'SHA256: $value';
  }

  @override
  String blossomUrl(Object value) {
    return 'URL: $value';
  }

  @override
  String get blossomNoUploadedFileYet => 'No file uploaded yet';

  @override
  String get blossomPickAndUploadFile => 'Pick & Upload File';

  @override
  String get clear => 'Clear';

  @override
  String get blossomDownloadTitle => 'Download File to Disk';

  @override
  String get blossomDownloadDescription =>
      'Demonstrates downloadToFile() and saves directly to disk.';

  @override
  String get blossomNoDownloadedFileYet => 'No file downloaded yet';

  @override
  String get blossomDownloadUploadedFile => 'Download Uploaded File';

  @override
  String blossomSavedTo(Object value) {
    return 'Saved to: $value';
  }

  @override
  String get blossomUploadFirstToEnableDownload =>
      'Upload a file first to enable download.';

  @override
  String get blossomNoUploadedFileToDownload =>
      'No file uploaded yet to download.';

  @override
  String get blossomDownloadedToBrowser => 'Downloaded to browser';

  @override
  String get downloadSuccess => 'Download successful';

  @override
  String errorLabel(Object error) {
    return 'Error: $error';
  }

  @override
  String get pendingRequestsLoginRequired =>
      'Please log in to see pending requests.';

  @override
  String get pendingNoRequests => 'No pending requests';

  @override
  String get pendingUseButtons => 'Use the buttons above to trigger requests.';

  @override
  String get pendingRequestCancelled => 'Request cancelled';

  @override
  String get pendingRequestCancelFailed => 'Failed to cancel request';

  @override
  String get pendingHeading => 'Pending Signer Requests';

  @override
  String get pendingDescription =>
      'Requests waiting for approval from your signer.';

  @override
  String get pendingTriggerRequests => 'Trigger Requests';

  @override
  String get signEvent => 'Sign Event';

  @override
  String get encrypt => 'Encrypt';

  @override
  String get decrypt => 'Decrypt';

  @override
  String pendingSignedResult(Object value) {
    return 'Signed! ID: $value';
  }

  @override
  String pendingSignFailed(Object error) {
    return 'Sign failed: $error';
  }

  @override
  String get pendingEncryptFirst => 'Encrypt first to get ciphertext.';

  @override
  String pendingEncryptedResult(Object value) {
    return 'Encrypted: $value';
  }

  @override
  String pendingEncryptFailed(Object error) {
    return 'Encrypt failed: $error';
  }

  @override
  String pendingDecryptedResult(Object value) {
    return 'Decrypted: $value';
  }

  @override
  String pendingDecryptFailed(Object error) {
    return 'Decrypt failed: $error';
  }

  @override
  String get pendingMethodSignEvent => 'Sign Event';

  @override
  String get pendingMethodGetPublicKey => 'Get Public Key';

  @override
  String get pendingMethodNip04Encrypt => 'NIP-04 Encrypt';

  @override
  String get pendingMethodNip04Decrypt => 'NIP-04 Decrypt';

  @override
  String get pendingMethodNip44Encrypt => 'NIP-44 Encrypt';

  @override
  String get pendingMethodNip44Decrypt => 'NIP-44 Decrypt';

  @override
  String get pendingMethodPing => 'Ping';

  @override
  String get pendingMethodConnect => 'Connect';

  @override
  String pendingSecondsAgo(int count) {
    return '${count}s ago';
  }

  @override
  String pendingMinutesAgo(int count) {
    return '${count}m ago';
  }

  @override
  String pendingHoursAgo(int count) {
    return '${count}h ago';
  }

  @override
  String pendingEventKind(Object value) {
    return 'Event Kind: $value';
  }

  @override
  String pendingContent(Object value) {
    return 'Content: $value';
  }

  @override
  String pendingCounterparty(Object value) {
    return 'Counterparty: $value...';
  }

  @override
  String pendingPlaintext(Object value) {
    return 'Plaintext: $value';
  }

  @override
  String pendingCiphertext(Object value) {
    return 'Ciphertext: $value...';
  }

  @override
  String pendingId(Object value) {
    return 'ID: $value';
  }

  @override
  String get cancel => 'Cancel';
}
