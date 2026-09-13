// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get lnbitsWalletOption => 'LNbits';

  @override
  String get lnbitsConnectionInstructions =>
      'LNbitsで接続するウォレットを選んで開き、APIドキュメントを押して管理者キーをコピーしてください。下に貼り付けます：';

  @override
  String get lnbitsAdminKey => 'LNbits管理者キー';

  @override
  String get lnbitsKeyType => 'LNbitsキーの種類';

  @override
  String get lnbitsInvoiceReadKey => 'LNbits請求書・読み取りキー';

  @override
  String get lnbitsReadOnlyDescription =>
      '受信専用ウォレット：残高と履歴の表示、請求書の作成ができます。支払いの送信は無効です。';

  @override
  String get lnbitsUrl => 'LNbits URL';

  @override
  String get lnbitsCredentialsRequired => 'LNbits管理者キーとURLを入力してください。';

  @override
  String get lnbitsWalletAdded => 'LNbitsウォレットを追加しました';

  @override
  String get walletDetailWalletId => 'ウォレットID';

  @override
  String get saveBackupToFile => 'バックアップをファイルに保存';

  @override
  String get backupSavedToFile => 'バックアップをファイルに保存しました';

  @override
  String get restoreFromFile => 'ファイルから復元';

  @override
  String get backupFileReadFailed => '選択したバックアップファイルを読み込めませんでした。';

  @override
  String get fetchingWalletConnectionInfo => 'ウォレットの接続情報を取得中…';

  @override
  String get createAccount => 'アカウントを作成';

  @override
  String get newHere => '初めてですか？';

  @override
  String get nostrAddress => 'Nostrアドレス';

  @override
  String get publicKey => '公開鍵';

  @override
  String get privateKey => '秘密鍵（安全ではありません）';

  @override
  String get browserExtension => 'ブラウザ拡張機能';

  @override
  String get connect => '接続';

  @override
  String get install => 'インストール';

  @override
  String get logout => 'ログアウト';

  @override
  String get nostrAddressHint => 'name@example.com';

  @override
  String get invalidAddress => '無効なアドレス';

  @override
  String get unableToConnect => '接続できません';

  @override
  String get publicKeyHint => 'npub1...';

  @override
  String get privateKeyHint => 'nsec1...';

  @override
  String get newToNostr => 'Nostrは初めてですか？';

  @override
  String get getStarted => '始める';

  @override
  String get bunker => 'バンカー';

  @override
  String get bunkerAuthentication => 'バンカー認証';

  @override
  String tapToOpen(String url) {
    return 'タップして開く：$url';
  }

  @override
  String get showNostrConnectQrcode => 'nostr connect QRコードを表示';

  @override
  String get loginWithSignerApp => '署名アプリでログイン';

  @override
  String get nostrConnectUrl => 'Nostr接続URL';

  @override
  String get copy => 'コピー';

  @override
  String get addAccount => 'アカウントを追加';

  @override
  String get readOnly => '読み取り専用';

  @override
  String get nsec => 'Nsec';

  @override
  String get extension => '拡張機能';

  @override
  String get userMetadata => 'ユーザーメタデータ';

  @override
  String get shortTextNote => '短いテキストノート';

  @override
  String get recommendRelay => 'リレー推奨';

  @override
  String get follows => 'フォロー';

  @override
  String get encryptedDirectMessages => '暗号化ダイレクトメッセージ';

  @override
  String get eventDeletionRequest => 'イベント削除リクエスト';

  @override
  String get repost => 'リポスト';

  @override
  String get reaction => 'リアクション';

  @override
  String get badgeAward => 'バッジ授与';

  @override
  String get chatMessage => 'チャットメッセージ';

  @override
  String get groupChatThreadedReply => 'グループチャットスレッド返信';

  @override
  String get thread => 'スレッド';

  @override
  String get groupThreadReply => 'グループスレッド返信';

  @override
  String get seal => 'シール';

  @override
  String get directMessage => 'ダイレクトメッセージ';

  @override
  String get fileMessage => 'ファイルメッセージ';

  @override
  String get genericRepost => '汎用リポスト';

  @override
  String get reactionToWebsite => 'ウェブサイトへのリアクション';

  @override
  String get picture => '画像';

  @override
  String get videoEvent => '動画イベント';

  @override
  String get shortFormPortraitVideoEvent => '短編縦型動画';

  @override
  String get internalReference => '内部参照';

  @override
  String get externalReference => '外部参照';

  @override
  String get hardcopyReference => '印刷物参照';

  @override
  String get promptReference => 'プロンプト参照';

  @override
  String get channelCreation => 'チャンネル作成';

  @override
  String get channelMetadata => 'チャンネルメタデータ';

  @override
  String get channelMessage => 'チャンネルメッセージ';

  @override
  String get channelHideMessage => 'チャンネルメッセージを隠す';

  @override
  String get channelMuteUser => 'チャンネルユーザーをミュート';

  @override
  String get requestToVanish => '消去リクエスト';

  @override
  String get chessPgn => 'チェス（PGN）';

  @override
  String get mlsKeyPackage => 'MLSキーパッケージ';

  @override
  String get mlsWelcome => 'MLSウェルカム';

  @override
  String get mlsGroupEvent => 'MLSグループイベント';

  @override
  String get mergeRequests => 'マージリクエスト';

  @override
  String get pollResponse => '投票回答';

  @override
  String get marketplaceBid => 'マーケット入札';

  @override
  String get marketplaceBidConfirmation => '入札確認';

  @override
  String get openTimestamps => 'OpenTimestamps';

  @override
  String get giftWrap => 'ギフトラップ';

  @override
  String get fileMetadata => 'ファイルメタデータ';

  @override
  String get poll => '投票';

  @override
  String get comment => 'コメント';

  @override
  String get voiceMessage => '音声メッセージ';

  @override
  String get voiceMessageComment => '音声メッセージコメント';

  @override
  String get liveChatMessage => 'ライブチャットメッセージ';

  @override
  String get codeSnippet => 'コードスニペット';

  @override
  String get gitPatch => 'Gitパッチ';

  @override
  String get gitPullRequest => 'Gitプルリクエスト';

  @override
  String get gitStatusUpdate => 'Gitステータス更新';

  @override
  String get gitIssue => 'Git Issue';

  @override
  String get gitIssueUpdate => 'Git Issue更新';

  @override
  String get status => 'ステータス';

  @override
  String get statusUpdate => 'ステータス更新';

  @override
  String get statusDelete => 'ステータス削除';

  @override
  String get statusReply => 'ステータス返信';

  @override
  String get problemTracker => '問題トラッカー';

  @override
  String get reporting => '報告';

  @override
  String get label => 'ラベル';

  @override
  String get relayReviews => 'リレーレビュー';

  @override
  String get aiEmbeddings => 'AI埋め込み / ベクトルリスト';

  @override
  String get torrent => 'トレント';

  @override
  String get torrentComment => 'トレントコメント';

  @override
  String get coinjoinPool => 'Coinjoinプール';

  @override
  String get communityPostApproval => 'コミュニティ投稿承認';

  @override
  String get jobRequest => 'ジョブリクエスト';

  @override
  String get jobResult => 'ジョブ結果';

  @override
  String get jobFeedback => 'ジョブフィードバック';

  @override
  String get cashuWalletToken => 'Cashuウォレットトークン';

  @override
  String get cashuWalletProofs => 'Cashuウォレット証明';

  @override
  String get cashuWalletHistory => 'Cashuウォレット履歴';

  @override
  String get geocacheCreate => 'ジオキャッシュ作成';

  @override
  String get geocacheUpdate => 'ジオキャッシュ更新';

  @override
  String get groupControlEvent => 'グループ制御イベント';

  @override
  String get zapGoal => 'Zapゴール';

  @override
  String get nutzap => 'Nutzap';

  @override
  String get tidalLogin => 'Tidalログイン';

  @override
  String get zapRequest => 'Zapリクエスト';

  @override
  String get zap => 'Zap';

  @override
  String get highlights => 'ハイライト';

  @override
  String get muteList => 'ミュートリスト';

  @override
  String get pinList => 'ピンリスト';

  @override
  String get relayListMetadata => 'リレーリストメタデータ';

  @override
  String get bookmarkList => 'ブックマークリスト';

  @override
  String get communitiesList => 'コミュニティリスト';

  @override
  String get publicChatsList => '公開チャットリスト';

  @override
  String get blockedRelaysList => 'ブロックリレーリスト';

  @override
  String get searchRelaysList => '検索リレーリスト';

  @override
  String get userGroups => 'ユーザーグループ';

  @override
  String get favoritesList => 'お気に入りリスト';

  @override
  String get privateEventsList => 'プライベートイベントリスト';

  @override
  String get interestsList => '興味リスト';

  @override
  String get mediaFollowsList => 'メディアフォローリスト';

  @override
  String get peopleFollowsList => 'ユーザーフォローリスト';

  @override
  String get userEmojiList => 'ユーザー絵文字リスト';

  @override
  String get dmRelayList => 'DMリレーリスト';

  @override
  String get keyPackageRelayList => 'キーパッケージリレーリスト';

  @override
  String get userServerList => 'ユーザーサーバーリスト';

  @override
  String get fileStorageServerList => 'ファイルストレージサーバーリスト';

  @override
  String get relayMonitorAnnouncement => 'リレーモニター告知';

  @override
  String get roomPresence => 'ルームプレゼンス';

  @override
  String get proxyAnnouncement => 'プロキシ告知';

  @override
  String get transportMethodAnnouncement => 'トランスポート方式告知';

  @override
  String get walletInfo => 'ウォレット情報';

  @override
  String get cashuWalletEvent => 'Cashuウォレットイベント';

  @override
  String get lightningPubRpc => 'Lightning Pub RPC';

  @override
  String get clientAuthentication => 'クライアント認証';

  @override
  String get walletRequest => 'ウォレットリクエスト';

  @override
  String get walletResponse => 'ウォレットレスポンス';

  @override
  String get nostrConnectEvent => 'Nostr Connect';

  @override
  String get blobsStoredOnMediaservers => 'メディアサーバー上のBlob';

  @override
  String get httpAuth => 'HTTP認証';

  @override
  String get categorizedPeopleList => 'カテゴリ別ユーザーリスト';

  @override
  String get categorizedBookmarkList => 'カテゴリ別ブックマークリスト';

  @override
  String get categorizedRelayList => 'カテゴリ別リレーリスト';

  @override
  String get bookmarkSets => 'ブックマークセット';

  @override
  String get curationSets => 'キュレーションセット';

  @override
  String get videoSets => '動画セット';

  @override
  String get kindMuteSets => 'Kindミュートセット';

  @override
  String get profileBadges => 'プロフィールバッジ';

  @override
  String get badgeDefinition => 'バッジ定義';

  @override
  String get interestSets => '興味セット';

  @override
  String get createOrUpdateStall => 'ストール作成・更新';

  @override
  String get createOrUpdateProduct => '商品作成・更新';

  @override
  String get marketplaceUiUx => 'マーケットプレイスUI/UX';

  @override
  String get productSoldAsAuction => 'オークション販売商品';

  @override
  String get longFormContent => '長文コンテンツ';

  @override
  String get draftLongFormContent => '長文下書き';

  @override
  String get emojiSets => '絵文字セット';

  @override
  String get curatedPublicationItem => 'キュレーション出版アイテム';

  @override
  String get curatedPublicationDraft => 'キュレーション出版下書き';

  @override
  String get releaseArtifactSets => 'リリースアーティファクトセット';

  @override
  String get applicationSpecificData => 'アプリ固有データ';

  @override
  String get relayDiscovery => 'リレー検出';

  @override
  String get appCurationSets => 'アプリキュレーションセット';

  @override
  String get liveEvent => 'ライブイベント';

  @override
  String get userStatus => 'ユーザーステータス';

  @override
  String get slideSet => 'スライドセット';

  @override
  String get classifiedListing => 'クラシファイド広告';

  @override
  String get draftClassifiedListing => 'クラシファイド広告下書き';

  @override
  String get repositoryAnnouncement => 'リポジトリ告知';

  @override
  String get repositoryStateAnnouncement => 'リポジトリ状態告知';

  @override
  String get wikiArticle => 'Wiki記事';

  @override
  String get redirects => 'リダイレクト';

  @override
  String get draftEvent => 'イベント下書き';

  @override
  String get linkSet => 'リンクセット';

  @override
  String get feed => 'フィード';

  @override
  String get dateBasedCalendarEvent => '日付ベースカレンダーイベント';

  @override
  String get timeBasedCalendarEvent => '時間ベースカレンダーイベント';

  @override
  String get calendar => 'カレンダー';

  @override
  String get calendarEventRsvp => 'カレンダーイベントRSVP';

  @override
  String get handlerRecommendation => 'ハンドラー推奨';

  @override
  String get handlerInformation => 'ハンドラー情報';

  @override
  String get softwareApplication => 'ソフトウェアアプリケーション';

  @override
  String get videoView => '動画ビュー';

  @override
  String get communityDefinition => 'コミュニティ定義';

  @override
  String get geocacheListing => 'ジオキャッシュリスト';

  @override
  String get mintAnnouncement => 'Mint告知';

  @override
  String get mintQuote => 'Mint見積';

  @override
  String get peerToPeerOrder => 'P2P注文';

  @override
  String get groupMetadata => 'グループメタデータ';

  @override
  String get groupAdminMetadata => 'グループ管理者メタデータ';

  @override
  String get groupMemberMetadata => 'グループメンバーメタデータ';

  @override
  String get groupAdminsList => 'グループ管理者リスト';

  @override
  String get groupMembersList => 'グループメンバーリスト';

  @override
  String get groupRoles => 'グループロール';

  @override
  String get groupPermissions => 'グループ権限';

  @override
  String get groupChatMessage => 'グループチャットメッセージ';

  @override
  String get groupChatThread => 'グループチャットスレッド';

  @override
  String get groupPinned => 'グループピン留め';

  @override
  String get starterPacks => 'スターターパック';

  @override
  String get mediaStarterPacks => 'メディアスターターパック';

  @override
  String get webBookmarks => 'ウェブブックマーク';

  @override
  String unknownEventKind(int kind) {
    return 'イベント種別 $kind';
  }

  @override
  String get walletsTitle => 'ウォレット';

  @override
  String get recentActivityTitle => '最近のアクティビティ';

  @override
  String get addCashuWallet => 'Cashuウォレットを追加';

  @override
  String get addNwcWallet => 'NWCウォレットを追加';

  @override
  String get addLnurlWallet => 'LNURLウォレットを追加';

  @override
  String get addCashuTooltip => 'Cashuウォレットを追加';

  @override
  String get addNwcTooltip => 'NWCウォレットを追加';

  @override
  String get addLnurlTooltip => 'LNURLウォレットを追加';

  @override
  String get addCashuWalletTitle => 'Cashuウォレットを追加';

  @override
  String get enterMintUrl => 'Cashuウォレットを追加するにはミントURLを入力してください。';

  @override
  String get mintUrl => 'ミントURL';

  @override
  String get mintUrlHint => 'https://mint.example.com';

  @override
  String get pleaseEnterMintUrl => 'ミントURLを入力してください';

  @override
  String get cashuWalletAdded => 'Cashuウォレットが正常に追加されました！';

  @override
  String get failedToAddMint => 'ミントの追加に失敗しました。URLを確認して再試行してください。';

  @override
  String get addNwcWalletTitle => 'NWCウォレットを追加';

  @override
  String get faucet => 'フォーセット';

  @override
  String get manual => '手動';

  @override
  String get nwcFaucetDescription => 'NWCフォーセットからsatsを使ってテストウォレットを作成します。';

  @override
  String get startingBalance => '開始残高';

  @override
  String get startingBalanceHint => '10000';

  @override
  String get nwcConnectionUri => 'NWC接続URI';

  @override
  String get nwcConnectionUriHint => 'nostr+walletconnect://...';

  @override
  String get nwcWalletAdded => 'NWCウォレットが正常に追加されました！';

  @override
  String nwcFaucetWalletAdded(int balance) {
    return '$balance satsのNWCフォーセットウォレットが追加されました！';
  }

  @override
  String get invalidFaucetResponse => 'フォーセットからの無効な応答';

  @override
  String get errorCreatingWallet => 'ウォレットの作成エラー';

  @override
  String get addLnurlWalletTitle => 'LNURLウォレットを追加';

  @override
  String get enterLnurlIdentifier => 'LNURL識別子（user@domain.com）を入力してください。';

  @override
  String get lnurlIdentifierHint => 'user@example.com';

  @override
  String get pleaseEnterValidIdentifier => '有効な識別子（user@domain.com）を入力してください';

  @override
  String get lnurlWalletAdded => 'LNURLウォレットが正常に追加されました！';

  @override
  String get cancel => 'キャンセル';

  @override
  String get add => '追加';

  @override
  String get send => '送信';

  @override
  String get receive => '受信';

  @override
  String get setAsDefaultForReceiving => '受信のデフォルトに設定';

  @override
  String get setAsDefaultForSending => '送信のデフォルトに設定';

  @override
  String get defaultForReceiving => '受信のデフォルト';

  @override
  String get defaultForSending => '送信のデフォルト';

  @override
  String get defaultWalletForReceivingTooltip => 'このウォレットは受信のデフォルトです。';

  @override
  String get defaultWalletForSendingTooltip => 'このウォレットは送信のデフォルトです。';

  @override
  String get sendOptionsTitle => '送信オプション';

  @override
  String get sendByToken => 'トークンで送信';

  @override
  String get sendByTokenDescription => '送信するCashuトークンを作成';

  @override
  String get sendByLightning => 'Lightningで送信';

  @override
  String get sendByLightningDescription => 'Lightning請求書を支払う';

  @override
  String get payInvoiceTitle => '請求書を支払う';

  @override
  String get sendToWallet => 'Send to Wallet';

  @override
  String get sendToWalletDescription => 'Transfer to another compatible wallet';

  @override
  String get noCompatibleReceivingWallets => 'No compatible receiving wallets';

  @override
  String get noCompatibleReceivingWalletsDescription =>
      'Add or connect another wallet that can receive a payment supported by this wallet.';

  @override
  String get destinationWallet => 'Destination wallet';

  @override
  String walletTransferSubmitted(String walletName) {
    return 'Payment sent to $walletName';
  }

  @override
  String get invoice => '請求書';

  @override
  String get invoiceHint => 'lnbc...';

  @override
  String get pleaseEnterInvoice => '請求書を入力してください';

  @override
  String get invoicePaid => '請求書が支払われました！';

  @override
  String paymentFailed(String message) {
    return '支払い失敗：$message';
  }

  @override
  String get receiveOptionsTitle => '受信オプション';

  @override
  String get receiveByToken => 'トークンで受信';

  @override
  String get receiveByTokenDescription => 'Cashuトークンを受信';

  @override
  String get receiveByLightning => 'Lightningで受信';

  @override
  String get receiveByLightningDescription => 'Lightning請求書を作成';

  @override
  String get receiveByTokenTitle => 'トークンで受信';

  @override
  String get token => 'トークン';

  @override
  String get tokenHint => 'トークンをここに貼り付け...';

  @override
  String get pleaseEnterToken => 'トークンを入力してください';

  @override
  String get tokenReceived => 'トークンを受信しました！';

  @override
  String get createInvoiceTitle => '請求書を作成';

  @override
  String get amount => '金額';

  @override
  String get amountHint => '100';

  @override
  String get pleaseEnterValidAmount => '有効な金額を入力してください';

  @override
  String get tokenCopiedToClipboard => 'トークンをクリップボードにコピーしました！';

  @override
  String get invoiceCreatedAndCopied => '請求書を作成してコピーしました！';

  @override
  String get invoiceTrackingTitle => 'Lightning請求書';

  @override
  String get invoiceCreatedMessage => '請求書を作成してコピーしました！';

  @override
  String get close => '閉じる';

  @override
  String get copyAgain => '再度コピー';

  @override
  String get copied => 'コピーしました！';

  @override
  String get paymentReceived => '支払いを受信しました！';

  @override
  String get waitingForPayment => '支払いを待っています...';

  @override
  String get paid => '支払い完了！';

  @override
  String get createToken => 'トークンを作成';

  @override
  String get pay => '支払う';

  @override
  String get create => '作成';

  @override
  String get pendingTransactions => '保留中';

  @override
  String get backupSeedWarning => 'Cashuリカバリーフレーズをバックアップしてください';

  @override
  String get backupSeedTitle => 'Cashuリカバリーフレーズのバックアップ';

  @override
  String get backupSeedInstructions =>
      'これらの単語を順番に書き留め、安全な場所に保管してください。この端末を紛失した場合、cashu資金を復元する唯一の方法です。';

  @override
  String get backupSeedConfirm => 'リカバリーフレーズを書き留め、安全に保管しました';

  @override
  String get backupSeedDone => 'バックアップしました';

  @override
  String get reclaimPendingFunds => '保留中の資金を回収';

  @override
  String get reclaimPendingTitle => '保留中の資金を回収';

  @override
  String get recentTransactions => '最近の取引';

  @override
  String get noRecentTransactions => '最近の取引はありません';

  @override
  String get noWalletsYet => 'ウォレットはまだありません';

  @override
  String get noWalletsAvailable => '利用可能なウォレットがありません';

  @override
  String get tapToAddWallet => '+をタップして追加';

  @override
  String get delete => '削除';

  @override
  String error(String message) {
    return 'エラー：$message';
  }

  @override
  String get unknownWalletType => '不明';

  @override
  String get cashuWallet => 'Cashu';

  @override
  String get nwcWallet => 'NWC';

  @override
  String get lnurlWallet => 'LNURL';

  @override
  String get nwcWalletSubtitle => 'NWCウォレット';

  @override
  String get balance => '残高';

  @override
  String get sats => 'sats';

  @override
  String get selected => '選択済み';

  @override
  String get receiveOnlyWallet => '受信専用ウォレット';

  @override
  String receiveRange(int min, int max) {
    return '受信：$min - $max sats';
  }

  @override
  String get limitsUnavailable => '制限情報は利用できません';

  @override
  String get tokenCopied => 'トークンをコピーしました';

  @override
  String get deleteWalletConfirmation => 'ウォレットを削除しますか?';

  @override
  String get deleteWalletConfirmationMessage =>
      'このウォレットを削除してもよろしいですか? この操作は元に戻せません。';

  @override
  String get addWalletTitle => 'ウォレットを追加';

  @override
  String get addWalletDescription =>
      '対応するウォレットのQRコードをスキャンするか、接続情報を貼り付けるか、ウォレットアプリから接続します。';

  @override
  String get scanWalletQrCode => 'ウォレットのQRコードをスキャン';

  @override
  String get connectWithWallet => 'ウォレットに接続';

  @override
  String get chooseWalletApp => 'ウォレットアプリを選択';

  @override
  String get oneClickConnect => '1クリック接続';

  @override
  String get chooseWallet => 'ウォレットを選択';

  @override
  String get albyWalletOption => 'Alby';

  @override
  String get albyCloudOption => 'Alby Cloud';

  @override
  String get coinosWalletOption => 'Coinos';

  @override
  String get manualNwcConnection => 'NWCを手動接続';

  @override
  String walletConnectionFinishIn(String walletName) {
    return '$walletNameで接続を完了してください';
  }

  @override
  String walletConnectionConnecting(String walletName) {
    return '$walletNameに接続中…';
  }

  @override
  String walletConnectionConnected(String walletName) {
    return '$walletNameに接続しました';
  }

  @override
  String walletConnectionFailed(String walletName) {
    return '$walletNameに接続できませんでした';
  }

  @override
  String get retry => '再試行';

  @override
  String get walletUnreachable => 'ウォレットに接続できません';

  @override
  String get chooseAnotherWallet => '別のウォレットを選択';

  @override
  String get chooseWalletAppDescription => 'インストール済みウォレットでNWC接続を承認します';

  @override
  String get walletInput => 'ウォレットアドレスまたは接続情報';

  @override
  String get walletInputHint =>
      'NWC、Lightning/BIP353アドレス、BOLT12/BIP321オファー、またはCashuミントのHTTPS URL';

  @override
  String get unsupportedWalletInput => '対応していないウォレットアドレスまたは接続情報です。';

  @override
  String get detected => '検出済み';

  @override
  String get lightningAddressInputType => 'LightningまたはBIP353アドレス';

  @override
  String get manualWalletSetup => '手動で設定';

  @override
  String get chooseWalletType => 'ウォレットタイプを選択';

  @override
  String get nwcWalletTypeTitle => 'Nostr Wallet Connect';

  @override
  String get nwcWalletTypeSubtitle => 'NWCでリモートウォレットに接続';

  @override
  String get lnurlWalletTypeTitle => 'Lightningアドレス（LNURL）';

  @override
  String get lnurlWalletTypeSubtitle => '受信専用にLightningアドレス（LNURL）を使う';

  @override
  String get cashuWalletTypeTitle => 'Cashu';

  @override
  String get chooseCashuMint => 'Cashuミントを選択';

  @override
  String get cashuMintRatingsNotice =>
      'コミュニティ評価は署名済みNostrレビューに基づきます。高評価でもミントの安全性は保証されません。';

  @override
  String get cashuMintDiscoveryFailed => 'ミント候補を読み込めませんでした。';

  @override
  String get noCashuMintSuggestions => '利用可能なミント候補が見つかりません。';

  @override
  String get noRatingsYet => 'まだ評価がありません';

  @override
  String cashuMintRating(String rating, int count) {
    return '★ $rating · $count件のレビュー';
  }

  @override
  String get enterMintUrlManually => 'ミントURLを手動入力';

  @override
  String get cashuWalletTypeSubtitle => 'Cashuミント対応のecashウォレットを使う';

  @override
  String get cashuOption => 'Cashu';

  @override
  String get nwcOption => 'NWC';

  @override
  String get lnurlOption => 'LNURL';

  @override
  String get connectNwcTitle => 'NWCを接続';

  @override
  String get chooseNwcMethod => '接続方法を選択';

  @override
  String get albyGoOption => 'Alby Go';

  @override
  String get albyGoQrScanInstructions =>
      'Alby Goで「送信」をタップして、このQRコードをスキャンしてください。';

  @override
  String get manualOption => '手動';

  @override
  String get faucetOption => 'Faucet';

  @override
  String get invalidNwcQrCode => '無効なNWC QRコード';

  @override
  String get scanNwcQrCodeTitle => 'NWC QRコードをスキャン';

  @override
  String get cameraNotAvailable => 'カメラが利用できません';

  @override
  String get scanNwcInstructions => 'NWCウォレットアプリからQRコードをスキャンしてください';

  @override
  String get invalidNwcUri => '無効なNWC URI';

  @override
  String get paste => '貼り付け';

  @override
  String get clearInput => '入力を消去';

  @override
  String get pasteOrEnter => '貼り付けまたは入力';

  @override
  String get fromYourProfile => 'プロフィールから';

  @override
  String get orEnterManually => 'または手動で入力:';

  @override
  String get renameWallet => '名前を変更';

  @override
  String get pickColor => '色を選択';

  @override
  String get deleteWallet => '削除';

  @override
  String get walletName => 'ウォレット名';

  @override
  String get walletNameHint => 'ウォレット名を入力';

  @override
  String get save => '保存';

  @override
  String get walletRenamed => 'ウォレット名を変更しました';

  @override
  String budgetUsedOf(int used, int total) {
    final intl.NumberFormat usedNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String usedString = usedNumberFormat.format(used);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return '予算: $usedString / $totalString';
  }

  @override
  String budgetRenewsIn(int days) {
    return '$days 日後に更新';
  }

  @override
  String get budgetDaily => '毎日';

  @override
  String get budgetWeekly => '毎週';

  @override
  String get budgetMonthly => '毎月';

  @override
  String get budgetYearly => '毎年';

  @override
  String get budgetNever => 'なし';

  @override
  String get backup => 'Backup';

  @override
  String get restore => 'Restore';

  @override
  String get cashuBackupTitle => 'Cashu Backup';

  @override
  String get cashuBackupWarning =>
      'This backup contains your ecash proofs, which are bearer funds. Keep it private and store it somewhere safe. Your seed phrase is backed up separately.';

  @override
  String get generatingBackup => 'Generating backup...';

  @override
  String get copyBackup => 'Copy backup';

  @override
  String get backupCopiedToClipboard => 'Backup copied to clipboard';

  @override
  String get cashuRestoreTitle => 'Restore Cashu Backup';

  @override
  String get backupJson => 'Backup JSON';

  @override
  String get backupJsonHint => 'Paste your backup JSON here';

  @override
  String get pleaseEnterBackup => 'Please enter a backup';

  @override
  String get restoringBackup => 'Restoring backup...';

  @override
  String appUpdateVersionAvailable(String version) {
    return 'バージョン $version を利用できます';
  }

  @override
  String get appUpdateLater => '後で';

  @override
  String get appUpdateView => '更新を表示';

  @override
  String get appUpdateChecking => '更新を確認中…';

  @override
  String get appUpdateCheckFailed => '更新の確認に失敗しました';

  @override
  String appUpdateInstalled(String version) {
    return 'インストール済み: $version';
  }

  @override
  String get appUpdatesTitle => 'アプリの更新';

  @override
  String get appUpdateNone => '利用できる更新はありません';

  @override
  String appUpdateTitle(String currentVersion, String availableVersion) {
    return '更新 $currentVersion → $availableVersion';
  }

  @override
  String appUpdateSizeMb(String size) {
    return '$size MB';
  }

  @override
  String get appUpdateAllowInstalls => 'このアプリからのインストールを許可し、もう一度「更新」をタップしてください。';

  @override
  String get appUpdateCompleteInstallation =>
      'Android システムインストーラーでインストールを完了してください。';

  @override
  String get appUpdateFailed => '更新に失敗しました';

  @override
  String get appUpdateCancel => 'キャンセル';

  @override
  String get appUpdateAction => '更新';

  @override
  String get appUpdateDownload => 'ダウンロード';

  @override
  String get appUpdateUpToDate => '最新の状態です';

  @override
  String get appUpdateAheadOfPublished => '公開版より新しいバージョン';

  @override
  String appUpdateAheadOfPublishedMessage(
    String installedVersion,
    String publishedVersion,
  ) {
    return 'インストール済みバージョン $installedVersion は、最新の公開版 $publishedVersion より新しいものです。このバージョンが公開されるとリリース詳細が表示されます。';
  }

  @override
  String get appUpdateCheckFailedMessage => '更新を確認できませんでした。';

  @override
  String appUpdateLatest(String version) {
    return 'バージョン $version が利用可能な最新バージョンです。';
  }

  @override
  String get appUpdateClose => '閉じる';

  @override
  String get appUpdateCheckAgain => '再確認';

  @override
  String appUpdateInstalledVersion(String version) {
    return 'インストール済みバージョン $version';
  }

  @override
  String appUpdateInstalledAndAvailable(
    String installedVersion,
    String availableVersion,
  ) {
    return 'インストール済みバージョン $installedVersion。更新 $availableVersion を利用できます。';
  }

  @override
  String get appUpdateChangelog => '変更履歴';

  @override
  String get appUpdateReleaseHistory => 'リリース履歴';

  @override
  String get appUpdateInstalledBadge => 'インストール済み';

  @override
  String get appUpdateAvailableBadge => '更新可能';

  @override
  String get appUpdateLatestBadge => '最新';

  @override
  String get appUpdateNoReleases => 'まだリリースは公開されていません。';

  @override
  String get appUpdateAcrossAllReleases => 'すべてのリリース共通';

  @override
  String get appUpdateReleaseDetails => 'リリース詳細';

  @override
  String get appUpdateWhatsNew => '新機能';

  @override
  String appUpdatePublishedOn(String date) {
    return '$date に公開';
  }

  @override
  String appUpdateChannel(String channel) {
    return 'チャンネル: $channel';
  }

  @override
  String appUpdateArchitecture(String architecture) {
    return 'アーキテクチャ: $architecture';
  }

  @override
  String appUpdateVersionCode(int versionCode) {
    return 'ビルド $versionCode';
  }

  @override
  String appUpdateReleaseVersion(String version) {
    return 'リリース $version';
  }

  @override
  String get appUpdateNoReleaseNotes => 'リリースノートはありません。';

  @override
  String get appUpdatePublisher => '公開者';

  @override
  String get appUpdatePublisherSignatureVerified => 'Nostrイベントの署名を確認済み';

  @override
  String get appUpdateCertificateDeclared => '公開者がAndroid署名証明書を宣言済み';

  @override
  String appUpdateSource(String host) {
    return 'ダウンロード元: $host';
  }

  @override
  String get appUpdateCommunity => 'コミュニティ';

  @override
  String appUpdateZapSummary(int count, int sats) {
    return '$count zap・$sats sats';
  }

  @override
  String get appUpdateSatsBy => 'sats、送信者';

  @override
  String appUpdateReactionCount(int count) {
    return 'リアクション $count件';
  }

  @override
  String appUpdateCommentCount(int count) {
    return 'コメント $count件';
  }

  @override
  String get appUpdateSocialLoadFailed => 'コミュニティ情報を読み込めませんでした。';

  @override
  String get appUpdateComments => 'コメント';

  @override
  String get appUpdateNoComments => 'コメントはまだありません。';

  @override
  String get appUpdateCommentHint => 'このリリースへの感想を共有';

  @override
  String get appUpdatePostComment => 'コメントを投稿';

  @override
  String get appUpdateSignInToComment => 'コメントするにはNostrアカウントでログインしてください。';

  @override
  String get appUpdateTechnicalDetails => '技術情報';

  @override
  String get appUpdateViewStatus => '更新状態を表示';

  @override
  String restoreSuccess(int count) {
    return 'Restored $count proofs from backup';
  }

  @override
  String get bolt12Wallet => 'BOLT12ウォレット';

  @override
  String get bolt12WalletSubtitle => 'Reusable Lightning offer';

  @override
  String get bolt12PrivateOfferSubtitle => 'Reusable private offer';

  @override
  String get anyAmount => 'Any amount';

  @override
  String get blindedRoute => 'Blinded';

  @override
  String fromAmountSats(String amount) {
    return 'From $amount sats';
  }

  @override
  String fromAmountMsats(String amount) {
    return 'From $amount msats';
  }

  @override
  String fromCurrencyAmount(String amount, String currency) {
    return 'From $amount $currency';
  }

  @override
  String bolt12Expires(String date) {
    return 'Expires $date';
  }

  @override
  String get bolt12WalletTypeTitle => 'BOLT12オファー';

  @override
  String get bip353WalletTypeTitle => 'BIP353';

  @override
  String get lnurlProtocol => 'LNURL';

  @override
  String get bolt12WalletTypeSubtitle =>
      'Receive-only wallet using a reusable offer';

  @override
  String get addBolt12WalletTitle => 'BOLT12ウォレットを追加';

  @override
  String get enterBolt12Input =>
      'lnoオファー、bitcoin:?lno=… URI、またはBIP353アドレスを入力またはスキャンしてください。';

  @override
  String get bolt12Input => 'BOLT12支払い先';

  @override
  String get bolt12InputHint => 'lno1…、bitcoin:?lno=…、またはuser@domain.com';

  @override
  String get walletNameOptional => 'ウォレット名（任意）';

  @override
  String get scanBolt12QrCodeTitle => 'BOLT12 QRコードをスキャン';

  @override
  String get invalidBolt12QrCode =>
      'The QR code is not a BOLT12, BIP321, or BIP353 payment target.';

  @override
  String get pleaseEnterBolt12Input => 'BOLT12オファーまたはBIP353アドレスを入力してください。';

  @override
  String get bolt12WalletAdded => 'BOLT12ウォレットを追加しました！';

  @override
  String get bolt12OfferTitle => 'Receive with BOLT12';

  @override
  String get bolt12OfferInstructions =>
      'Share this reusable offer to receive a Lightning payment.';

  @override
  String get confirm => '確認';

  @override
  String get reviewWallet => 'ウォレットを確認';

  @override
  String get confirmWalletTitle => 'ウォレットを確認';

  @override
  String get confirmWalletDescription => 'このウォレットを追加する前に詳細を確認してください。';

  @override
  String get walletDetailType => 'ウォレットの種類';

  @override
  String get walletDetailAddress => 'アドレス';

  @override
  String get walletDetailDomain => 'ドメイン';

  @override
  String get walletDetailUrl => 'URL';

  @override
  String get walletDetailPublicKey => '公開鍵';

  @override
  String get walletDetailRelay => 'リレー';

  @override
  String get walletDetailRelays => 'リレー';

  @override
  String get walletDetailSecret => '接続シークレット';

  @override
  String get walletSecretHidden => '存在します（安全のため非表示）';

  @override
  String get walletDetailDescription => '説明';

  @override
  String get walletDetailDetails => '詳細';

  @override
  String get walletDetailIssuer => '発行者';

  @override
  String get walletDetailAmount => '金額';

  @override
  String get walletDetailCurrency => '通貨';

  @override
  String get walletDetailExpiry => '有効期限';

  @override
  String get walletDetailNodeId => 'ノードID';

  @override
  String get walletDetailOffer => 'BOLT12オファー';

  @override
  String get walletDetailVersion => 'バージョン';

  @override
  String get walletDetailUnits => '対応単位';

  @override
  String get walletDetailContact => '連絡先';

  @override
  String get walletDetailTerms => '利用規約';

  @override
  String get walletDetailMessage => 'メッセージ';

  @override
  String get walletDetailCommunityRating => 'コミュニティ評価';

  @override
  String get walletDetailCommunityReviews => '最近のコミュニティレビュー';

  @override
  String get refreshBalance => '残高を更新';

  @override
  String get balanceRefreshed => '残高を更新しました';
}
