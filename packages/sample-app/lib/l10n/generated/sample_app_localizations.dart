import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'sample_app_localizations_de.dart';
import 'sample_app_localizations_en.dart';
import 'sample_app_localizations_es.dart';
import 'sample_app_localizations_fr.dart';
import 'sample_app_localizations_it.dart';
import 'sample_app_localizations_ja.dart';
import 'sample_app_localizations_pl.dart';
import 'sample_app_localizations_ru.dart';
import 'sample_app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of SampleAppLocalizations
/// returned by `SampleAppLocalizations.of(context)`.
///
/// Applications need to include `SampleAppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/sample_app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: SampleAppLocalizations.localizationsDelegates,
///   supportedLocales: SampleAppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the SampleAppLocalizations.supportedLocales
/// property.
abstract class SampleAppLocalizations {
  SampleAppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static SampleAppLocalizations? of(BuildContext context) {
    return Localizations.of<SampleAppLocalizations>(
        context, SampleAppLocalizations);
  }

  static const LocalizationsDelegate<SampleAppLocalizations> delegate =
      _SampleAppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('it'),
    Locale('ja'),
    Locale('pl'),
    Locale('ru'),
    Locale('zh')
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Nostr Developer Kit Demo'**
  String get appName;

  /// No description provided for @appBarTitle.
  ///
  /// In en, this message translates to:
  /// **'NDK Demo'**
  String get appBarTitle;

  /// No description provided for @tabAccounts.
  ///
  /// In en, this message translates to:
  /// **'Accounts'**
  String get tabAccounts;

  /// No description provided for @tabProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get tabProfile;

  /// No description provided for @tabRelays.
  ///
  /// In en, this message translates to:
  /// **'Relays'**
  String get tabRelays;

  /// No description provided for @tabBlossom.
  ///
  /// In en, this message translates to:
  /// **'Blossom'**
  String get tabBlossom;

  /// No description provided for @tabWallets.
  ///
  /// In en, this message translates to:
  /// **'Wallets'**
  String get tabWallets;

  /// No description provided for @tabWidgets.
  ///
  /// In en, this message translates to:
  /// **'Widgets'**
  String get tabWidgets;

  /// No description provided for @profileTooltip.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTooltip;

  /// No description provided for @loginDialogDefaultTitle.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get loginDialogDefaultTitle;

  /// No description provided for @loginDialogAddAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Add account'**
  String get loginDialogAddAccountTitle;

  /// No description provided for @closeTooltip.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get closeTooltip;

  /// No description provided for @accountsHeading.
  ///
  /// In en, this message translates to:
  /// **'Accounts'**
  String get accountsHeading;

  /// No description provided for @accountsDescription.
  ///
  /// In en, this message translates to:
  /// **'Manage your logged accounts and add new ones.'**
  String get accountsDescription;

  /// No description provided for @addAnotherAccount.
  ///
  /// In en, this message translates to:
  /// **'Add Another Account'**
  String get addAnotherAccount;

  /// No description provided for @logIn.
  ///
  /// In en, this message translates to:
  /// **'Log In'**
  String get logIn;

  /// No description provided for @profileNoAccount.
  ///
  /// In en, this message translates to:
  /// **'No account logged in.'**
  String get profileNoAccount;

  /// No description provided for @profileAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get profileAbout;

  /// No description provided for @profileMetadataError.
  ///
  /// In en, this message translates to:
  /// **'Error fetching metadata: {error}'**
  String profileMetadataError(Object error);

  /// No description provided for @relaysLoginRequired.
  ///
  /// In en, this message translates to:
  /// **'Log in to view your relay list.'**
  String get relaysLoginRequired;

  /// No description provided for @relaysFetchButton.
  ///
  /// In en, this message translates to:
  /// **'Fetch relay list'**
  String get relaysFetchButton;

  /// No description provided for @relayListHeading.
  ///
  /// In en, this message translates to:
  /// **'Relay List'**
  String get relayListHeading;

