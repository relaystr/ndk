// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'sample_app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class SampleAppLocalizationsZh extends SampleAppLocalizations {
  SampleAppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appName => 'Nostr Developer Kit 示例';

  @override
  String get appBarTitle => 'NDK 示例';

  @override
  String get tabAccounts => '账户';

  @override
  String get tabProfile => '个人资料';

  @override
  String get tabRelays => '中继';

  @override
  String get tabBlossom => 'Blossom';

  @override
  String get tabWallets => '钱包';

  @override
  String get tabWidgets => '组件';

  @override
  String get profileTooltip => '个人资料';

  @override
  String get loginDialogDefaultTitle => '登录';

  @override
  String get loginDialogAddAccountTitle => '添加账户';

  @override
  String get closeTooltip => '关闭';

  @override
  String get accountsHeading => '账户';

  @override
  String get accountsDescription => '管理已登录的账户并添加新账户。';

  @override
  String get addAnotherAccount => '添加另一个账户';

  @override
  String get logIn => '登录';

  @override
  String get profileNoAccount => '当前没有已登录账户。';

  @override
  String get profileAbout => '关于';

  @override
  String profileMetadataError(Object error) {
    return '获取元数据时出错：$error';
  }

  @override
  String get relaysLoginRequired => '请先登录以查看你的中继列表。';

  @override
  String get relaysFetchButton => '获取中继列表';

  @override
  String get relayListHeading => '中继列表';

  @override
  String relayConfiguredCount(int count) {
    return '$count 个已配置的中继';
  }

  @override
  String relayConnection(Object state) {
    return '连接：$state';
  }

  @override
  String get relayRead => '读取';

  @override
  String get relayWrite => '写入';

  @override
  String get relayStateConnecting => '连接中';

  @override
  String get relayStateOnline => '在线';

  @override
  String get relayStateOffline => '离线';

  @override
  String get relayStateUnknown => '未知';

  @override
  String get widgetsPageTitle => 'NDK Flutter 组件示例';

  @override
  String get widgetsLoginHint => '请从“账户”标签登录以查看个性化组件。';

  @override
  String get widgetsCurrentUser => '当前用户：';

  @override
  String get widgetsSizeDefault => '默认';

  @override
  String get widgetsSizeLarger => '更大';

  @override
  String get widgetsSizeLarge => '大';

  @override
  String get widgetsShowLoginWidget => '显示 NLogin 组件';

  @override
  String get widgetsLoginWidgetTitle => 'NLogin 组件';

  @override
  String widgetsRequiresLogin(Object widgetName) {
    return '$widgetName\\n(需要登录)';
  }

  @override
  String get widgetsSectionNNameDescription => '显示元数据中的用户名，缺失时回退为格式化的 npub。';

  @override
  String get widgetsSectionNPictureDescription => '显示用户头像，缺失时回退为首字母。';

  @override
  String get widgetsSectionNBannerDescription => '显示用户横幅图，缺失时回退为彩色容器。';

  @override
  String get widgetsSectionNUserProfileDescription =>
      '完整的用户资料组件，包含横幅、头像、名称和 NIP-05。';

  @override
  String get widgetsSectionNSwitchAccountDescription => '带账户切换和登出的账户管理组件。';

  @override
  String get widgetsSectionNLoginDescription =>
      '支持多种认证方式的登录组件（NIP-05、npub、nsec、bunker 等）。';

  @override
  String get widgetsSectionGetColorDescription => '根据 pubkey 生成确定性颜色的静态方法。';

  @override
  String get blossomPageTitle => 'Blossom 媒体与文件操作';

  @override
  String get blossomImageDemoTitle => '图片示例（getBlob）';

  @override
  String get blossomVideoDemoTitle => '视频示例（checkBlob）';

  @override
  String get blossomNoImageYet => '尚未下载图片';

  @override
  String get blossomDownloadImage => '下载图片';

  @override
  String get blossomClearImage => '清除图片';

  @override
  String blossomMimeType(Object value) {
    return 'MIME 类型：$value';
  }

  @override
  String blossomFileSizeBytes(Object value) {
    return '大小：$value 字节';
  }

  @override
  String get blossomNoVideoYet => '尚未加载视频';

  @override
  String get blossomLoadVideo => '加载视频';

  @override
  String get blossomClearVideo => '清除视频';

  @override
  String blossomVideoUrl(Object value) {
    return '视频 URL：$value';
  }

  @override
  String get blossomUploadTitle => '从磁盘上传文件';

  @override
  String get blossomUploadDescription => '演示带流式进度的 uploadFromFile()。';

  @override
  String blossomUploadingProgress(Object progress) {
    return '上传中：$progress%';
  }

  @override
  String get blossomUploadSuccess => '上传成功';

  @override
  String blossomSha256(Object value) {
    return 'SHA256：$value';
  }

  @override
  String blossomUrl(Object value) {
    return 'URL：$value';
  }

  @override
  String get blossomNoUploadedFileYet => '尚未上传文件';

  @override
  String get blossomPickAndUploadFile => '选择并上传文件';

  @override
  String get clear => '清除';

  @override
  String get blossomDownloadTitle => '将文件下载到磁盘';

  @override
  String get blossomDownloadDescription => '演示 downloadToFile() 并将文件直接保存到磁盘。';

  @override
  String get blossomNoDownloadedFileYet => '尚未下载文件';

  @override
  String get blossomDownloadUploadedFile => '下载已上传文件';

  @override
  String blossomSavedTo(Object value) {
    return '已保存到：$value';
  }

  @override
  String get blossomUploadFirstToEnableDownload => '请先上传文件以启用下载。';

  @override
  String get blossomNoUploadedFileToDownload => '当前没有可下载的已上传文件。';

  @override
  String get blossomDownloadedToBrowser => '已下载到浏览器';

  @override
  String get downloadSuccess => '下载成功';

  @override
  String errorLabel(Object error) {
    return '错误：$error';
  }

  @override
  String get pendingRequestsLoginRequired => '请先登录以查看待处理请求。';

  @override
  String get pendingNoRequests => '没有待处理请求';

  @override
  String get pendingUseButtons => '使用上方按钮来触发请求。';

  @override
  String get pendingRequestCancelled => '请求已取消';

  @override
  String get pendingRequestCancelFailed => '取消请求失败';

  @override
  String get pendingHeading => '待处理的签名器请求';

  @override
  String get pendingDescription => '等待你的签名器批准的请求。';

  @override
  String get pendingTriggerRequests => '触发请求';

  @override
  String get signEvent => '签名事件';

  @override
  String get encrypt => '加密';

  @override
  String get decrypt => '解密';

  @override
  String pendingSignedResult(Object value) {
    return '已签名，ID：$value';
  }

  @override
  String pendingSignFailed(Object error) {
    return '签名失败：$error';
  }

  @override
  String get pendingEncryptFirst => '请先加密以获取密文。';

  @override
  String pendingEncryptedResult(Object value) {
    return '已加密：$value';
  }

  @override
  String pendingEncryptFailed(Object error) {
    return '加密失败：$error';
  }

  @override
  String pendingDecryptedResult(Object value) {
    return '已解密：$value';
  }

  @override
  String pendingDecryptFailed(Object error) {
    return '解密失败：$error';
  }

  @override
  String get pendingMethodSignEvent => '签名事件';

  @override
  String get pendingMethodGetPublicKey => '获取公钥';

  @override
  String get pendingMethodNip04Encrypt => 'NIP-04 加密';

  @override
  String get pendingMethodNip04Decrypt => 'NIP-04 解密';

  @override
  String get pendingMethodNip44Encrypt => 'NIP-44 加密';

  @override
  String get pendingMethodNip44Decrypt => 'NIP-44 解密';

  @override
  String get pendingMethodPing => 'Ping';

  @override
  String get pendingMethodConnect => '连接';

  @override
  String pendingSecondsAgo(int count) {
    return '$count秒前';
  }

  @override
  String pendingMinutesAgo(int count) {
    return '$count分钟前';
  }

  @override
  String pendingHoursAgo(int count) {
    return '$count小时前';
  }

  @override
  String pendingEventKind(Object value) {
    return '事件类型：$value';
  }

  @override
  String pendingContent(Object value) {
    return '内容：$value';
  }

  @override
  String pendingCounterparty(Object value) {
    return '对方：$value...';
  }

  @override
  String pendingPlaintext(Object value) {
    return '明文：$value';
  }

  @override
  String pendingCiphertext(Object value) {
    return '密文：$value...';
  }

  @override
  String pendingId(Object value) {
    return 'ID：$value';
  }

  @override
  String get cancel => '取消';
}
