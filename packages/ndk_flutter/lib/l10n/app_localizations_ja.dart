// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

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
  String get loginWithAmber => 'Amberでログイン';

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
}