  /// No description provided for @relayConfiguredCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} configured relay} other{{count} configured relays}}'**
  String relayConfiguredCount(int count);

  /// No description provided for @relayConnection.
  ///
  /// In en, this message translates to:
  /// **'Connection: {state}'**
  String relayConnection(Object state);

  /// No description provided for @relayRead.
  ///
  /// In en, this message translates to:
  /// **'Read'**
  String get relayRead;

  /// No description provided for @relayWrite.
  ///
  /// In en, this message translates to:
  /// **'Write'**
  String get relayWrite;

  /// No description provided for @relayStateConnecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting'**
  String get relayStateConnecting;

  /// No description provided for @relayStateOnline.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get relayStateOnline;

  /// No description provided for @relayStateOffline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get relayStateOffline;

  /// No description provided for @relayStateUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get relayStateUnknown;

  /// No description provided for @widgetsPageTitle.
  ///
  /// In en, this message translates to:
  /// **'NDK Flutter Widgets Demo'**
  String get widgetsPageTitle;

  /// No description provided for @widgetsLoginHint.
  ///
  /// In en, this message translates to:
  /// **'Log in from the Accounts tab to see personalized widgets.'**
  String get widgetsLoginHint;

  /// No description provided for @widgetsCurrentUser.
  ///
  /// In en, this message translates to:
  /// **'Current user: '**
  String get widgetsCurrentUser;

  /// No description provided for @widgetsSizeDefault.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get widgetsSizeDefault;

  /// No description provided for @widgetsSizeLarger.
  ///
  /// In en, this message translates to:
  /// **'Larger'**
  String get widgetsSizeLarger;

  /// No description provided for @widgetsSizeLarge.
  ///
  /// In en, this message translates to:
  /// **'Large'**
  String get widgetsSizeLarge;

  /// No description provided for @widgetsShowLoginWidget.
  ///
  /// In en, this message translates to:
  /// **'Show NLogin Widget'**
  String get widgetsShowLoginWidget;

  /// No description provided for @widgetsLoginWidgetTitle.
  ///
  /// In en, this message translates to:
  /// **'NLogin Widget'**
  String get widgetsLoginWidgetTitle;

  /// No description provided for @widgetsRequiresLogin.
  ///
  /// In en, this message translates to:
  /// **'{widgetName}\\n(requires login)'**
  String widgetsRequiresLogin(Object widgetName);

  /// No description provided for @widgetsSectionNNameDescription.
  ///
  /// In en, this message translates to:
  /// **'Displays user name from metadata, falls back to formatted npub.'**
  String get widgetsSectionNNameDescription;

  /// No description provided for @widgetsSectionNPictureDescription.
  ///
  /// In en, this message translates to:
  /// **'Displays user profile picture with fallback to initials.'**
  String get widgetsSectionNPictureDescription;

  /// No description provided for @widgetsSectionNBannerDescription.
  ///
  /// In en, this message translates to:
  /// **'Displays user banner image with fallback to a colored container.'**
  String get widgetsSectionNBannerDescription;

  /// No description provided for @widgetsSectionNUserProfileDescription.
  ///
  /// In en, this message translates to:
  /// **'Complete user profile with banner, picture, name, and NIP-05.'**
  String get widgetsSectionNUserProfileDescription;

  /// No description provided for @widgetsSectionNSwitchAccountDescription.
  ///
  /// In en, this message translates to:
  /// **'Account management widget with switching and logout.'**
  String get widgetsSectionNSwitchAccountDescription;

  /// No description provided for @widgetsSectionNLoginDescription.
  ///
  /// In en, this message translates to:
  /// **'Login widget with multiple auth methods (NIP-05, npub, nsec, bunker, etc.).'**
  String get widgetsSectionNLoginDescription;

  /// No description provided for @widgetsSectionGetColorDescription.
  ///
  /// In en, this message translates to:
  /// **'Static method that generates deterministic colors from pubkeys.'**
  String get widgetsSectionGetColorDescription;

  /// No description provided for @blossomPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Blossom Media & File Operations'**
  String get blossomPageTitle;

