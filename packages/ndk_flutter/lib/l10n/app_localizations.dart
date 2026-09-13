import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fi.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_it.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_pl.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_sk.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
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
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

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
    Locale('fi'),
    Locale('fr'),
    Locale('it'),
    Locale('ja'),
    Locale('pl'),
    Locale('pt'),
    Locale('pt', 'BR'),
    Locale('ru'),
    Locale('sk'),
    Locale('zh'),
  ];

  /// No description provided for @lnbitsWalletOption.
  ///
  /// In en, this message translates to:
  /// **'LNbits'**
  String get lnbitsWalletOption;

  /// No description provided for @lnbitsConnectionInstructions.
  ///
  /// In en, this message translates to:
  /// **'In LNbits, choose the wallet you want to connect, open it, click API docs, and copy the Admin Key. Paste it below:'**
  String get lnbitsConnectionInstructions;

  /// No description provided for @lnbitsAdminKey.
  ///
  /// In en, this message translates to:
  /// **'LNbits Admin Key'**
  String get lnbitsAdminKey;

  /// No description provided for @lnbitsKeyType.
  ///
  /// In en, this message translates to:
  /// **'LNbits key type'**
  String get lnbitsKeyType;

  /// No description provided for @lnbitsInvoiceReadKey.
  ///
  /// In en, this message translates to:
  /// **'LNbits invoice/read key'**
  String get lnbitsInvoiceReadKey;

  /// No description provided for @lnbitsReadOnlyDescription.
  ///
  /// In en, this message translates to:
  /// **'Receive-only wallet: view balance and history, and create invoices. Sending payments is disabled.'**
  String get lnbitsReadOnlyDescription;

  /// No description provided for @lnbitsUrl.
  ///
  /// In en, this message translates to:
  /// **'LNbits URL'**
  String get lnbitsUrl;

  /// No description provided for @lnbitsCredentialsRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter both the LNbits Admin Key and URL.'**
  String get lnbitsCredentialsRequired;

  /// No description provided for @lnbitsWalletAdded.
  ///
  /// In en, this message translates to:
  /// **'LNbits wallet added successfully'**
  String get lnbitsWalletAdded;

  /// No description provided for @walletDetailWalletId.
  ///
  /// In en, this message translates to:
  /// **'Wallet ID'**
  String get walletDetailWalletId;

  /// No description provided for @saveBackupToFile.
  ///
  /// In en, this message translates to:
  /// **'Save backup to file'**
  String get saveBackupToFile;

  /// No description provided for @backupSavedToFile.
  ///
  /// In en, this message translates to:
  /// **'Backup saved to file'**
  String get backupSavedToFile;

  /// No description provided for @restoreFromFile.
  ///
  /// In en, this message translates to:
  /// **'Restore from file'**
  String get restoreFromFile;

  /// No description provided for @backupFileReadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not read the selected backup file.'**
  String get backupFileReadFailed;

  /// No description provided for @fetchingWalletConnectionInfo.
  ///
  /// In en, this message translates to:
  /// **'Fetching wallet connection info…'**
  String get fetchingWalletConnectionInfo;

  /// Button text for creating a new account
  ///
  /// In en, this message translates to:
  /// **'Create your account'**
  String get createAccount;

  /// Question asking if the user is new to the platform
  ///
  /// In en, this message translates to:
  /// **'Are you new here?'**
  String get newHere;

  /// Label for nostr address input field
  ///
  /// In en, this message translates to:
  /// **'Nostr Address'**
  String get nostrAddress;

  /// Label for public key input field
  ///
  /// In en, this message translates to:
  /// **'Public Key'**
  String get publicKey;

  /// Label for private key input field
  ///
  /// In en, this message translates to:
  /// **'Private Key (insecure)'**
  String get privateKey;

  /// Label for browser extension login section
  ///
  /// In en, this message translates to:
  /// **'Browser extension'**
  String get browserExtension;

  /// Button text to connect with browser extension
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get connect;

  /// Button text to install browser extension
  ///
  /// In en, this message translates to:
  /// **'Install'**
  String get install;

  /// Button text to logout from the application
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// Placeholder text for nostr address input field
  ///
  /// In en, this message translates to:
  /// **'name@example.com'**
  String get nostrAddressHint;

  /// Error message for invalid nostr address
  ///
  /// In en, this message translates to:
  /// **'Invalid Address'**
  String get invalidAddress;

  /// Error message when unable to connect to nostr address
  ///
  /// In en, this message translates to:
  /// **'Unable to connect'**
  String get unableToConnect;

  /// Placeholder text for public key input field
  ///
  /// In en, this message translates to:
  /// **'npub1...'**
  String get publicKeyHint;

  /// Placeholder text for private key input field
  ///
  /// In en, this message translates to:
  /// **'nsec1...'**
  String get privateKeyHint;

  /// Question asking if the user is new to Nostr
  ///
  /// In en, this message translates to:
  /// **'New to Nostr?'**
  String get newToNostr;

  /// Button text to get started with Nostr
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// Label for bunker login section
  ///
  /// In en, this message translates to:
  /// **'Bunker'**
  String get bunker;

  /// Title for bunker authentication toast
  ///
  /// In en, this message translates to:
  /// **'Bunker Authentication'**
  String get bunkerAuthentication;

  /// Description for bunker authentication toast
  ///
  /// In en, this message translates to:
  /// **'Tap to open: {url}'**
  String tapToOpen(String url);

  /// Button text to show nostr connect QR code
  ///
  /// In en, this message translates to:
  /// **'Show nostr connect qrcode'**
  String get showNostrConnectQrcode;

  /// Button text to login with an external Nostr signer app
  ///
  /// In en, this message translates to:
  /// **'Login with signer app'**
  String get loginWithSignerApp;

  /// Title for nostr connect URL dialog
  ///
  /// In en, this message translates to:
  /// **'Nostr connect URL'**
  String get nostrConnectUrl;

  /// Button text to copy to clipboard
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// Button text to add a new account
  ///
  /// In en, this message translates to:
  /// **'Add account'**
  String get addAccount;

  /// Label for read-only account type
  ///
  /// In en, this message translates to:
  /// **'Read-only'**
  String get readOnly;

  /// Label for nsec (private key) account type
  ///
  /// In en, this message translates to:
  /// **'Nsec'**
  String get nsec;

  /// Label for browser extension account type
  ///
  /// In en, this message translates to:
  /// **'Extension'**
  String get extension;

  /// Nostr event kind 0
  ///
  /// In en, this message translates to:
  /// **'User Metadata'**
  String get userMetadata;

  /// Nostr event kind 1
  ///
  /// In en, this message translates to:
  /// **'Short Text Note'**
  String get shortTextNote;

  /// Nostr event kind 2
  ///
  /// In en, this message translates to:
  /// **'Recommend Relay'**
  String get recommendRelay;

  /// Nostr event kind 3
  ///
  /// In en, this message translates to:
  /// **'Follows'**
  String get follows;

  /// Nostr event kind 4
  ///
  /// In en, this message translates to:
  /// **'Encrypted Direct Messages'**
  String get encryptedDirectMessages;

  /// Nostr event kind 5
  ///
  /// In en, this message translates to:
  /// **'Event Deletion Request'**
  String get eventDeletionRequest;

  /// Nostr event kind 6
  ///
  /// In en, this message translates to:
  /// **'Repost'**
  String get repost;

  /// Nostr event kind 7
  ///
  /// In en, this message translates to:
  /// **'Reaction'**
  String get reaction;

  /// Nostr event kind 8
  ///
  /// In en, this message translates to:
  /// **'Badge Award'**
  String get badgeAward;

  /// Nostr event kind 9
  ///
  /// In en, this message translates to:
  /// **'Chat Message'**
  String get chatMessage;

  /// Nostr event kind 10
  ///
  /// In en, this message translates to:
  /// **'Group Chat Threaded Reply'**
  String get groupChatThreadedReply;

  /// Nostr event kind 11
  ///
  /// In en, this message translates to:
  /// **'Thread'**
  String get thread;

  /// Nostr event kind 12
  ///
  /// In en, this message translates to:
  /// **'Group Thread Reply'**
  String get groupThreadReply;

  /// Nostr event kind 13
  ///
  /// In en, this message translates to:
  /// **'Seal'**
  String get seal;

  /// Nostr event kind 14
  ///
  /// In en, this message translates to:
  /// **'Direct Message'**
  String get directMessage;

  /// Nostr event kind 15
  ///
  /// In en, this message translates to:
  /// **'File Message'**
  String get fileMessage;

  /// Nostr event kind 16
  ///
  /// In en, this message translates to:
  /// **'Generic Repost'**
  String get genericRepost;

  /// Nostr event kind 17
  ///
  /// In en, this message translates to:
  /// **'Reaction to a website'**
  String get reactionToWebsite;

  /// Nostr event kind 20
  ///
  /// In en, this message translates to:
  /// **'Picture'**
  String get picture;

  /// Nostr event kind 21
  ///
  /// In en, this message translates to:
  /// **'Video Event'**
  String get videoEvent;

  /// Nostr event kind 22
  ///
  /// In en, this message translates to:
  /// **'Short-form Portrait Video Event'**
  String get shortFormPortraitVideoEvent;

  /// Nostr event kind 30
  ///
  /// In en, this message translates to:
  /// **'Internal reference'**
  String get internalReference;

  /// Nostr event kind 31
  ///
  /// In en, this message translates to:
  /// **'External reference'**
  String get externalReference;

  /// Nostr event kind 32
  ///
  /// In en, this message translates to:
  /// **'Hardcopy reference'**
  String get hardcopyReference;

  /// Nostr event kind 33
  ///
  /// In en, this message translates to:
  /// **'Prompt reference'**
  String get promptReference;

  /// Nostr event kind 40
  ///
  /// In en, this message translates to:
  /// **'Channel Creation'**
  String get channelCreation;

  /// Nostr event kind 41
  ///
  /// In en, this message translates to:
  /// **'Channel Metadata'**
  String get channelMetadata;

  /// Nostr event kind 42
  ///
  /// In en, this message translates to:
  /// **'Channel Message'**
  String get channelMessage;

  /// Nostr event kind 43
  ///
  /// In en, this message translates to:
  /// **'Channel Hide Message'**
  String get channelHideMessage;

  /// Nostr event kind 44
  ///
  /// In en, this message translates to:
  /// **'Channel Mute User'**
  String get channelMuteUser;

  /// Nostr event kind 62
  ///
  /// In en, this message translates to:
  /// **'Request to Vanish'**
  String get requestToVanish;

  /// Nostr event kind 64
  ///
  /// In en, this message translates to:
  /// **'Chess (PGN)'**
  String get chessPgn;

  /// Nostr event kind 443
  ///
  /// In en, this message translates to:
  /// **'MLS KeyPackage'**
  String get mlsKeyPackage;

  /// Nostr event kind 444
  ///
  /// In en, this message translates to:
  /// **'MLS Welcome'**
  String get mlsWelcome;

  /// Nostr event kind 445
  ///
  /// In en, this message translates to:
  /// **'MLS Group Event'**
  String get mlsGroupEvent;

  /// Nostr event kind 818
  ///
  /// In en, this message translates to:
  /// **'Merge Requests'**
  String get mergeRequests;

  /// Nostr event kind 1018
  ///
  /// In en, this message translates to:
  /// **'Poll Response'**
  String get pollResponse;

  /// Nostr event kind 1021
  ///
  /// In en, this message translates to:
  /// **'Marketplace Bid'**
  String get marketplaceBid;

  /// Nostr event kind 1022
  ///
  /// In en, this message translates to:
  /// **'Marketplace Bid Confirmation'**
  String get marketplaceBidConfirmation;

  /// Nostr event kind 1040
  ///
  /// In en, this message translates to:
  /// **'OpenTimestamps'**
  String get openTimestamps;

  /// Nostr event kind 1059
  ///
  /// In en, this message translates to:
  /// **'Gift Wrap'**
  String get giftWrap;

  /// Nostr event kind 1063
  ///
  /// In en, this message translates to:
  /// **'File Metadata'**
  String get fileMetadata;

  /// Nostr event kind 1068
  ///
  /// In en, this message translates to:
  /// **'Poll'**
  String get poll;

  /// Nostr event kind 1111
  ///
  /// In en, this message translates to:
  /// **'Comment'**
  String get comment;

  /// Nostr event kind 1222
  ///
  /// In en, this message translates to:
  /// **'Voice Message'**
  String get voiceMessage;

  /// Nostr event kind 1244
  ///
  /// In en, this message translates to:
  /// **'Voice Message Comment'**
  String get voiceMessageComment;

  /// Nostr event kind 1311
  ///
  /// In en, this message translates to:
  /// **'Live Chat Message'**
  String get liveChatMessage;

  /// Nostr event kind 1337
  ///
  /// In en, this message translates to:
  /// **'Code Snippet'**
  String get codeSnippet;

  /// Nostr event kind 1617
  ///
  /// In en, this message translates to:
  /// **'Git Patch'**
  String get gitPatch;

  /// Nostr event kind 1618
  ///
  /// In en, this message translates to:
  /// **'Git Pull Request'**
  String get gitPullRequest;

  /// Nostr event kind 1619
  ///
  /// In en, this message translates to:
  /// **'Git Status Update'**
  String get gitStatusUpdate;

  /// Nostr event kind 1621
  ///
  /// In en, this message translates to:
  /// **'Git Issue'**
  String get gitIssue;

  /// Nostr event kind 1622
  ///
  /// In en, this message translates to:
  /// **'Git Issue Update'**
  String get gitIssueUpdate;

  /// Nostr event kind 1630
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// Nostr event kind 1631
  ///
  /// In en, this message translates to:
  /// **'Status Update'**
  String get statusUpdate;

  /// Nostr event kind 1632
  ///
  /// In en, this message translates to:
  /// **'Status Delete'**
  String get statusDelete;

  /// Nostr event kind 1633
  ///
  /// In en, this message translates to:
  /// **'Status Reply'**
  String get statusReply;

  /// Nostr event kind 1971
  ///
  /// In en, this message translates to:
  /// **'Problem Tracker'**
  String get problemTracker;

  /// Nostr event kind 1984
  ///
  /// In en, this message translates to:
  /// **'Reporting'**
  String get reporting;

  /// Nostr event kind 1985
  ///
  /// In en, this message translates to:
  /// **'Label'**
  String get label;

  /// Nostr event kind 1986
  ///
  /// In en, this message translates to:
  /// **'Relay reviews'**
  String get relayReviews;

  /// Nostr event kind 1987
  ///
  /// In en, this message translates to:
  /// **'AI Embeddings / Vector lists'**
  String get aiEmbeddings;

  /// Nostr event kind 2003
  ///
  /// In en, this message translates to:
  /// **'Torrent'**
  String get torrent;

  /// Nostr event kind 2004
  ///
  /// In en, this message translates to:
  /// **'Torrent Comment'**
  String get torrentComment;

  /// Nostr event kind 2022
  ///
  /// In en, this message translates to:
  /// **'Coinjoin Pool'**
  String get coinjoinPool;

  /// Nostr event kind 4550
  ///
  /// In en, this message translates to:
  /// **'Community Post Approval'**
  String get communityPostApproval;

  /// Nostr event kinds 5000-5999
  ///
  /// In en, this message translates to:
  /// **'Job Request'**
  String get jobRequest;

  /// Nostr event kinds 6000-6999
  ///
  /// In en, this message translates to:
  /// **'Job Result'**
  String get jobResult;

  /// Nostr event kind 7000
  ///
  /// In en, this message translates to:
  /// **'Job Feedback'**
  String get jobFeedback;

  /// Nostr event kind 7374
  ///
  /// In en, this message translates to:
  /// **'Cashu Wallet Token'**
  String get cashuWalletToken;

  /// Nostr event kind 7375
  ///
  /// In en, this message translates to:
  /// **'Cashu Wallet Proofs'**
  String get cashuWalletProofs;

  /// Nostr event kind 7376
  ///
  /// In en, this message translates to:
  /// **'Cashu Wallet History'**
  String get cashuWalletHistory;

  /// Nostr event kind 7516
  ///
  /// In en, this message translates to:
  /// **'Geocache Create'**
  String get geocacheCreate;

  /// Nostr event kind 7517
  ///
  /// In en, this message translates to:
  /// **'Geocache Update'**
  String get geocacheUpdate;

  /// Nostr event kinds 9000-9030
  ///
  /// In en, this message translates to:
  /// **'Group Control Event'**
  String get groupControlEvent;

  /// Nostr event kind 9041
  ///
  /// In en, this message translates to:
  /// **'Zap Goal'**
  String get zapGoal;

  /// Nostr event kind 9321
  ///
  /// In en, this message translates to:
  /// **'Nutzap'**
  String get nutzap;

  /// Nostr event kind 9467
  ///
  /// In en, this message translates to:
  /// **'Tidal login'**
  String get tidalLogin;

  /// Nostr event kind 9734
  ///
  /// In en, this message translates to:
  /// **'Zap Request'**
  String get zapRequest;

  /// Nostr event kind 9735
  ///
  /// In en, this message translates to:
  /// **'Zap'**
  String get zap;

  /// Nostr event kind 9802
  ///
  /// In en, this message translates to:
  /// **'Highlights'**
  String get highlights;

  /// Nostr event kind 10000
  ///
  /// In en, this message translates to:
  /// **'Mute List'**
  String get muteList;

  /// Nostr event kind 10001
  ///
  /// In en, this message translates to:
  /// **'Pin List'**
  String get pinList;

  /// Nostr event kind 10002
  ///
  /// In en, this message translates to:
  /// **'Relay List Metadata'**
  String get relayListMetadata;

  /// Nostr event kind 10003
  ///
  /// In en, this message translates to:
  /// **'Bookmark List'**
  String get bookmarkList;

  /// Nostr event kind 10004
  ///
  /// In en, this message translates to:
  /// **'Communities List'**
  String get communitiesList;

  /// Nostr event kind 10005
  ///
  /// In en, this message translates to:
  /// **'Public Chats List'**
  String get publicChatsList;

  /// Nostr event kind 10006
  ///
  /// In en, this message translates to:
  /// **'Blocked Relays List'**
  String get blockedRelaysList;

  /// Nostr event kind 10007
  ///
  /// In en, this message translates to:
  /// **'Search Relays List'**
  String get searchRelaysList;

  /// Nostr event kind 10009
  ///
  /// In en, this message translates to:
  /// **'User Groups'**
  String get userGroups;

  /// Nostr event kind 10012
  ///
  /// In en, this message translates to:
  /// **'Favorites List'**
  String get favoritesList;

  /// Nostr event kind 10013
  ///
  /// In en, this message translates to:
  /// **'Private Events List'**
  String get privateEventsList;

  /// Nostr event kind 10015
  ///
  /// In en, this message translates to:
  /// **'Interests List'**
  String get interestsList;

  /// Nostr event kind 10019
  ///
  /// In en, this message translates to:
  /// **'Media Follows List'**
  String get mediaFollowsList;

  /// Nostr event kind 10020
  ///
  /// In en, this message translates to:
  /// **'People Follows List'**
  String get peopleFollowsList;

  /// Nostr event kind 10030
  ///
  /// In en, this message translates to:
  /// **'User Emoji List'**
  String get userEmojiList;

  /// Nostr event kind 10050
  ///
  /// In en, this message translates to:
  /// **'DM Relay List'**
  String get dmRelayList;

  /// Nostr event kind 10051
  ///
  /// In en, this message translates to:
  /// **'KeyPackage Relay List'**
  String get keyPackageRelayList;

  /// Nostr event kind 10063
  ///
  /// In en, this message translates to:
  /// **'User Server List'**
  String get userServerList;

  /// Nostr event kind 10096
  ///
  /// In en, this message translates to:
  /// **'File Storage Server List'**
  String get fileStorageServerList;

  /// Nostr event kind 10166
  ///
  /// In en, this message translates to:
  /// **'Relay Monitor Announcement'**
  String get relayMonitorAnnouncement;

  /// Nostr event kind 10312
  ///
  /// In en, this message translates to:
  /// **'Room Presence'**
  String get roomPresence;

  /// Nostr event kind 10377
  ///
  /// In en, this message translates to:
  /// **'Proxy Announcement'**
  String get proxyAnnouncement;

  /// Nostr event kind 11111
  ///
  /// In en, this message translates to:
  /// **'Transport Method Announcement'**
  String get transportMethodAnnouncement;

  /// Nostr event kind 13194
  ///
  /// In en, this message translates to:
  /// **'Wallet Info'**
  String get walletInfo;

  /// Nostr event kind 17375
  ///
  /// In en, this message translates to:
  /// **'Cashu Wallet Event'**
  String get cashuWalletEvent;

  /// Nostr event kind 21000
  ///
  /// In en, this message translates to:
  /// **'Lightning Pub RPC'**
  String get lightningPubRpc;

  /// Nostr event kind 22242
  ///
  /// In en, this message translates to:
  /// **'Client Authentication'**
  String get clientAuthentication;

  /// Nostr event kind 23194
  ///
  /// In en, this message translates to:
  /// **'Wallet Request'**
  String get walletRequest;

  /// Nostr event kind 23195
  ///
  /// In en, this message translates to:
  /// **'Wallet Response'**
  String get walletResponse;

  /// Nostr event kind 24133
  ///
  /// In en, this message translates to:
  /// **'Nostr Connect'**
  String get nostrConnectEvent;

  /// Nostr event kind 24242
  ///
  /// In en, this message translates to:
  /// **'Blobs stored on mediaservers'**
  String get blobsStoredOnMediaservers;

  /// Nostr event kind 27235
  ///
  /// In en, this message translates to:
  /// **'HTTP Auth'**
  String get httpAuth;

  /// Nostr event kind 30000
  ///
  /// In en, this message translates to:
  /// **'Categorized People List'**
  String get categorizedPeopleList;

  /// Nostr event kind 30001
  ///
  /// In en, this message translates to:
  /// **'Categorized Bookmark List'**
  String get categorizedBookmarkList;

  /// Nostr event kind 30002
  ///
  /// In en, this message translates to:
  /// **'Categorized Relay List'**
  String get categorizedRelayList;

  /// Nostr event kind 30003
  ///
  /// In en, this message translates to:
  /// **'Bookmark Sets'**
  String get bookmarkSets;

  /// Nostr event kind 30004
  ///
  /// In en, this message translates to:
  /// **'Curation Sets'**
  String get curationSets;

  /// Nostr event kind 30005
  ///
  /// In en, this message translates to:
  /// **'Video Sets'**
  String get videoSets;

  /// Nostr event kind 30007
  ///
  /// In en, this message translates to:
  /// **'Kind Mute Sets'**
  String get kindMuteSets;

  /// Nostr event kind 30008
  ///
  /// In en, this message translates to:
  /// **'Profile Badges'**
  String get profileBadges;

  /// Nostr event kind 30009
  ///
  /// In en, this message translates to:
  /// **'Badge Definition'**
  String get badgeDefinition;

  /// Nostr event kind 30015
  ///
  /// In en, this message translates to:
  /// **'Interest Sets'**
  String get interestSets;

  /// Nostr event kind 30017
  ///
  /// In en, this message translates to:
  /// **'Create or Update Stall'**
  String get createOrUpdateStall;

  /// Nostr event kind 30018
  ///
  /// In en, this message translates to:
  /// **'Create or Update Product'**
  String get createOrUpdateProduct;

  /// Nostr event kind 30019
  ///
  /// In en, this message translates to:
  /// **'Marketplace UI/UX'**
  String get marketplaceUiUx;

  /// Nostr event kind 30020
  ///
  /// In en, this message translates to:
  /// **'Product Sold as Auction'**
  String get productSoldAsAuction;

  /// Nostr event kind 30023
  ///
  /// In en, this message translates to:
  /// **'Long-form Content'**
  String get longFormContent;

  /// Nostr event kind 30024
  ///
  /// In en, this message translates to:
  /// **'Draft Long-form Content'**
  String get draftLongFormContent;

  /// Nostr event kind 30030
  ///
  /// In en, this message translates to:
  /// **'Emoji Sets'**
  String get emojiSets;

  /// Nostr event kind 30040
  ///
  /// In en, this message translates to:
  /// **'Curated Publication Item'**
  String get curatedPublicationItem;

  /// Nostr event kind 30041
  ///
  /// In en, this message translates to:
  /// **'Curated Publication Draft'**
  String get curatedPublicationDraft;

  /// Nostr event kind 30063
  ///
  /// In en, this message translates to:
  /// **'Release Artifact Sets'**
  String get releaseArtifactSets;

  /// Nostr event kind 30078
  ///
  /// In en, this message translates to:
  /// **'Application-specific Data'**
  String get applicationSpecificData;

  /// Nostr event kind 30166
  ///
  /// In en, this message translates to:
  /// **'Relay Discovery'**
  String get relayDiscovery;

  /// Nostr event kind 30267
  ///
  /// In en, this message translates to:
  /// **'App Curation Sets'**
  String get appCurationSets;

  /// Nostr event kind 30311
  ///
  /// In en, this message translates to:
  /// **'Live Event'**
  String get liveEvent;

  /// Nostr event kind 30315
  ///
  /// In en, this message translates to:
  /// **'User Status'**
  String get userStatus;

  /// Nostr event kind 30388
  ///
  /// In en, this message translates to:
  /// **'Slide Set'**
  String get slideSet;

  /// Nostr event kind 30402
  ///
  /// In en, this message translates to:
  /// **'Classified Listing'**
  String get classifiedListing;

  /// Nostr event kind 30403
  ///
  /// In en, this message translates to:
  /// **'Draft Classified Listing'**
  String get draftClassifiedListing;

  /// Nostr event kind 30617
  ///
  /// In en, this message translates to:
  /// **'Repository Announcement'**
  String get repositoryAnnouncement;

  /// Nostr event kind 30618
  ///
  /// In en, this message translates to:
  /// **'Repository State Announcement'**
  String get repositoryStateAnnouncement;

  /// Nostr event kind 30818
  ///
  /// In en, this message translates to:
  /// **'Wiki Article'**
  String get wikiArticle;

  /// Nostr event kind 30819
  ///
  /// In en, this message translates to:
  /// **'Redirects'**
  String get redirects;

  /// Nostr event kind 31234
  ///
  /// In en, this message translates to:
  /// **'Draft Event'**
  String get draftEvent;

  /// Nostr event kind 31388
  ///
  /// In en, this message translates to:
  /// **'Link Set'**
  String get linkSet;

  /// Nostr event kind 31890
  ///
  /// In en, this message translates to:
  /// **'Feed'**
  String get feed;

  /// Nostr event kind 31922
  ///
  /// In en, this message translates to:
  /// **'Date-Based Calendar Event'**
  String get dateBasedCalendarEvent;

  /// Nostr event kind 31923
  ///
  /// In en, this message translates to:
  /// **'Time-Based Calendar Event'**
  String get timeBasedCalendarEvent;

  /// Nostr event kind 31924
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get calendar;

  /// Nostr event kind 31925
  ///
  /// In en, this message translates to:
  /// **'Calendar Event RSVP'**
  String get calendarEventRsvp;

  /// Nostr event kind 31989
  ///
  /// In en, this message translates to:
  /// **'Handler Recommendation'**
  String get handlerRecommendation;

  /// Nostr event kind 31990
  ///
  /// In en, this message translates to:
  /// **'Handler Information'**
  String get handlerInformation;

  /// Nostr event kind 32267
  ///
  /// In en, this message translates to:
  /// **'Software Application'**
  String get softwareApplication;

  /// Nostr event kind 34237
  ///
  /// In en, this message translates to:
  /// **'Video View'**
  String get videoView;

  /// Nostr event kind 34550
  ///
  /// In en, this message translates to:
  /// **'Community Definition'**
  String get communityDefinition;

  /// Nostr event kind 37516
  ///
  /// In en, this message translates to:
  /// **'Geocache Listing'**
  String get geocacheListing;

  /// Nostr event kind 38172
  ///
  /// In en, this message translates to:
  /// **'Mint Announcement'**
  String get mintAnnouncement;

  /// Nostr event kind 38173
  ///
  /// In en, this message translates to:
  /// **'Mint Quote'**
  String get mintQuote;

  /// Nostr event kind 38383
  ///
  /// In en, this message translates to:
  /// **'Peer-to-peer Order'**
  String get peerToPeerOrder;

  /// Nostr event kind 39000
  ///
  /// In en, this message translates to:
  /// **'Group Metadata'**
  String get groupMetadata;

  /// Nostr event kind 39001
  ///
  /// In en, this message translates to:
  /// **'Group Admin Metadata'**
  String get groupAdminMetadata;

  /// Nostr event kind 39002
  ///
  /// In en, this message translates to:
  /// **'Group Member Metadata'**
  String get groupMemberMetadata;

  /// Nostr event kind 39003
  ///
  /// In en, this message translates to:
  /// **'Group Admins List'**
  String get groupAdminsList;

  /// Nostr event kind 39004
  ///
  /// In en, this message translates to:
  /// **'Group Members List'**
  String get groupMembersList;

  /// Nostr event kind 39005
  ///
  /// In en, this message translates to:
  /// **'Group Roles'**
  String get groupRoles;

  /// Nostr event kind 39006
  ///
  /// In en, this message translates to:
  /// **'Group Permissions'**
  String get groupPermissions;

  /// Nostr event kind 39007
  ///
  /// In en, this message translates to:
  /// **'Group Chat Message'**
  String get groupChatMessage;

  /// Nostr event kind 39008
  ///
  /// In en, this message translates to:
  /// **'Group Chat Thread'**
  String get groupChatThread;

  /// Nostr event kind 39009
  ///
  /// In en, this message translates to:
  /// **'Group Pinned'**
  String get groupPinned;

  /// Nostr event kind 39089
  ///
  /// In en, this message translates to:
  /// **'Starter Packs'**
  String get starterPacks;

  /// Nostr event kind 39092
  ///
  /// In en, this message translates to:
  /// **'Media Starter Packs'**
  String get mediaStarterPacks;

  /// Nostr event kind 39701
  ///
  /// In en, this message translates to:
  /// **'Web Bookmarks'**
  String get webBookmarks;

  /// Fallback for unknown event kinds
  ///
  /// In en, this message translates to:
  /// **'Event Kind {kind}'**
  String unknownEventKind(int kind);

  /// Title for wallets section
  ///
  /// In en, this message translates to:
  /// **'Wallets'**
  String get walletsTitle;

  /// Title for recent activity section
  ///
  /// In en, this message translates to:
  /// **'Recent Activity'**
  String get recentActivityTitle;

  /// Label for add Cashu wallet button
  ///
  /// In en, this message translates to:
  /// **'Add Cashu Wallet'**
  String get addCashuWallet;

  /// Label for add NWC wallet button
  ///
  /// In en, this message translates to:
  /// **'Add NWC Wallet'**
  String get addNwcWallet;

  /// Label for add LNURL wallet button
  ///
  /// In en, this message translates to:
  /// **'Add LNURL Wallet'**
  String get addLnurlWallet;

  /// Tooltip for add Cashu wallet button
  ///
  /// In en, this message translates to:
  /// **'Add Cashu Wallet'**
  String get addCashuTooltip;

  /// Tooltip for add NWC wallet button
  ///
  /// In en, this message translates to:
  /// **'Add NWC Wallet'**
  String get addNwcTooltip;

  /// Tooltip for add LNURL wallet button
  ///
  /// In en, this message translates to:
  /// **'Add LNURL Wallet'**
  String get addLnurlTooltip;

  /// Title for add Cashu wallet dialog
  ///
  /// In en, this message translates to:
  /// **'Add Cashu Wallet'**
  String get addCashuWalletTitle;

  /// Prompt for mint URL input
  ///
  /// In en, this message translates to:
  /// **'Enter the mint URL to add a Cashu wallet.'**
  String get enterMintUrl;

  /// Label for mint URL input
  ///
  /// In en, this message translates to:
  /// **'Mint URL'**
  String get mintUrl;

  /// Hint for mint URL input
  ///
  /// In en, this message translates to:
  /// **'https://mint.example.com'**
  String get mintUrlHint;

  /// Error message for empty mint URL
  ///
  /// In en, this message translates to:
  /// **'Please enter a mint URL'**
  String get pleaseEnterMintUrl;

  /// Success message when Cashu wallet is added
  ///
  /// In en, this message translates to:
  /// **'Cashu wallet added successfully!'**
  String get cashuWalletAdded;

  /// Error message when adding Cashu wallet fails
  ///
  /// In en, this message translates to:
  /// **'Failed to add mint. Please check the URL and try again.'**
  String get failedToAddMint;

  /// Title for add NWC wallet dialog
  ///
  /// In en, this message translates to:
  /// **'Add NWC Wallet'**
  String get addNwcWalletTitle;

  /// Tab label for faucet option
  ///
  /// In en, this message translates to:
  /// **'Faucet'**
  String get faucet;

  /// Tab label for manual option
  ///
  /// In en, this message translates to:
  /// **'Manual'**
  String get manual;

  /// Description for NWC faucet
  ///
  /// In en, this message translates to:
  /// **'Create a test wallet with sats from the NWC faucet.'**
  String get nwcFaucetDescription;

  /// Label for starting balance input
  ///
  /// In en, this message translates to:
  /// **'Starting Balance'**
  String get startingBalance;

  /// Hint for starting balance input
  ///
  /// In en, this message translates to:
  /// **'10000'**
  String get startingBalanceHint;

  /// Label for NWC connection URI input
  ///
  /// In en, this message translates to:
  /// **'NWC Connection URI'**
  String get nwcConnectionUri;

  /// Hint for NWC connection URI input
  ///
  /// In en, this message translates to:
  /// **'nostr+walletconnect://...'**
  String get nwcConnectionUriHint;

  /// Success message when NWC wallet is added
  ///
  /// In en, this message translates to:
  /// **'NWC wallet added successfully!'**
  String get nwcWalletAdded;

  /// Success message when NWC faucet wallet is added
  ///
  /// In en, this message translates to:
  /// **'NWC faucet wallet added with {balance} sats!'**
  String nwcFaucetWalletAdded(int balance);

  /// Error message for invalid faucet response
  ///
  /// In en, this message translates to:
  /// **'Invalid response from faucet'**
  String get invalidFaucetResponse;

  /// Error message when creating NWC wallet fails
  ///
  /// In en, this message translates to:
  /// **'Error creating wallet'**
  String get errorCreatingWallet;

  /// Title for add LNURL wallet dialog
  ///
  /// In en, this message translates to:
  /// **'Add LNURL Wallet'**
  String get addLnurlWalletTitle;

  /// Prompt for LNURL identifier input
  ///
  /// In en, this message translates to:
  /// **'Enter your LNURL identifier (user@domain.com).'**
  String get enterLnurlIdentifier;

  /// Hint for LNURL identifier input
  ///
  /// In en, this message translates to:
  /// **'user@example.com'**
  String get lnurlIdentifierHint;

  /// Error message for invalid LNURL identifier
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid identifier (user@domain.com)'**
  String get pleaseEnterValidIdentifier;

  /// Success message when LNURL wallet is added
  ///
  /// In en, this message translates to:
  /// **'LNURL wallet added successfully!'**
  String get lnurlWalletAdded;

  /// Button label for cancel action
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Button label for add action
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// Label for send action
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// Label for receive action
  ///
  /// In en, this message translates to:
  /// **'Receive'**
  String get receive;

  /// Menu option to set wallet as default for receiving
  ///
  /// In en, this message translates to:
  /// **'Set as default for receiving'**
  String get setAsDefaultForReceiving;

  /// Menu option to set wallet as default for sending
  ///
  /// In en, this message translates to:
  /// **'Set as default for sending'**
  String get setAsDefaultForSending;

  /// Menu label for wallet already default for receiving
  ///
  /// In en, this message translates to:
  /// **'Default for receiving'**
  String get defaultForReceiving;

  /// Menu label for wallet already default for sending
  ///
  /// In en, this message translates to:
  /// **'Default for sending'**
  String get defaultForSending;

  /// Tooltip shown on receiving default ribbon
  ///
  /// In en, this message translates to:
  /// **'This wallet is the default one for receiving payments.'**
  String get defaultWalletForReceivingTooltip;

  /// Tooltip shown on sending default ribbon
  ///
  /// In en, this message translates to:
  /// **'This wallet is the default one for sending payments.'**
  String get defaultWalletForSendingTooltip;

  /// Title for send options sheet
  ///
  /// In en, this message translates to:
  /// **'Send Options'**
  String get sendOptionsTitle;

  /// Option for sending by token
  ///
  /// In en, this message translates to:
  /// **'Send by Token'**
  String get sendByToken;

  /// Description for send by token option
  ///
  /// In en, this message translates to:
  /// **'Create a Cashu token to send'**
  String get sendByTokenDescription;

  /// Option for sending by Lightning
  ///
  /// In en, this message translates to:
  /// **'Send by Lightning'**
  String get sendByLightning;

  /// Description for send by Lightning option
  ///
  /// In en, this message translates to:
  /// **'Pay a Lightning invoice'**
  String get sendByLightningDescription;

  /// Title for pay invoice dialog
  ///
  /// In en, this message translates to:
  /// **'Pay Invoice'**
  String get payInvoiceTitle;

  /// No description provided for @sendToWallet.
  ///
  /// In en, this message translates to:
  /// **'Send to Wallet'**
  String get sendToWallet;

  /// No description provided for @sendToWalletDescription.
  ///
  /// In en, this message translates to:
  /// **'Transfer to another compatible wallet'**
  String get sendToWalletDescription;

  /// No description provided for @noCompatibleReceivingWallets.
  ///
  /// In en, this message translates to:
  /// **'No compatible receiving wallets'**
  String get noCompatibleReceivingWallets;

  /// No description provided for @noCompatibleReceivingWalletsDescription.
  ///
  /// In en, this message translates to:
  /// **'Add or connect another wallet that can receive a payment supported by this wallet.'**
  String get noCompatibleReceivingWalletsDescription;

  /// No description provided for @destinationWallet.
  ///
  /// In en, this message translates to:
  /// **'Destination wallet'**
  String get destinationWallet;

  /// No description provided for @walletTransferSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Payment sent to {walletName}'**
  String walletTransferSubmitted(String walletName);

  /// Label for invoice input
  ///
  /// In en, this message translates to:
  /// **'Invoice'**
  String get invoice;

  /// Hint for invoice input
  ///
  /// In en, this message translates to:
  /// **'lnbc...'**
  String get invoiceHint;

  /// Error message for empty invoice
  ///
  /// In en, this message translates to:
  /// **'Please enter an invoice'**
  String get pleaseEnterInvoice;

  /// Success message when invoice is paid
  ///
  /// In en, this message translates to:
  /// **'Invoice paid!'**
  String get invoicePaid;

  /// Error message when payment fails
  ///
  /// In en, this message translates to:
  /// **'Payment failed: {message}'**
  String paymentFailed(String message);

  /// Title for receive options sheet
  ///
  /// In en, this message translates to:
  /// **'Receive Options'**
  String get receiveOptionsTitle;

  /// Option for receiving by token
  ///
  /// In en, this message translates to:
  /// **'Receive by Token'**
  String get receiveByToken;

  /// Description for receive by token option
  ///
  /// In en, this message translates to:
  /// **'Receive a Cashu token'**
  String get receiveByTokenDescription;

  /// Option for receiving by Lightning
  ///
  /// In en, this message translates to:
  /// **'Receive by Lightning'**
  String get receiveByLightning;

  /// Description for receive by Lightning option
  ///
  /// In en, this message translates to:
  /// **'Create a Lightning invoice'**
  String get receiveByLightningDescription;

  /// Title for receive by token dialog
  ///
  /// In en, this message translates to:
  /// **'Receive by Token'**
  String get receiveByTokenTitle;

  /// Label for token input
  ///
  /// In en, this message translates to:
  /// **'Token'**
  String get token;

  /// Hint for token input
  ///
  /// In en, this message translates to:
  /// **'Paste token here...'**
  String get tokenHint;

  /// Error message for empty token
  ///
  /// In en, this message translates to:
  /// **'Please enter a token'**
  String get pleaseEnterToken;

  /// Success message when token is received
  ///
  /// In en, this message translates to:
  /// **'Token received!'**
  String get tokenReceived;

  /// Title for create invoice dialog
  ///
  /// In en, this message translates to:
  /// **'Create Invoice'**
  String get createInvoiceTitle;

  /// Label for amount input
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// Hint for amount input
  ///
  /// In en, this message translates to:
  /// **'100'**
  String get amountHint;

  /// Error message for invalid amount
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid amount'**
  String get pleaseEnterValidAmount;

  /// Success message when token is copied to clipboard
  ///
  /// In en, this message translates to:
  /// **'Token copied to clipboard!'**
  String get tokenCopiedToClipboard;

  /// Success message when invoice is created and copied
  ///
  /// In en, this message translates to:
  /// **'Invoice created and copied!'**
  String get invoiceCreatedAndCopied;

  /// Title for invoice tracking dialog
  ///
  /// In en, this message translates to:
  /// **'Lightning Invoice'**
  String get invoiceTrackingTitle;

  /// Message shown when invoice is created
  ///
  /// In en, this message translates to:
  /// **'Invoice created and copied!'**
  String get invoiceCreatedMessage;

  /// Label for close button
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// Label for copy again button
  ///
  /// In en, this message translates to:
  /// **'Copy Again'**
  String get copyAgain;

  /// Message shown when copied
  ///
  /// In en, this message translates to:
  /// **'Copied!'**
  String get copied;

  /// Message shown when payment is received
  ///
  /// In en, this message translates to:
  /// **'Payment received!'**
  String get paymentReceived;

  /// Status message while waiting for payment
  ///
  /// In en, this message translates to:
  /// **'Waiting for payment...'**
  String get waitingForPayment;

  /// Status message when payment is complete
  ///
  /// In en, this message translates to:
  /// **'Paid!'**
  String get paid;

  /// Label for create token button
  ///
  /// In en, this message translates to:
  /// **'Create Token'**
  String get createToken;

  /// Label for pay button
  ///
  /// In en, this message translates to:
  /// **'Pay'**
  String get pay;

  /// Label for create button
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// Title for pending transactions section
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pendingTransactions;

  /// No description provided for @backupSeedWarning.
  ///
  /// In en, this message translates to:
  /// **'Back up your cashu recovery phrase'**
  String get backupSeedWarning;

  /// No description provided for @backupSeedTitle.
  ///
  /// In en, this message translates to:
  /// **'Back up cashu recovery phrase'**
  String get backupSeedTitle;

  /// No description provided for @backupSeedInstructions.
  ///
  /// In en, this message translates to:
  /// **'Write down these words in order and store them somewhere safe. They are the only way to recover your cashu funds if you lose this device.'**
  String get backupSeedInstructions;

  /// No description provided for @backupSeedConfirm.
  ///
  /// In en, this message translates to:
  /// **'I have written down my recovery phrase and stored it safely'**
  String get backupSeedConfirm;

  /// No description provided for @backupSeedDone.
  ///
  /// In en, this message translates to:
  /// **'I\'ve backed it up'**
  String get backupSeedDone;

  /// Label for the action that retries minting tokens for pending funding transactions
  ///
  /// In en, this message translates to:
  /// **'Reclaim pending funds'**
  String get reclaimPendingFunds;

  /// Title for the reclaim pending funds dialog
  ///
  /// In en, this message translates to:
  /// **'Reclaim Pending Funds'**
  String get reclaimPendingTitle;

  /// Title for recent transactions section
  ///
  /// In en, this message translates to:
  /// **'Recent Transactions'**
  String get recentTransactions;

  /// Message shown when there are no recent transactions
  ///
  /// In en, this message translates to:
  /// **'No recent transactions'**
  String get noRecentTransactions;

  /// Message shown when there are no wallets
  ///
  /// In en, this message translates to:
  /// **'No wallets yet'**
  String get noWalletsYet;

  /// Message shown when no wallets are available
  ///
  /// In en, this message translates to:
  /// **'No wallets available'**
  String get noWalletsAvailable;

  /// Hint to add a wallet
  ///
  /// In en, this message translates to:
  /// **'Tap + to add one'**
  String get tapToAddWallet;

  /// Label for delete action
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// Error message for general errors
  ///
  /// In en, this message translates to:
  /// **'Error: {message}'**
  String error(String message);

  /// Label for unknown wallet type
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknownWalletType;

  /// Label for Cashu wallet type
  ///
  /// In en, this message translates to:
  /// **'Cashu'**
  String get cashuWallet;

  /// Label for NWC wallet type
  ///
  /// In en, this message translates to:
  /// **'NWC'**
  String get nwcWallet;

  /// Label for LNURL wallet type
  ///
  /// In en, this message translates to:
  /// **'LNURL'**
  String get lnurlWallet;

  /// Subtitle for NWC wallet
  ///
  /// In en, this message translates to:
  /// **'NWC Wallet'**
  String get nwcWalletSubtitle;

  /// Label for balance display
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get balance;

  /// Label for sats
  ///
  /// In en, this message translates to:
  /// **'sats'**
  String get sats;

  /// Label shown when a wallet is selected
  ///
  /// In en, this message translates to:
  /// **'SELECTED'**
  String get selected;

  /// Label for receive-only wallet
  ///
  /// In en, this message translates to:
  /// **'Receive-only wallet'**
  String get receiveOnlyWallet;

  /// Label showing receive range for LNURL wallet
  ///
  /// In en, this message translates to:
  /// **'Receive: {min} - {max} sats'**
  String receiveRange(int min, int max);

  /// Message shown when limits are unavailable
  ///
  /// In en, this message translates to:
  /// **'Limits unavailable'**
  String get limitsUnavailable;

  /// Message shown when token is copied
  ///
  /// In en, this message translates to:
  /// **'Token copied'**
  String get tokenCopied;

  /// Title for delete wallet confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Delete Wallet?'**
  String get deleteWalletConfirmation;

  /// Message for delete wallet confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this wallet? This action cannot be undone.'**
  String get deleteWalletConfirmationMessage;

  /// Title for add wallet dialog
  ///
  /// In en, this message translates to:
  /// **'Add Wallet'**
  String get addWalletTitle;

  /// Description for the unified add wallet flow
  ///
  /// In en, this message translates to:
  /// **'Scan any supported wallet QR code, paste its details, or connect through a wallet app.'**
  String get addWalletDescription;

  /// Button for opening the universal wallet QR scanner
  ///
  /// In en, this message translates to:
  /// **'Scan wallet QR code'**
  String get scanWalletQrCode;

  /// Heading for wallet-assisted NWC connection options
  ///
  /// In en, this message translates to:
  /// **'Connect with a wallet'**
  String get connectWithWallet;

  /// Button for opening the standard NWC wallet chooser
  ///
  /// In en, this message translates to:
  /// **'Choose wallet app'**
  String get chooseWalletApp;

  /// No description provided for @oneClickConnect.
  ///
  /// In en, this message translates to:
  /// **'1-click connect'**
  String get oneClickConnect;

  /// No description provided for @chooseWallet.
  ///
  /// In en, this message translates to:
  /// **'Choose wallet'**
  String get chooseWallet;

  /// No description provided for @albyWalletOption.
  ///
  /// In en, this message translates to:
  /// **'Alby'**
  String get albyWalletOption;

  /// No description provided for @albyCloudOption.
  ///
  /// In en, this message translates to:
  /// **'Alby Cloud'**
  String get albyCloudOption;

  /// No description provided for @coinosWalletOption.
  ///
  /// In en, this message translates to:
  /// **'Coinos'**
  String get coinosWalletOption;

  /// No description provided for @manualNwcConnection.
  ///
  /// In en, this message translates to:
  /// **'Manual NWC connection'**
  String get manualNwcConnection;

  /// Prompt shown while an external wallet is authorizing
  ///
  /// In en, this message translates to:
  /// **'Finish connection in {walletName}'**
  String walletConnectionFinishIn(String walletName);

  /// Progress shown while adding an externally authorized wallet
  ///
  /// In en, this message translates to:
  /// **'Connecting {walletName}…'**
  String walletConnectionConnecting(String walletName);

  /// Animated success message after adding a wallet
  ///
  /// In en, this message translates to:
  /// **'{walletName} connected'**
  String walletConnectionConnected(String walletName);

  /// Heading shown when an external wallet connection fails
  ///
  /// In en, this message translates to:
  /// **'Could not connect {walletName}'**
  String walletConnectionFailed(String walletName);

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// Status shown when a wallet's remote service cannot be reached
  ///
  /// In en, this message translates to:
  /// **'Wallet unreachable'**
  String get walletUnreachable;

  /// No description provided for @chooseAnotherWallet.
  ///
  /// In en, this message translates to:
  /// **'Choose another wallet'**
  String get chooseAnotherWallet;

  /// Description for the standard NWC wallet chooser
  ///
  /// In en, this message translates to:
  /// **'Approve an NWC connection in an installed wallet'**
  String get chooseWalletAppDescription;

  /// Label for unified wallet input
  ///
  /// In en, this message translates to:
  /// **'Wallet address or connection'**
  String get walletInput;

  /// Hint listing supported wallet inputs
  ///
  /// In en, this message translates to:
  /// **'NWC, Lightning/BIP353 address, BOLT12/BIP321 offer, or HTTPS Cashu mint URL'**
  String get walletInputHint;

  /// Error for an unrecognized unified wallet input
  ///
  /// In en, this message translates to:
  /// **'This is not a supported wallet address or connection.'**
  String get unsupportedWalletInput;

  /// Label shown before a detected wallet type
  ///
  /// In en, this message translates to:
  /// **'Detected'**
  String get detected;

  /// Detected type label for an ambiguous user at domain address
  ///
  /// In en, this message translates to:
  /// **'Lightning or BIP353 address'**
  String get lightningAddressInputType;

  /// Button revealing type-specific manual wallet setup
  ///
  /// In en, this message translates to:
  /// **'Set up manually'**
  String get manualWalletSetup;

  /// Prompt to choose wallet type
  ///
  /// In en, this message translates to:
  /// **'Choose wallet type'**
  String get chooseWalletType;

  /// Title for the NWC wallet type option
  ///
  /// In en, this message translates to:
  /// **'Nostr Wallet Connect'**
  String get nwcWalletTypeTitle;

  /// Subtitle for the NWC wallet type option
  ///
  /// In en, this message translates to:
  /// **'Connect to a remote wallet with NWC'**
  String get nwcWalletTypeSubtitle;

  /// Title for the LNURL wallet type option
  ///
  /// In en, this message translates to:
  /// **'Lightning Address (LNURL)'**
  String get lnurlWalletTypeTitle;

  /// Subtitle for the LNURL wallet type option
  ///
  /// In en, this message translates to:
  /// **'Use a Lightning address (LNURL) for receiving only'**
  String get lnurlWalletTypeSubtitle;

  /// Title for the Cashu wallet type option
  ///
  /// In en, this message translates to:
  /// **'Cashu'**
  String get cashuWalletTypeTitle;

  /// No description provided for @chooseCashuMint.
  ///
  /// In en, this message translates to:
  /// **'Choose Cashu mint'**
  String get chooseCashuMint;

  /// No description provided for @cashuMintRatingsNotice.
  ///
  /// In en, this message translates to:
  /// **'Community ratings come from signed Nostr reviews. A high rating does not guarantee that a mint is safe.'**
  String get cashuMintRatingsNotice;

  /// No description provided for @cashuMintDiscoveryFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load mint suggestions.'**
  String get cashuMintDiscoveryFailed;

  /// No description provided for @noCashuMintSuggestions.
  ///
  /// In en, this message translates to:
  /// **'No available mint suggestions found.'**
  String get noCashuMintSuggestions;

  /// No description provided for @noRatingsYet.
  ///
  /// In en, this message translates to:
  /// **'No ratings yet'**
  String get noRatingsYet;

  /// No description provided for @cashuMintRating.
  ///
  /// In en, this message translates to:
  /// **'★ {rating} · {count} reviews'**
  String cashuMintRating(String rating, int count);

  /// No description provided for @enterMintUrlManually.
  ///
  /// In en, this message translates to:
  /// **'Enter mint URL manually'**
  String get enterMintUrlManually;

  /// Subtitle for the Cashu wallet type option
  ///
  /// In en, this message translates to:
  /// **'Use an ecash wallet backed by a Cashu mint'**
  String get cashuWalletTypeSubtitle;

  /// Label for Cashu wallet option
  ///
  /// In en, this message translates to:
  /// **'Cashu'**
  String get cashuOption;

  /// Label for NWC wallet option
  ///
  /// In en, this message translates to:
  /// **'NWC'**
  String get nwcOption;

  /// Label for LNURL wallet option
  ///
  /// In en, this message translates to:
  /// **'LNURL'**
  String get lnurlOption;

  /// Title for NWC connection dialog
  ///
  /// In en, this message translates to:
  /// **'Connect NWC'**
  String get connectNwcTitle;

  /// Prompt to choose NWC connection method
  ///
  /// In en, this message translates to:
  /// **'Choose connection method'**
  String get chooseNwcMethod;

  /// Label for Alby Go option
  ///
  /// In en, this message translates to:
  /// **'Alby Go'**
  String get albyGoOption;

  /// Instructions shown beside the Alby Go wallet authorization QR code
  ///
  /// In en, this message translates to:
  /// **'In Alby Go, tap Send, then scan this QR code.'**
  String get albyGoQrScanInstructions;

  /// Label for manual connection option
  ///
  /// In en, this message translates to:
  /// **'Manual'**
  String get manualOption;

  /// Label for faucet option
  ///
  /// In en, this message translates to:
  /// **'Faucet'**
  String get faucetOption;

  /// Error message for invalid NWC QR code
  ///
  /// In en, this message translates to:
  /// **'Invalid NWC QR code'**
  String get invalidNwcQrCode;

  /// Title for scanning NWC QR code
  ///
  /// In en, this message translates to:
  /// **'Scan NWC QR Code'**
  String get scanNwcQrCodeTitle;

  /// Message shown when camera is not available
  ///
  /// In en, this message translates to:
  /// **'Camera not available'**
  String get cameraNotAvailable;

  /// Instructions for scanning NWC QR code
  ///
  /// In en, this message translates to:
  /// **'Scan the QR code from your NWC wallet app'**
  String get scanNwcInstructions;

  /// Error message for invalid NWC URI
  ///
  /// In en, this message translates to:
  /// **'Invalid NWC URI'**
  String get invalidNwcUri;

  /// Label for paste action
  ///
  /// In en, this message translates to:
  /// **'Paste'**
  String get paste;

  /// No description provided for @clearInput.
  ///
  /// In en, this message translates to:
  /// **'Clear input'**
  String get clearInput;

  /// No description provided for @pasteOrEnter.
  ///
  /// In en, this message translates to:
  /// **'Paste or type'**
  String get pasteOrEnter;

  /// Label indicating a value comes from user's profile
  ///
  /// In en, this message translates to:
  /// **'From your profile'**
  String get fromYourProfile;

  /// Label for manual entry option
  ///
  /// In en, this message translates to:
  /// **'Or enter manually:'**
  String get orEnterManually;

  /// Label for rename wallet option
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get renameWallet;

  /// Label for pick color option
  ///
  /// In en, this message translates to:
  /// **'Pick Color'**
  String get pickColor;

  /// Label for delete wallet option
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteWallet;

  /// Label for wallet name input
  ///
  /// In en, this message translates to:
  /// **'Wallet Name'**
  String get walletName;

  /// Hint for wallet name input
  ///
  /// In en, this message translates to:
  /// **'Enter wallet name'**
  String get walletNameHint;

  /// Label for save action
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Message shown when wallet is renamed
  ///
  /// In en, this message translates to:
  /// **'Wallet renamed'**
  String get walletRenamed;

  /// Budget information showing used and total amount
  ///
  /// In en, this message translates to:
  /// **'Budget: {used} / {total}'**
  String budgetUsedOf(int used, int total);

  /// Budget renewal information showing days until renewal
  ///
  /// In en, this message translates to:
  /// **'Renews in {days} days'**
  String budgetRenewsIn(int days);

  /// Daily budget renewal period
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get budgetDaily;

  /// Weekly budget renewal period
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get budgetWeekly;

  /// Monthly budget renewal period
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get budgetMonthly;

  /// Yearly budget renewal period
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get budgetYearly;

  /// Never renews budget
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get budgetNever;

  /// Label for the wallet backup action
  ///
  /// In en, this message translates to:
  /// **'Backup'**
  String get backup;

  /// Label for the wallet restore action
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restore;

  /// Title of the cashu backup dialog
  ///
  /// In en, this message translates to:
  /// **'Cashu Backup'**
  String get cashuBackupTitle;

  /// Security warning shown in the cashu backup dialog
  ///
  /// In en, this message translates to:
  /// **'This backup contains your ecash proofs, which are bearer funds. Keep it private and store it somewhere safe. Your seed phrase is backed up separately.'**
  String get cashuBackupWarning;

  /// Shown while the cashu backup is being generated
  ///
  /// In en, this message translates to:
  /// **'Generating backup...'**
  String get generatingBackup;

  /// Button to copy the cashu backup to the clipboard
  ///
  /// In en, this message translates to:
  /// **'Copy backup'**
  String get copyBackup;

  /// Confirmation that the backup was copied
  ///
  /// In en, this message translates to:
  /// **'Backup copied to clipboard'**
  String get backupCopiedToClipboard;

  /// Title of the cashu restore dialog
  ///
  /// In en, this message translates to:
  /// **'Restore Cashu Backup'**
  String get cashuRestoreTitle;

  /// Label for the backup JSON input field
  ///
  /// In en, this message translates to:
  /// **'Backup JSON'**
  String get backupJson;

  /// Hint for the backup JSON input field
  ///
  /// In en, this message translates to:
  /// **'Paste your backup JSON here'**
  String get backupJsonHint;

  /// Validation message when the backup field is empty
  ///
  /// In en, this message translates to:
  /// **'Please enter a backup'**
  String get pleaseEnterBackup;

  /// Shown while a cashu backup is being restored
  ///
  /// In en, this message translates to:
  /// **'Restoring backup...'**
  String get restoringBackup;

  /// No description provided for @appUpdateVersionAvailable.
  ///
  /// In en, this message translates to:
  /// **'Version {version} available'**
  String appUpdateVersionAvailable(String version);

  /// No description provided for @appUpdateLater.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get appUpdateLater;

  /// No description provided for @appUpdateView.
  ///
  /// In en, this message translates to:
  /// **'View update'**
  String get appUpdateView;

  /// No description provided for @appUpdateChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking for updates…'**
  String get appUpdateChecking;

  /// No description provided for @appUpdateCheckFailed.
  ///
  /// In en, this message translates to:
  /// **'Update check failed'**
  String get appUpdateCheckFailed;

  /// No description provided for @appUpdateInstalled.
  ///
  /// In en, this message translates to:
  /// **'Installed {version}'**
  String appUpdateInstalled(String version);

  /// No description provided for @appUpdatesTitle.
  ///
  /// In en, this message translates to:
  /// **'App updates'**
  String get appUpdatesTitle;

  /// No description provided for @appUpdateNone.
  ///
  /// In en, this message translates to:
  /// **'No update available'**
  String get appUpdateNone;

  /// No description provided for @appUpdateTitle.
  ///
  /// In en, this message translates to:
  /// **'Update {currentVersion} → {availableVersion}'**
  String appUpdateTitle(String currentVersion, String availableVersion);

  /// No description provided for @appUpdateSizeMb.
  ///
  /// In en, this message translates to:
  /// **'{size} MB'**
  String appUpdateSizeMb(String size);

  /// No description provided for @appUpdateAllowInstalls.
  ///
  /// In en, this message translates to:
  /// **'Allow installs from this app, then tap Update again.'**
  String get appUpdateAllowInstalls;

  /// No description provided for @appUpdateCompleteInstallation.
  ///
  /// In en, this message translates to:
  /// **'Complete installation in Android system installer.'**
  String get appUpdateCompleteInstallation;

  /// No description provided for @appUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Update failed'**
  String get appUpdateFailed;

  /// No description provided for @appUpdateCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get appUpdateCancel;

  /// No description provided for @appUpdateAction.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get appUpdateAction;

  /// No description provided for @appUpdateDownload.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get appUpdateDownload;

  /// No description provided for @appUpdateUpToDate.
  ///
  /// In en, this message translates to:
  /// **'You’re up to date'**
  String get appUpdateUpToDate;

  /// No description provided for @appUpdateAheadOfPublished.
  ///
  /// In en, this message translates to:
  /// **'Newer than published'**
  String get appUpdateAheadOfPublished;

  /// No description provided for @appUpdateAheadOfPublishedMessage.
  ///
  /// In en, this message translates to:
  /// **'Installed version {installedVersion} is newer than latest published version {publishedVersion}. Release details will appear after this version is published.'**
  String appUpdateAheadOfPublishedMessage(
    String installedVersion,
    String publishedVersion,
  );

  /// No description provided for @appUpdateCheckFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'Could not check for updates.'**
  String get appUpdateCheckFailedMessage;

  /// No description provided for @appUpdateLatest.
  ///
  /// In en, this message translates to:
  /// **'Version {version} is the latest available version.'**
  String appUpdateLatest(String version);

  /// No description provided for @appUpdateClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get appUpdateClose;

  /// No description provided for @appUpdateCheckAgain.
  ///
  /// In en, this message translates to:
  /// **'Check again'**
  String get appUpdateCheckAgain;

  /// No description provided for @appUpdateInstalledVersion.
  ///
  /// In en, this message translates to:
  /// **'Installed version {version}'**
  String appUpdateInstalledVersion(String version);

  /// No description provided for @appUpdateInstalledAndAvailable.
  ///
  /// In en, this message translates to:
  /// **'Installed version {installedVersion}. Update {availableVersion} available.'**
  String appUpdateInstalledAndAvailable(
    String installedVersion,
    String availableVersion,
  );

  /// No description provided for @appUpdateChangelog.
  ///
  /// In en, this message translates to:
  /// **'Changelog'**
  String get appUpdateChangelog;

  /// No description provided for @appUpdateReleaseHistory.
  ///
  /// In en, this message translates to:
  /// **'Release history'**
  String get appUpdateReleaseHistory;

  /// No description provided for @appUpdateInstalledBadge.
  ///
  /// In en, this message translates to:
  /// **'Installed'**
  String get appUpdateInstalledBadge;

  /// No description provided for @appUpdateAvailableBadge.
  ///
  /// In en, this message translates to:
  /// **'Update available'**
  String get appUpdateAvailableBadge;

  /// No description provided for @appUpdateLatestBadge.
  ///
  /// In en, this message translates to:
  /// **'Latest'**
  String get appUpdateLatestBadge;

  /// No description provided for @appUpdateNoReleases.
  ///
  /// In en, this message translates to:
  /// **'No releases have been published yet.'**
  String get appUpdateNoReleases;

  /// No description provided for @appUpdateAcrossAllReleases.
  ///
  /// In en, this message translates to:
  /// **'Across all releases'**
  String get appUpdateAcrossAllReleases;

  /// No description provided for @appUpdateReleaseDetails.
  ///
  /// In en, this message translates to:
  /// **'Release details'**
  String get appUpdateReleaseDetails;

  /// No description provided for @appUpdateWhatsNew.
  ///
  /// In en, this message translates to:
  /// **'What’s new'**
  String get appUpdateWhatsNew;

  /// No description provided for @appUpdatePublishedOn.
  ///
  /// In en, this message translates to:
  /// **'Published {date}'**
  String appUpdatePublishedOn(String date);

  /// No description provided for @appUpdateChannel.
  ///
  /// In en, this message translates to:
  /// **'Channel: {channel}'**
  String appUpdateChannel(String channel);

  /// No description provided for @appUpdateArchitecture.
  ///
  /// In en, this message translates to:
  /// **'Architecture: {architecture}'**
  String appUpdateArchitecture(String architecture);

  /// No description provided for @appUpdateVersionCode.
  ///
  /// In en, this message translates to:
  /// **'Build {versionCode}'**
  String appUpdateVersionCode(int versionCode);

  /// No description provided for @appUpdateReleaseVersion.
  ///
  /// In en, this message translates to:
  /// **'Release {version}'**
  String appUpdateReleaseVersion(String version);

  /// No description provided for @appUpdateNoReleaseNotes.
  ///
  /// In en, this message translates to:
  /// **'No release notes were published.'**
  String get appUpdateNoReleaseNotes;

  /// No description provided for @appUpdatePublisher.
  ///
  /// In en, this message translates to:
  /// **'Publisher'**
  String get appUpdatePublisher;

  /// No description provided for @appUpdatePublisherSignatureVerified.
  ///
  /// In en, this message translates to:
  /// **'Nostr event signature verified'**
  String get appUpdatePublisherSignatureVerified;

  /// No description provided for @appUpdateCertificateDeclared.
  ///
  /// In en, this message translates to:
  /// **'Android signing certificate declared by publisher'**
  String get appUpdateCertificateDeclared;

  /// No description provided for @appUpdateSource.
  ///
  /// In en, this message translates to:
  /// **'Download source: {host}'**
  String appUpdateSource(String host);

  /// No description provided for @appUpdateCommunity.
  ///
  /// In en, this message translates to:
  /// **'Community'**
  String get appUpdateCommunity;

  /// No description provided for @appUpdateZapSummary.
  ///
  /// In en, this message translates to:
  /// **'{count} zaps · {sats} sats'**
  String appUpdateZapSummary(int count, int sats);

  /// No description provided for @appUpdateSatsBy.
  ///
  /// In en, this message translates to:
  /// **'sats by'**
  String get appUpdateSatsBy;

  /// No description provided for @appUpdateReactionCount.
  ///
  /// In en, this message translates to:
  /// **'{count} reactions'**
  String appUpdateReactionCount(int count);

  /// No description provided for @appUpdateCommentCount.
  ///
  /// In en, this message translates to:
  /// **'{count} comments'**
  String appUpdateCommentCount(int count);

  /// No description provided for @appUpdateSocialLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Community activity could not be loaded.'**
  String get appUpdateSocialLoadFailed;

  /// No description provided for @appUpdateComments.
  ///
  /// In en, this message translates to:
  /// **'Comments'**
  String get appUpdateComments;

  /// No description provided for @appUpdateNoComments.
  ///
  /// In en, this message translates to:
  /// **'No comments yet.'**
  String get appUpdateNoComments;

  /// No description provided for @appUpdateCommentHint.
  ///
  /// In en, this message translates to:
  /// **'Share feedback about this release'**
  String get appUpdateCommentHint;

  /// No description provided for @appUpdatePostComment.
  ///
  /// In en, this message translates to:
  /// **'Post comment'**
  String get appUpdatePostComment;

  /// No description provided for @appUpdateSignInToComment.
  ///
  /// In en, this message translates to:
  /// **'Sign in with a Nostr account to comment.'**
  String get appUpdateSignInToComment;

  /// No description provided for @appUpdateTechnicalDetails.
  ///
  /// In en, this message translates to:
  /// **'Technical details'**
  String get appUpdateTechnicalDetails;

  /// No description provided for @appUpdateViewStatus.
  ///
  /// In en, this message translates to:
  /// **'View update status'**
  String get appUpdateViewStatus;

  /// Confirmation after a successful restore
  ///
  /// In en, this message translates to:
  /// **'Restored {count} proofs from backup'**
  String restoreSuccess(int count);

  /// No description provided for @bolt12Wallet.
  ///
  /// In en, this message translates to:
  /// **'BOLT12 Wallet'**
  String get bolt12Wallet;

  /// No description provided for @bolt12WalletSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Reusable Lightning offer'**
  String get bolt12WalletSubtitle;

  /// No description provided for @bolt12PrivateOfferSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Reusable private offer'**
  String get bolt12PrivateOfferSubtitle;

  /// No description provided for @anyAmount.
  ///
  /// In en, this message translates to:
  /// **'Any amount'**
  String get anyAmount;

  /// No description provided for @blindedRoute.
  ///
  /// In en, this message translates to:
  /// **'Blinded'**
  String get blindedRoute;

  /// No description provided for @fromAmountSats.
  ///
  /// In en, this message translates to:
  /// **'From {amount} sats'**
  String fromAmountSats(String amount);

  /// No description provided for @fromAmountMsats.
  ///
  /// In en, this message translates to:
  /// **'From {amount} msats'**
  String fromAmountMsats(String amount);

  /// No description provided for @fromCurrencyAmount.
  ///
  /// In en, this message translates to:
  /// **'From {amount} {currency}'**
  String fromCurrencyAmount(String amount, String currency);

  /// No description provided for @bolt12Expires.
  ///
  /// In en, this message translates to:
  /// **'Expires {date}'**
  String bolt12Expires(String date);

  /// No description provided for @bolt12WalletTypeTitle.
  ///
  /// In en, this message translates to:
  /// **'BOLT12 Offer'**
  String get bolt12WalletTypeTitle;

  /// No description provided for @bip353WalletTypeTitle.
  ///
  /// In en, this message translates to:
  /// **'BIP353'**
  String get bip353WalletTypeTitle;

  /// No description provided for @lnurlProtocol.
  ///
  /// In en, this message translates to:
  /// **'LNURL'**
  String get lnurlProtocol;

  /// No description provided for @bolt12WalletTypeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Receive-only wallet using a reusable offer'**
  String get bolt12WalletTypeSubtitle;

  /// No description provided for @addBolt12WalletTitle.
  ///
  /// In en, this message translates to:
  /// **'Add BOLT12 Wallet'**
  String get addBolt12WalletTitle;

  /// No description provided for @enterBolt12Input.
  ///
  /// In en, this message translates to:
  /// **'Enter or scan an lno offer, a bitcoin:?lno=... URI, or a BIP353 address.'**
  String get enterBolt12Input;

  /// No description provided for @bolt12Input.
  ///
  /// In en, this message translates to:
  /// **'BOLT12 payment target'**
  String get bolt12Input;

  /// No description provided for @bolt12InputHint.
  ///
  /// In en, this message translates to:
  /// **'lno1..., bitcoin:?lno=..., or user@domain.com'**
  String get bolt12InputHint;

  /// No description provided for @walletNameOptional.
  ///
  /// In en, this message translates to:
  /// **'Wallet name (optional)'**
  String get walletNameOptional;

  /// No description provided for @scanBolt12QrCodeTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan BOLT12 QR code'**
  String get scanBolt12QrCodeTitle;

  /// No description provided for @invalidBolt12QrCode.
  ///
  /// In en, this message translates to:
  /// **'The QR code is not a BOLT12, BIP321, or BIP353 payment target.'**
  String get invalidBolt12QrCode;

  /// No description provided for @pleaseEnterBolt12Input.
  ///
  /// In en, this message translates to:
  /// **'Please enter a BOLT12 offer or BIP353 address.'**
  String get pleaseEnterBolt12Input;

  /// No description provided for @bolt12WalletAdded.
  ///
  /// In en, this message translates to:
  /// **'BOLT12 wallet added successfully!'**
  String get bolt12WalletAdded;

  /// No description provided for @bolt12OfferTitle.
  ///
  /// In en, this message translates to:
  /// **'Receive with BOLT12'**
  String get bolt12OfferTitle;

  /// No description provided for @bolt12OfferInstructions.
  ///
  /// In en, this message translates to:
  /// **'Share this reusable offer to receive a Lightning payment.'**
  String get bolt12OfferInstructions;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @reviewWallet.
  ///
  /// In en, this message translates to:
  /// **'Review wallet'**
  String get reviewWallet;

  /// No description provided for @confirmWalletTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm wallet'**
  String get confirmWalletTitle;

  /// No description provided for @confirmWalletDescription.
  ///
  /// In en, this message translates to:
  /// **'Review these details before adding this wallet.'**
  String get confirmWalletDescription;

  /// No description provided for @walletDetailType.
  ///
  /// In en, this message translates to:
  /// **'Wallet type'**
  String get walletDetailType;

  /// No description provided for @walletDetailAddress.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get walletDetailAddress;

  /// No description provided for @walletDetailDomain.
  ///
  /// In en, this message translates to:
  /// **'Domain'**
  String get walletDetailDomain;

  /// No description provided for @walletDetailUrl.
  ///
  /// In en, this message translates to:
  /// **'URL'**
  String get walletDetailUrl;

  /// No description provided for @walletDetailPublicKey.
  ///
  /// In en, this message translates to:
  /// **'Public key'**
  String get walletDetailPublicKey;

  /// No description provided for @walletDetailRelay.
  ///
  /// In en, this message translates to:
  /// **'Relay'**
  String get walletDetailRelay;

  /// No description provided for @walletDetailRelays.
  ///
  /// In en, this message translates to:
  /// **'Relays'**
  String get walletDetailRelays;

  /// No description provided for @walletDetailSecret.
  ///
  /// In en, this message translates to:
  /// **'Connection secret'**
  String get walletDetailSecret;

  /// No description provided for @walletSecretHidden.
  ///
  /// In en, this message translates to:
  /// **'Present and hidden for security'**
  String get walletSecretHidden;

  /// No description provided for @walletDetailDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get walletDetailDescription;

  /// No description provided for @walletDetailDetails.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get walletDetailDetails;

  /// No description provided for @walletDetailIssuer.
  ///
  /// In en, this message translates to:
  /// **'Issuer'**
  String get walletDetailIssuer;

  /// No description provided for @walletDetailAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get walletDetailAmount;

  /// No description provided for @walletDetailCurrency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get walletDetailCurrency;

  /// No description provided for @walletDetailExpiry.
  ///
  /// In en, this message translates to:
  /// **'Expires'**
  String get walletDetailExpiry;

  /// No description provided for @walletDetailNodeId.
  ///
  /// In en, this message translates to:
  /// **'Node ID'**
  String get walletDetailNodeId;

  /// No description provided for @walletDetailOffer.
  ///
  /// In en, this message translates to:
  /// **'BOLT12 offer'**
  String get walletDetailOffer;

  /// No description provided for @walletDetailVersion.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get walletDetailVersion;

  /// No description provided for @walletDetailUnits.
  ///
  /// In en, this message translates to:
  /// **'Supported units'**
  String get walletDetailUnits;

  /// No description provided for @walletDetailContact.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get walletDetailContact;

  /// No description provided for @walletDetailTerms.
  ///
  /// In en, this message translates to:
  /// **'Terms of service'**
  String get walletDetailTerms;

  /// No description provided for @walletDetailMessage.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get walletDetailMessage;

  /// No description provided for @walletDetailCommunityRating.
  ///
  /// In en, this message translates to:
  /// **'Community rating'**
  String get walletDetailCommunityRating;

  /// No description provided for @walletDetailCommunityReviews.
  ///
  /// In en, this message translates to:
  /// **'Recent community reviews'**
  String get walletDetailCommunityReviews;

  /// No description provided for @refreshBalance.
  ///
  /// In en, this message translates to:
  /// **'Refresh balance'**
  String get refreshBalance;

  /// No description provided for @balanceRefreshed.
  ///
  /// In en, this message translates to:
  /// **'Balance refreshed'**
  String get balanceRefreshed;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'de',
    'en',
    'es',
    'fi',
    'fr',
    'it',
    'ja',
    'pl',
    'pt',
    'ru',
    'sk',
    'zh',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+country codes are specified.
  switch (locale.languageCode) {
    case 'pt':
      {
        switch (locale.countryCode) {
          case 'BR':
            return AppLocalizationsPtBr();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fi':
      return AppLocalizationsFi();
    case 'fr':
      return AppLocalizationsFr();
    case 'it':
      return AppLocalizationsIt();
    case 'ja':
      return AppLocalizationsJa();
    case 'pl':
      return AppLocalizationsPl();
    case 'pt':
      return AppLocalizationsPt();
    case 'ru':
      return AppLocalizationsRu();
    case 'sk':
      return AppLocalizationsSk();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
