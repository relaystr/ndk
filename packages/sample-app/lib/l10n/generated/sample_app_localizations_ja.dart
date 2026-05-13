// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'sample_app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class SampleAppLocalizationsJa extends SampleAppLocalizations {
  SampleAppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appName => 'Nostr Developer Kit デモ';

  @override
  String get appBarTitle => 'NDK デモ';

  @override
  String get tabAccounts => 'アカウント';

  @override
  String get tabProfile => 'プロフィール';

  @override
  String get tabRelays => 'リレー';

  @override
  String get tabBlossom => 'Blossom';

  @override
  String get tabWallets => 'ウォレット';

  @override
  String get tabWidgets => 'ウィジェット';

  @override
  String get profileTooltip => 'プロフィール';

  @override
  String get loginDialogDefaultTitle => 'ログイン';

  @override
  String get loginDialogAddAccountTitle => 'アカウントを追加';

  @override
  String get closeTooltip => '閉じる';

  @override
  String get accountsHeading => 'アカウント';

  @override
  String get accountsDescription => 'ログイン中のアカウントを管理し、新しいアカウントを追加します。';

  @override
  String get addAnotherAccount => '別のアカウントを追加';

  @override
  String get logIn => 'ログイン';

  @override
  String get profileNoAccount => 'ログイン中のアカウントがありません。';

  @override
  String get profileAbout => '概要';

  @override
  String profileMetadataError(Object error) {
    return 'メタデータの取得エラー: $error';
  }

  @override
  String get relaysLoginRequired => 'リレー一覧を表示するにはログインしてください。';

  @override
  String get relaysFetchButton => 'リレー一覧を取得';

  @override
  String get relayListHeading => 'リレー一覧';

  @override
  String relayConfiguredCount(int count) {
    return '$count 件の設定済みリレー';
  }

  @override
  String relayConnection(Object state) {
    return '接続: $state';
  }

  @override
  String get relayRead => '読み取り';

  @override
  String get relayWrite => '書き込み';

  @override
  String get relayStateConnecting => '接続中';

  @override
  String get relayStateOnline => 'オンライン';

  @override
  String get relayStateOffline => 'オフライン';

  @override
  String get relayStateUnknown => '不明';

  @override
  String get widgetsPageTitle => 'NDK Flutter Widgets デモ';

  @override
  String get widgetsLoginHint => 'パーソナライズされたウィジェットを見るには、アカウントタブからログインしてください。';

  @override
  String get widgetsCurrentUser => '現在のユーザー: ';

  @override
  String get widgetsSizeDefault => '標準';

  @override
  String get widgetsSizeLarger => 'やや大きい';

  @override
  String get widgetsSizeLarge => '大';

  @override
  String get widgetsShowLoginWidget => 'NLogin ウィジェットを表示';

  @override
  String get widgetsLoginWidgetTitle => 'NLogin ウィジェット';

  @override
  String widgetsRequiresLogin(Object widgetName) {
    return '$widgetName\\n(ログインが必要です)';
  }

  @override
  String get widgetsSectionNNameDescription =>
      'メタデータからユーザー名を表示し、なければ整形済み npub を表示します。';

  @override
  String get widgetsSectionNPictureDescription =>
      'プロフィール画像を表示し、なければイニシャルを表示します。';

  @override
  String get widgetsSectionNBannerDescription => 'バナー画像を表示し、なければ色付きコンテナを表示します。';

  @override
  String get widgetsSectionNUserProfileDescription =>
      'バナー、画像、名前、NIP-05 を含む完全なユーザープロフィールです。';

  @override
  String get widgetsSectionNSwitchAccountDescription =>
      'アカウント切り替えとログアウトを備えたアカウント管理ウィジェットです。';

  @override
  String get widgetsSectionNLoginDescription =>
      '複数の認証方法 (NIP-05、npub、nsec、bunker など) に対応したログインウィジェットです。';

  @override
  String get widgetsSectionGetColorDescription =>
      'pubkey から決定的な色を生成する静的メソッドです。';

  @override
  String get blossomPageTitle => 'Blossom メディアとファイル操作';

  @override
  String get blossomImageDemoTitle => '画像デモ (getBlob)';

  @override
  String get blossomVideoDemoTitle => '動画デモ (checkBlob)';

  @override
  String get blossomNoImageYet => 'まだ画像はダウンロードされていません';

  @override
  String get blossomDownloadImage => '画像をダウンロード';

  @override
  String get blossomClearImage => '画像をクリア';

  @override
  String blossomMimeType(Object value) {
    return 'MIME タイプ: $value';
  }

  @override
  String blossomFileSizeBytes(Object value) {
    return 'サイズ: $value バイト';
  }

  @override
  String get blossomNoVideoYet => 'まだ動画は読み込まれていません';

  @override
  String get blossomLoadVideo => '動画を読み込む';

  @override
  String get blossomClearVideo => '動画をクリア';

  @override
  String blossomVideoUrl(Object value) {
    return '動画 URL: $value';
  }

  @override
  String get blossomUploadTitle => 'ディスクからファイルをアップロード';

  @override
  String get blossomUploadDescription => 'uploadFromFile() の進行状況付きアップロードを示します。';

  @override
  String blossomUploadingProgress(Object progress) {
    return 'アップロード中: $progress%';
  }

  @override
  String get blossomUploadSuccess => 'アップロード成功';

  @override
  String blossomSha256(Object value) {
    return 'SHA256: $value';
  }

  @override
  String blossomUrl(Object value) {
    return 'URL: $value';
  }

  @override
  String get blossomNoUploadedFileYet => 'まだファイルはアップロードされていません';

  @override
  String get blossomPickAndUploadFile => 'ファイルを選択してアップロード';

  @override
  String get clear => 'クリア';

  @override
  String get blossomDownloadTitle => 'ファイルをディスクにダウンロード';

  @override
  String get blossomDownloadDescription => 'downloadToFile() を示し、ディスクへ直接保存します。';

  @override
  String get blossomNoDownloadedFileYet => 'まだファイルはダウンロードされていません';

  @override
  String get blossomDownloadUploadedFile => 'アップロード済みファイルをダウンロード';

  @override
  String blossomSavedTo(Object value) {
    return '保存先: $value';
  }

  @override
  String get blossomUploadFirstToEnableDownload =>
      'ダウンロードを有効にするには先にファイルをアップロードしてください。';

  @override
  String get blossomNoUploadedFileToDownload => 'ダウンロードできるアップロード済みファイルがありません。';

  @override
  String get blossomDownloadedToBrowser => 'ブラウザにダウンロードしました';

  @override
  String get downloadSuccess => 'ダウンロード成功';

  @override
  String errorLabel(Object error) {
    return 'エラー: $error';
  }

  @override
  String get pendingRequestsLoginRequired => '保留中のリクエストを見るにはログインしてください。';

  @override
  String get pendingNoRequests => '保留中のリクエストはありません';

  @override
  String get pendingUseButtons => '上のボタンでリクエストを発生させてください。';

  @override
  String get pendingRequestCancelled => 'リクエストをキャンセルしました';

  @override
  String get pendingRequestCancelFailed => 'リクエストをキャンセルできませんでした';

  @override
  String get pendingHeading => '保留中の署名リクエスト';

  @override
  String get pendingDescription => '署名者の承認待ちリクエストです。';

  @override
  String get pendingTriggerRequests => 'リクエストを発生';

  @override
  String get signEvent => 'イベントに署名';

  @override
  String get encrypt => '暗号化';

  @override
  String get decrypt => '復号';

  @override
  String pendingSignedResult(Object value) {
    return '署名しました。ID: $value';
  }

  @override
  String pendingSignFailed(Object error) {
    return '署名に失敗しました: $error';
  }

  @override
  String get pendingEncryptFirst => '暗号文を取得するには先に暗号化してください。';

  @override
  String pendingEncryptedResult(Object value) {
    return '暗号化済み: $value';
  }

  @override
  String pendingEncryptFailed(Object error) {
    return '暗号化に失敗しました: $error';
  }

  @override
  String pendingDecryptedResult(Object value) {
    return '復号結果: $value';
  }

  @override
  String pendingDecryptFailed(Object error) {
    return '復号に失敗しました: $error';
  }

  @override
  String get pendingMethodSignEvent => 'イベントに署名';

  @override
  String get pendingMethodGetPublicKey => '公開鍵を取得';

  @override
  String get pendingMethodNip04Encrypt => 'NIP-04 で暗号化';

  @override
  String get pendingMethodNip04Decrypt => 'NIP-04 を復号';

  @override
  String get pendingMethodNip44Encrypt => 'NIP-44 で暗号化';

  @override
  String get pendingMethodNip44Decrypt => 'NIP-44 を復号';

  @override
  String get pendingMethodPing => 'Ping';

  @override
  String get pendingMethodConnect => '接続';

  @override
  String pendingSecondsAgo(int count) {
    return '$count秒前';
  }

  @override
  String pendingMinutesAgo(int count) {
    return '$count分前';
  }

  @override
  String pendingHoursAgo(int count) {
    return '$count時間前';
  }

  @override
  String pendingEventKind(Object value) {
    return 'イベント種別: $value';
  }

  @override
  String pendingContent(Object value) {
    return '内容: $value';
  }

  @override
  String pendingCounterparty(Object value) {
    return '相手先: $value...';
  }

  @override
  String pendingPlaintext(Object value) {
    return '平文: $value';
  }

  @override
  String pendingCiphertext(Object value) {
    return '暗号文: $value...';
  }

  @override
  String pendingId(Object value) {
    return 'ID: $value';
  }

  @override
  String get cancel => 'キャンセル';
}