  /// No description provided for @blossomImageDemoTitle.
  ///
  /// In en, this message translates to:
  /// **'Image Demo (getBlob)'**
  String get blossomImageDemoTitle;

  /// No description provided for @blossomVideoDemoTitle.
  ///
  /// In en, this message translates to:
  /// **'Video Demo (checkBlob)'**
  String get blossomVideoDemoTitle;

  /// No description provided for @blossomNoImageYet.
  ///
  /// In en, this message translates to:
  /// **'No image downloaded yet'**
  String get blossomNoImageYet;

  /// No description provided for @blossomDownloadImage.
  ///
  /// In en, this message translates to:
  /// **'Download Image'**
  String get blossomDownloadImage;

  /// No description provided for @blossomClearImage.
  ///
  /// In en, this message translates to:
  /// **'Clear Image'**
  String get blossomClearImage;

  /// No description provided for @blossomMimeType.
  ///
  /// In en, this message translates to:
  /// **'Mime Type: {value}'**
  String blossomMimeType(Object value);

  /// No description provided for @blossomFileSizeBytes.
  ///
  /// In en, this message translates to:
  /// **'Size: {value} bytes'**
  String blossomFileSizeBytes(Object value);

  /// No description provided for @blossomNoVideoYet.
  ///
  /// In en, this message translates to:
  /// **'No video loaded yet'**
  String get blossomNoVideoYet;

  /// No description provided for @blossomLoadVideo.
  ///
  /// In en, this message translates to:
  /// **'Load Video'**
  String get blossomLoadVideo;

  /// No description provided for @blossomClearVideo.
  ///
  /// In en, this message translates to:
  /// **'Clear Video'**
  String get blossomClearVideo;

  /// No description provided for @blossomVideoUrl.
  ///
  /// In en, this message translates to:
  /// **'Video URL: {value}'**
  String blossomVideoUrl(Object value);

  /// No description provided for @blossomUploadTitle.
  ///
  /// In en, this message translates to:
  /// **'Upload File from Disk'**
  String get blossomUploadTitle;

  /// No description provided for @blossomUploadDescription.
  ///
  /// In en, this message translates to:
  /// **'Demonstrates uploadFromFile() with streaming progress.'**
  String get blossomUploadDescription;

  /// No description provided for @blossomUploadingProgress.
  ///
  /// In en, this message translates to:
  /// **'Uploading: {progress}%'**
  String blossomUploadingProgress(Object progress);

  /// No description provided for @blossomUploadSuccess.
  ///
  /// In en, this message translates to:
  /// **'Upload successful'**
  String get blossomUploadSuccess;

  /// No description provided for @blossomSha256.
  ///
  /// In en, this message translates to:
  /// **'SHA256: {value}'**
  String blossomSha256(Object value);

  /// No description provided for @blossomUrl.
  ///
  /// In en, this message translates to:
  /// **'URL: {value}'**
  String blossomUrl(Object value);

  /// No description provided for @blossomNoUploadedFileYet.
  ///
  /// In en, this message translates to:
  /// **'No file uploaded yet'**
  String get blossomNoUploadedFileYet;

  /// No description provided for @blossomPickAndUploadFile.
  ///
  /// In en, this message translates to:
  /// **'Pick & Upload File'**
  String get blossomPickAndUploadFile;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @blossomDownloadTitle.
  ///
  /// In en, this message translates to:
  /// **'Download File to Disk'**
  String get blossomDownloadTitle;

  /// No description provided for @blossomDownloadDescription.
  ///
  /// In en, this message translates to:
  /// **'Demonstrates downloadToFile() and saves directly to disk.'**
  String get blossomDownloadDescription;

  /// No description provided for @blossomNoDownloadedFileYet.
  ///
  /// In en, this message translates to:
  /// **'No file downloaded yet'**
  String get blossomNoDownloadedFileYet;

  /// No description provided for @blossomDownloadUploadedFile.
  ///
  /// In en, this message translates to:
  /// **'Download Uploaded File'**
  String get blossomDownloadUploadedFile;

