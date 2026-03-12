// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get createAccount => 'Create your account';

  @override
  String get newHere => 'Are you new here?';

  @override
  String get nostrAddress => 'Nostr Address';

  @override
  String get publicKey => 'Public Key';

  @override
  String get privateKey => 'Private Key (insecure)';

  @override
  String get browserExtension => 'Browser extension';

  @override
  String get connect => 'Connect';

  @override
  String get install => 'Install';

  @override
  String get logout => 'Logout';

  @override
  String get nostrAddressHint => 'name@example.com';

  @override
  String get invalidAddress => 'Invalid Address';

  @override
  String get unableToConnect => 'Unable to connect';

  @override
  String get publicKeyHint => 'npub1...';

  @override
  String get privateKeyHint => 'nsec1...';

  @override
  String get newToNostr => 'New to Nostr?';

  @override
  String get getStarted => 'Get Started';

  @override
  String get bunker => 'Bunker';

  @override
  String get bunkerAuthentication => 'Bunker Authentication';

  @override
  String tapToOpen(String url) {
    return 'Tap to open: $url';
  }

  @override
  String get showNostrConnectQrcode => 'Show nostr connect qrcode';

  @override
  String get loginWithAmber => 'Login with amber';

  @override
  String get nostrConnectUrl => 'Nostr connect URL';

  @override
  String get copy => 'Copy';

  @override
  String get addAccount => 'Add account';

  @override
  String get readOnly => 'Read-only';

  @override
  String get nsec => 'Nsec';

  @override
  String get extension => 'Extension';

  @override
  String get userMetadata => 'User Metadata';

  @override
  String get shortTextNote => 'Short Text Note';

  @override
  String get recommendRelay => 'Recommend Relay';

  @override
  String get follows => 'Follows';

  @override
  String get encryptedDirectMessages => 'Encrypted Direct Messages';

  @override
  String get eventDeletionRequest => 'Event Deletion Request';

  @override
  String get repost => 'Repost';

  @override
  String get reaction => 'Reaction';

  @override
  String get badgeAward => 'Badge Award';

  @override
  String get chatMessage => 'Chat Message';

  @override
  String get groupChatThreadedReply => 'Group Chat Threaded Reply';

  @override
  String get thread => 'Thread';

  @override
  String get groupThreadReply => 'Group Thread Reply';

  @override
  String get seal => 'Seal';

  @override
  String get directMessage => 'Direct Message';

  @override
  String get fileMessage => 'File Message';

  @override
  String get genericRepost => 'Generic Repost';

  @override
  String get reactionToWebsite => 'Reaction to a website';

  @override
  String get picture => 'Picture';

  @override
  String get videoEvent => 'Video Event';

  @override
  String get shortFormPortraitVideoEvent => 'Short-form Portrait Video Event';

  @override
  String get internalReference => 'Internal reference';

  @override
  String get externalReference => 'External reference';

  @override
  String get hardcopyReference => 'Hardcopy reference';

  @override
  String get promptReference => 'Prompt reference';

  @override
  String get channelCreation => 'Channel Creation';

  @override
  String get channelMetadata => 'Channel Metadata';

  @override
  String get channelMessage => 'Channel Message';

  @override
  String get channelHideMessage => 'Channel Hide Message';

  @override
  String get channelMuteUser => 'Channel Mute User';

  @override
  String get requestToVanish => 'Request to Vanish';

  @override
  String get chessPgn => 'Chess (PGN)';

  @override
  String get mlsKeyPackage => 'MLS KeyPackage';

  @override
  String get mlsWelcome => 'MLS Welcome';

  @override
  String get mlsGroupEvent => 'MLS Group Event';

  @override
  String get mergeRequests => 'Merge Requests';

  @override
  String get pollResponse => 'Poll Response';

  @override
  String get marketplaceBid => 'Marketplace Bid';

  @override
  String get marketplaceBidConfirmation => 'Marketplace Bid Confirmation';

  @override
  String get openTimestamps => 'OpenTimestamps';

  @override
  String get giftWrap => 'Gift Wrap';

  @override
  String get fileMetadata => 'File Metadata';

  @override
  String get poll => 'Poll';

  @override
  String get comment => 'Comment';

  @override
  String get voiceMessage => 'Voice Message';

  @override
  String get voiceMessageComment => 'Voice Message Comment';

  @override
  String get liveChatMessage => 'Live Chat Message';

  @override
  String get codeSnippet => 'Code Snippet';

  @override
  String get gitPatch => 'Git Patch';

  @override
  String get gitPullRequest => 'Git Pull Request';

  @override
  String get gitStatusUpdate => 'Git Status Update';

  @override
  String get gitIssue => 'Git Issue';

  @override
  String get gitIssueUpdate => 'Git Issue Update';

  @override
  String get status => 'Status';

  @override
  String get statusUpdate => 'Status Update';

  @override
  String get statusDelete => 'Status Delete';

  @override
  String get statusReply => 'Status Reply';

  @override
  String get problemTracker => 'Problem Tracker';

  @override
  String get reporting => 'Reporting';

  @override
  String get label => 'Label';

  @override
  String get relayReviews => 'Relay reviews';

  @override
  String get aiEmbeddings => 'AI Embeddings / Vector lists';

  @override
  String get torrent => 'Torrent';

  @override
  String get torrentComment => 'Torrent Comment';

  @override
  String get coinjoinPool => 'Coinjoin Pool';

  @override
  String get communityPostApproval => 'Community Post Approval';

  @override
  String get jobRequest => 'Job Request';

  @override
  String get jobResult => 'Job Result';

  @override
  String get jobFeedback => 'Job Feedback';

  @override
  String get cashuWalletToken => 'Cashu Wallet Token';

  @override
  String get cashuWalletProofs => 'Cashu Wallet Proofs';

  @override
  String get cashuWalletHistory => 'Cashu Wallet History';

  @override
  String get geocacheCreate => 'Geocache Create';

  @override
  String get geocacheUpdate => 'Geocache Update';

  @override
  String get groupControlEvent => 'Group Control Event';

  @override
  String get zapGoal => 'Zap Goal';

  @override
  String get nutzap => 'Nutzap';

  @override
  String get tidalLogin => 'Tidal login';

  @override
  String get zapRequest => 'Zap Request';

  @override
  String get zap => 'Zap';

  @override
  String get highlights => 'Highlights';

  @override
  String get muteList => 'Mute List';

  @override
  String get pinList => 'Pin List';

  @override
  String get relayListMetadata => 'Relay List Metadata';

  @override
  String get bookmarkList => 'Bookmark List';

  @override
  String get communitiesList => 'Communities List';

  @override
  String get publicChatsList => 'Public Chats List';

  @override
  String get blockedRelaysList => 'Blocked Relays List';

  @override
  String get searchRelaysList => 'Search Relays List';

  @override
  String get userGroups => 'User Groups';

  @override
  String get favoritesList => 'Favorites List';

  @override
  String get privateEventsList => 'Private Events List';

  @override
  String get interestsList => 'Interests List';

  @override
  String get mediaFollowsList => 'Media Follows List';

  @override
  String get peopleFollowsList => 'People Follows List';

  @override
  String get userEmojiList => 'User Emoji List';

  @override
  String get dmRelayList => 'DM Relay List';

  @override
  String get keyPackageRelayList => 'KeyPackage Relay List';

  @override
  String get userServerList => 'User Server List';

  @override
  String get fileStorageServerList => 'File Storage Server List';

  @override
  String get relayMonitorAnnouncement => 'Relay Monitor Announcement';

  @override
  String get roomPresence => 'Room Presence';

  @override
  String get proxyAnnouncement => 'Proxy Announcement';

  @override
  String get transportMethodAnnouncement => 'Transport Method Announcement';

  @override
  String get walletInfo => 'Wallet Info';

  @override
  String get cashuWalletEvent => 'Cashu Wallet Event';

  @override
  String get lightningPubRpc => 'Lightning Pub RPC';

  @override
  String get clientAuthentication => 'Client Authentication';

  @override
  String get walletRequest => 'Wallet Request';

  @override
  String get walletResponse => 'Wallet Response';

  @override
  String get nostrConnectEvent => 'Nostr Connect';

  @override
  String get blobsStoredOnMediaservers => 'Blobs stored on mediaservers';

  @override
  String get httpAuth => 'HTTP Auth';

  @override
  String get categorizedPeopleList => 'Categorized People List';

  @override
  String get categorizedBookmarkList => 'Categorized Bookmark List';

  @override
  String get categorizedRelayList => 'Categorized Relay List';

  @override
  String get bookmarkSets => 'Bookmark Sets';

  @override
  String get curationSets => 'Curation Sets';

  @override
  String get videoSets => 'Video Sets';

  @override
  String get kindMuteSets => 'Kind Mute Sets';

  @override
  String get profileBadges => 'Profile Badges';

  @override
  String get badgeDefinition => 'Badge Definition';

  @override
  String get interestSets => 'Interest Sets';

  @override
  String get createOrUpdateStall => 'Create or Update Stall';

  @override
  String get createOrUpdateProduct => 'Create or Update Product';

  @override
  String get marketplaceUiUx => 'Marketplace UI/UX';

  @override
  String get productSoldAsAuction => 'Product Sold as Auction';

  @override
  String get longFormContent => 'Long-form Content';

  @override
  String get draftLongFormContent => 'Draft Long-form Content';

  @override
  String get emojiSets => 'Emoji Sets';

  @override
  String get curatedPublicationItem => 'Curated Publication Item';

  @override
  String get curatedPublicationDraft => 'Curated Publication Draft';

  @override
  String get releaseArtifactSets => 'Release Artifact Sets';

  @override
  String get applicationSpecificData => 'Application-specific Data';

  @override
  String get relayDiscovery => 'Relay Discovery';

  @override
  String get appCurationSets => 'App Curation Sets';

  @override
  String get liveEvent => 'Live Event';

  @override
  String get userStatus => 'User Status';

  @override
  String get slideSet => 'Slide Set';

  @override
  String get classifiedListing => 'Classified Listing';

  @override
  String get draftClassifiedListing => 'Draft Classified Listing';

  @override
  String get repositoryAnnouncement => 'Repository Announcement';

  @override
  String get repositoryStateAnnouncement => 'Repository State Announcement';

  @override
  String get wikiArticle => 'Wiki Article';

  @override
  String get redirects => 'Redirects';

  @override
  String get draftEvent => 'Draft Event';

  @override
  String get linkSet => 'Link Set';

  @override
  String get feed => 'Feed';

  @override
  String get dateBasedCalendarEvent => 'Date-Based Calendar Event';

  @override
  String get timeBasedCalendarEvent => 'Time-Based Calendar Event';

  @override
  String get calendar => 'Calendar';

  @override
  String get calendarEventRsvp => 'Calendar Event RSVP';

  @override
  String get handlerRecommendation => 'Handler Recommendation';

  @override
  String get handlerInformation => 'Handler Information';

  @override
  String get softwareApplication => 'Software Application';

  @override
  String get videoView => 'Video View';

  @override
  String get communityDefinition => 'Community Definition';

  @override
  String get geocacheListing => 'Geocache Listing';

  @override
  String get mintAnnouncement => 'Mint Announcement';

  @override
  String get mintQuote => 'Mint Quote';

  @override
  String get peerToPeerOrder => 'Peer-to-peer Order';

  @override
  String get groupMetadata => 'Group Metadata';

  @override
  String get groupAdminMetadata => 'Group Admin Metadata';

  @override
  String get groupMemberMetadata => 'Group Member Metadata';

  @override
  String get groupAdminsList => 'Group Admins List';

  @override
  String get groupMembersList => 'Group Members List';

  @override
  String get groupRoles => 'Group Roles';

  @override
  String get groupPermissions => 'Group Permissions';

  @override
  String get groupChatMessage => 'Group Chat Message';

  @override
  String get groupChatThread => 'Group Chat Thread';

  @override
  String get groupPinned => 'Group Pinned';

  @override
  String get starterPacks => 'Starter Packs';

  @override
  String get mediaStarterPacks => 'Media Starter Packs';

  @override
  String get webBookmarks => 'Web Bookmarks';

  @override
  String unknownEventKind(int kind) {
    return 'Event Kind $kind';
  }

  @override
  String get walletsTitle => 'Wallets';

  @override
  String get recentActivityTitle => 'Recent Activity';

  @override
  String get addCashuWallet => 'Add Cashu Wallet';

  @override
  String get addNwcWallet => 'Add NWC Wallet';

  @override
  String get addLnurlWallet => 'Add LNURL Wallet';

  @override
  String get addCashuTooltip => 'Add Cashu Wallet';

  @override
  String get addNwcTooltip => 'Add NWC Wallet';

  @override
  String get addLnurlTooltip => 'Add LNURL Wallet';

  @override
  String get addCashuWalletTitle => 'Add Cashu Wallet';

  @override
  String get enterMintUrl => 'Enter the mint URL to add a Cashu wallet.';

  @override
  String get mintUrl => 'Mint URL';

  @override
  String get mintUrlHint => 'https://mint.example.com';

  @override
  String get pleaseEnterMintUrl => 'Please enter a mint URL';

  @override
  String get cashuWalletAdded => 'Cashu wallet added successfully!';

  @override
  String get failedToAddMint =>
      'Failed to add mint. Please check the URL and try again.';

  @override
  String get addNwcWalletTitle => 'Add NWC Wallet';

  @override
  String get faucet => 'Faucet';

  @override
  String get manual => 'Manual';

  @override
  String get nwcFaucetDescription =>
      'Create a test wallet with sats from the NWC faucet.';

  @override
  String get startingBalance => 'Starting Balance';

  @override
  String get startingBalanceHint => '10000';

  @override
  String get nwcConnectionUri => 'NWC Connection URI';

  @override
  String get nwcConnectionUriHint => 'nostr+walletconnect://...';

  @override
  String get nwcWalletAdded => 'NWC wallet added successfully!';

  @override
  String nwcFaucetWalletAdded(int balance) {
    return 'NWC faucet wallet added with $balance sats!';
  }

  @override
  String get invalidFaucetResponse => 'Invalid response from faucet';

  @override
  String get errorCreatingWallet => 'Error creating wallet';

  @override
  String get addLnurlWalletTitle => 'Add LNURL Wallet';

  @override
  String get enterLnurlIdentifier =>
      'Enter your LNURL identifier (user@domain.com).';

  @override
  String get lnurlIdentifierHint => 'user@example.com';

  @override
  String get pleaseEnterValidIdentifier =>
      'Please enter a valid identifier (user@domain.com)';

  @override
  String get lnurlWalletAdded => 'LNURL wallet added successfully!';

  @override
  String get cancel => 'Cancel';

  @override
  String get add => 'Add';

  @override
  String get send => 'Send';

  @override
  String get receive => 'Receive';

  @override
  String get sendOptionsTitle => 'Send Options';

  @override
  String get sendByToken => 'Send by Token';

  @override
  String get sendByTokenDescription => 'Create a Cashu token to send';

  @override
  String get sendByLightning => 'Send by Lightning';

  @override
  String get sendByLightningDescription => 'Pay a Lightning invoice';

  @override
  String get payInvoiceTitle => 'Pay Invoice';

  @override
  String get invoice => 'Invoice';

  @override
  String get invoiceHint => 'lnbc...';

  @override
  String get pleaseEnterInvoice => 'Please enter an invoice';

  @override
  String get invoicePaid => 'Invoice paid!';

  @override
  String paymentFailed(String message) {
    return 'Payment failed: $message';
  }

  @override
  String get receiveOptionsTitle => 'Receive Options';

  @override
  String get receiveByToken => 'Receive by Token';

  @override
  String get receiveByTokenDescription => 'Receive a Cashu token';

  @override
  String get receiveByLightning => 'Receive by Lightning';

  @override
  String get receiveByLightningDescription => 'Create a Lightning invoice';

  @override
  String get receiveByTokenTitle => 'Receive by Token';

  @override
  String get token => 'Token';

  @override
  String get tokenHint => 'Paste token here...';

  @override
  String get pleaseEnterToken => 'Please enter a token';

  @override
  String get tokenReceived => 'Token received!';

  @override
  String get createInvoiceTitle => 'Create Invoice';

  @override
  String get amount => 'Amount';

  @override
  String get amountHint => '100';

  @override
  String get pleaseEnterValidAmount => 'Please enter a valid amount';

  @override
  String get tokenCopiedToClipboard => 'Token copied to clipboard!';

  @override
  String get invoiceCreatedAndCopied => 'Invoice created and copied!';

  @override
  String get invoiceTrackingTitle => 'Lightning Invoice';

  @override
  String get invoiceCreatedMessage => 'Invoice created and copied!';

  @override
  String get close => 'Close';

  @override
  String get copyAgain => 'Copy Again';

  @override
  String get copied => 'Copied!';

  @override
  String get paymentReceived => 'Payment received!';

  @override
  String get waitingForPayment => 'Waiting for payment...';

  @override
  String get paid => 'Paid!';

  @override
  String get createToken => 'Create Token';

  @override
  String get pay => 'Pay';

  @override
  String get create => 'Create';

  @override
  String get pendingTransactions => 'Pending';

  @override
  String get recentTransactions => 'Recent Transactions';

  @override
  String get noRecentTransactions => 'No recent transactions';

  @override
  String get noWalletsYet => 'No wallets yet';

  @override
  String get noWalletsAvailable => 'No wallets available';

  @override
  String get tapToAddWallet => 'Tap + to add one';

  @override
  String get delete => 'Delete';

  @override
  String error(String message) {
    return 'Error: $message';
  }

  @override
  String get unknownWalletType => 'Unknown';

  @override
  String get cashuWallet => 'Cashu';

  @override
  String get nwcWallet => 'NWC';

  @override
  String get lnurlWallet => 'LNURL';

  @override
  String get nwcWalletSubtitle => 'NWC Wallet';

  @override
  String get balance => 'Balance';

  @override
  String get sats => 'sats';

  @override
  String get selected => 'SELECTED';

  @override
  String get receiveOnlyWallet => 'Receive-only wallet';

  @override
  String receiveRange(int min, int max) {
    return 'Receive: $min - $max sats';
  }

  @override
  String get limitsUnavailable => 'Limits unavailable';

  @override
  String get tokenCopied => 'Token copied';

  @override
  String get deleteWalletConfirmation => 'Delete Wallet?';

  @override
  String get deleteWalletConfirmationMessage =>
      'Are you sure you want to delete this wallet? This action cannot be undone.';

  @override
  String get addWalletTitle => 'Add Wallet';

  @override
  String get chooseWalletType => 'Choose wallet type';

  @override
  String get cashuOption => 'Cashu';

  @override
  String get nwcOption => 'NWC';

  @override
  String get lnurlOption => 'LNURL';

  @override
  String get connectNwcTitle => 'Connect NWC';

  @override
  String get chooseNwcMethod => 'Choose connection method';

  @override
  String get albyGoOption => 'Alby Go';

  @override
  String get manualOption => 'Manual';

  @override
  String get faucetOption => 'Faucet';

  @override
  String get invalidNwcQrCode => 'Invalid NWC QR code';

  @override
  String get scanNwcQrCodeTitle => 'Scan NWC QR Code';

  @override
  String get cameraNotAvailable => 'Camera not available';

  @override
  String get scanNwcInstructions => 'Scan the QR code from your NWC wallet app';

  @override
  String get invalidNwcUri => 'Invalid NWC URI';

  @override
  String get paste => 'Paste';

  @override
  String get fromYourProfile => 'From your profile';

  @override
  String get orEnterManually => 'Or enter manually:';

  @override
  String get renameWallet => 'Rename';

  @override
  String get pickColor => 'Pick Color';

  @override
  String get deleteWallet => 'Delete';

  @override
  String get walletName => 'Wallet Name';

  @override
  String get walletNameHint => 'Enter wallet name';

  @override
  String get save => 'Save';

  @override
  String get walletRenamed => 'Wallet renamed';

  @override
  String budgetUsedOf(int used, int total) {
    return 'Used: $used / $total sats';
  }

  @override
  String budgetRenewsIn(int days) {
    return 'Renews in $days days';
  }

  @override
  String get budgetDaily => 'Daily';

  @override
  String get budgetWeekly => 'Weekly';

  @override
  String get budgetMonthly => 'Monthly';

  @override
  String get budgetYearly => 'Yearly';

  @override
  String get budgetNever => 'Never';
}