  /// No description provided for @blossomSavedTo.
  ///
  /// In en, this message translates to:
  /// **'Saved to: {value}'**
  String blossomSavedTo(Object value);

  /// No description provided for @blossomUploadFirstToEnableDownload.
  ///
  /// In en, this message translates to:
  /// **'Upload a file first to enable download.'**
  String get blossomUploadFirstToEnableDownload;

  /// No description provided for @blossomNoUploadedFileToDownload.
  ///
  /// In en, this message translates to:
  /// **'No file uploaded yet to download.'**
  String get blossomNoUploadedFileToDownload;

  /// No description provided for @blossomDownloadedToBrowser.
  ///
  /// In en, this message translates to:
  /// **'Downloaded to browser'**
  String get blossomDownloadedToBrowser;

  /// No description provided for @downloadSuccess.
  ///
  /// In en, this message translates to:
  /// **'Download successful'**
  String get downloadSuccess;

  /// No description provided for @errorLabel.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String errorLabel(Object error);

  /// No description provided for @pendingRequestsLoginRequired.
  ///
  /// In en, this message translates to:
  /// **'Please log in to see pending requests.'**
  String get pendingRequestsLoginRequired;

  /// No description provided for @pendingNoRequests.
  ///
  /// In en, this message translates to:
  /// **'No pending requests'**
  String get pendingNoRequests;

  /// No description provided for @pendingUseButtons.
  ///
  /// In en, this message translates to:
  /// **'Use the buttons above to trigger requests.'**
  String get pendingUseButtons;

  /// No description provided for @pendingRequestCancelled.
  ///
  /// In en, this message translates to:
  /// **'Request cancelled'**
  String get pendingRequestCancelled;

  /// No description provided for @pendingRequestCancelFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to cancel request'**
  String get pendingRequestCancelFailed;

  /// No description provided for @pendingHeading.
  ///
  /// In en, this message translates to:
  /// **'Pending Signer Requests'**
  String get pendingHeading;

  /// No description provided for @pendingDescription.
  ///
  /// In en, this message translates to:
  /// **'Requests waiting for approval from your signer.'**
  String get pendingDescription;

  /// No description provided for @pendingTriggerRequests.
  ///
  /// In en, this message translates to:
  /// **'Trigger Requests'**
  String get pendingTriggerRequests;

  /// No description provided for @signEvent.
  ///
  /// In en, this message translates to:
  /// **'Sign Event'**
  String get signEvent;

  /// No description provided for @encrypt.
  ///
  /// In en, this message translates to:
  /// **'Encrypt'**
  String get encrypt;

  /// No description provided for @decrypt.
  ///
  /// In en, this message translates to:
  /// **'Decrypt'**
  String get decrypt;

  /// No description provided for @pendingSignedResult.
  ///
  /// In en, this message translates to:
  /// **'Signed! ID: {value}'**
  String pendingSignedResult(Object value);

  /// No description provided for @pendingSignFailed.
  ///
  /// In en, this message translates to:
  /// **'Sign failed: {error}'**
  String pendingSignFailed(Object error);

  /// No description provided for @pendingEncryptFirst.
  ///
  /// In en, this message translates to:
  /// **'Encrypt first to get ciphertext.'**
  String get pendingEncryptFirst;

  /// No description provided for @pendingEncryptedResult.
  ///
  /// In en, this message translates to:
  /// **'Encrypted: {value}'**
  String pendingEncryptedResult(Object value);

  /// No description provided for @pendingEncryptFailed.
  ///
  /// In en, this message translates to:
  /// **'Encrypt failed: {error}'**
  String pendingEncryptFailed(Object error);

  /// No description provided for @pendingDecryptedResult.
  ///
  /// In en, this message translates to:
  /// **'Decrypted: {value}'**
  String pendingDecryptedResult(Object value);

  /// No description provided for @pendingDecryptFailed.
  ///
  /// In en, this message translates to:
  /// **'Decrypt failed: {error}'**
  String pendingDecryptFailed(Object error);

  /// No description provided for @pendingMethodSignEvent.
  ///
  /// In en, this message translates to:
  /// **'Sign Event'**
  String get pendingMethodSignEvent;

  /// No description provided for @pendingMethodGetPublicKey.
  ///
  /// In en, this message translates to:
  /// **'Get Public Key'**
  String get pendingMethodGetPublicKey;

  /// No description provided for @pendingMethodNip04Encrypt.
  ///
  /// In en, this message translates to:
  /// **'NIP-04 Encrypt'**
  String get pendingMethodNip04Encrypt;

  /// No description provided for @pendingMethodNip04Decrypt.
  ///
  /// In en, this message translates to:
  /// **'NIP-04 Decrypt'**
  String get pendingMethodNip04Decrypt;

  /// No description provided for @pendingMethodNip44Encrypt.
  ///
  /// In en, this message translates to:
  /// **'NIP-44 Encrypt'**
  String get pendingMethodNip44Encrypt;

  /// No description provided for @pendingMethodNip44Decrypt.
  ///
  /// In en, this message translates to:
  /// **'NIP-44 Decrypt'**
  String get pendingMethodNip44Decrypt;

  /// No description provided for @pendingMethodPing.
  ///
  /// In en, this message translates to:
  /// **'Ping'**
  String get pendingMethodPing;

  /// No description provided for @pendingMethodConnect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get pendingMethodConnect;

  /// No description provided for @pendingSecondsAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}s ago'**
  String pendingSecondsAgo(int count);

  /// No description provided for @pendingMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}m ago'**
  String pendingMinutesAgo(int count);

  /// No description provided for @pendingHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}h ago'**
  String pendingHoursAgo(int count);

  /// No description provided for @pendingEventKind.
  ///
  /// In en, this message translates to:
  /// **'Event Kind: {value}'**
  String pendingEventKind(Object value);

  /// No description provided for @pendingContent.
  ///
  /// In en, this message translates to:
  /// **'Content: {value}'**
  String pendingContent(Object value);

  /// No description provided for @pendingCounterparty.
  ///
  /// In en, this message translates to:
  /// **'Counterparty: {value}...'**
  String pendingCounterparty(Object value);

  /// No description provided for @pendingPlaintext.
  ///
  /// In en, this message translates to:
  /// **'Plaintext: {value}'**
  String pendingPlaintext(Object value);

  /// No description provided for @pendingCiphertext.
  ///
  /// In en, this message translates to:
  /// **'Ciphertext: {value}...'**
  String pendingCiphertext(Object value);

  /// No description provided for @pendingId.
  ///
  /// In en, this message translates to:
  /// **'ID: {value}'**
  String pendingId(Object value);

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;
}

class _SampleAppLocalizationsDelegate
    extends LocalizationsDelegate<SampleAppLocalizations> {
  const _SampleAppLocalizationsDelegate();

  @override
  Future<SampleAppLocalizations> load(Locale locale) {
    return SynchronousFuture<SampleAppLocalizations>(
        lookupSampleAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
        'de',
        'en',
        'es',
        'fr',
        'it',
        'ja',
        'pl',
        'ru',
        'zh'
      ].contains(locale.languageCode);

  @override
  bool shouldReload(_SampleAppLocalizationsDelegate old) => false;
}

SampleAppLocalizations lookupSampleAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return SampleAppLocalizationsDe();
    case 'en':
      return SampleAppLocalizationsEn();
    case 'es':
      return SampleAppLocalizationsEs();
    case 'fr':
      return SampleAppLocalizationsFr();
    case 'it':
      return SampleAppLocalizationsIt();
    case 'ja':
      return SampleAppLocalizationsJa();
    case 'pl':
      return SampleAppLocalizationsPl();
    case 'ru':
      return SampleAppLocalizationsRu();
    case 'zh':
      return SampleAppLocalizationsZh();
  }

  throw FlutterError(
      'SampleAppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
