import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ndk/ndk.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../main/ndk_flutter.dart';
import 'update_installer.dart';

enum NAppUpdateStatus {
  idle,
  checking,
  upToDate,
  aheadOfPublished,
  available,
  downloading,
  verifying,
  permissionRequired,
  awaitingUserAction,
  installing,
  installed,
  cancelled,
  failed,
}

@immutable
class NAppUpdateState {
  final NAppUpdateStatus status;
  final InstalledSoftware? installed;
  final SoftwareUpdate? update;
  final SoftwareRelease? currentRelease;
  final SoftwareRelease? latestRelease;
  final SoftwareRelease? justUpdatedRelease;
  final List<SoftwareRelease> releases;
  final Map<String, List<SoftwareAsset>> assetsByReleaseId;
  final double? progress;
  final DateTime? lastChecked;
  final String? error;

  const NAppUpdateState({
    this.status = NAppUpdateStatus.idle,
    this.installed,
    this.update,
    this.currentRelease,
    this.latestRelease,
    this.justUpdatedRelease,
    this.releases = const [],
    this.assetsByReleaseId = const {},
    this.progress,
    this.lastChecked,
    this.error,
  });

  NAppUpdateState copyWith({
    NAppUpdateStatus? status,
    InstalledSoftware? installed,
    SoftwareUpdate? update,
    SoftwareRelease? currentRelease,
    SoftwareRelease? latestRelease,
    SoftwareRelease? justUpdatedRelease,
    List<SoftwareRelease>? releases,
    Map<String, List<SoftwareAsset>>? assetsByReleaseId,
    bool clearJustUpdatedRelease = false,
    double? progress,
    bool clearProgress = false,
    DateTime? lastChecked,
    String? error,
    bool clearError = false,
  }) => NAppUpdateState(
    status: status ?? this.status,
    installed: installed ?? this.installed,
    update: update ?? this.update,
    currentRelease: currentRelease ?? this.currentRelease,
    latestRelease: latestRelease ?? this.latestRelease,
    justUpdatedRelease: clearJustUpdatedRelease
        ? null
        : justUpdatedRelease ?? this.justUpdatedRelease,
    releases: releases ?? this.releases,
    assetsByReleaseId: assetsByReleaseId ?? this.assetsByReleaseId,
    progress: clearProgress ? null : progress ?? this.progress,
    lastChecked: lastChecked ?? this.lastChecked,
    error: clearError ? null : error ?? this.error,
  );
}

class NAppUpdateController extends ChangeNotifier with WidgetsBindingObserver {
  final NdkFlutter ndkFlutter;
  final SoftwareAppRef app;
  final SoftwareAppRef? zapTargetApp;
  final String channel;
  final List<String> relays;
  final UpdateInstaller installer;
  final String? currentVersion;
  final Uri? externalUpdateUrl;
  final bool installationEnabled;
  final Duration queryTimeout;
  final Duration engagementQueryTimeout;
  final Duration engagementMetadataTimeout;

  NAppUpdateState _state = const NAppUpdateState();
  NAppUpdateState get state => _state;

  StreamSubscription<List<SoftwareRelease>>? _releaseSubscription;
  StreamSubscription<double>? _progressSubscription;
  bool _started = false;
  bool _disposed = false;
  bool _persistentReleaseWatch = false;
  int _releaseWatchers = 0;
  bool _checking = false;
  Completer<void>? _checkCompleter;
  bool _installOperationActive = false;
  int _evaluationGeneration = 0;
  int? _previousInstalledVersionCode;
  NAppUpdateController({
    required this.ndkFlutter,
    required this.app,
    required this.installer,
    this.currentVersion,
    this.externalUpdateUrl,
    bool? installationEnabled,
    this.zapTargetApp,
    this.channel = 'main',
    this.relays = const [],
    this.queryTimeout = const Duration(seconds: 5),
    this.engagementQueryTimeout = const Duration(seconds: 4),
    this.engagementMetadataTimeout = const Duration(seconds: 3),
  }) : installationEnabled =
           installationEnabled ??
           (!kIsWeb && defaultTargetPlatform == TargetPlatform.android);

  factory NAppUpdateController.self({
    required NdkFlutter ndkFlutter,
    required SoftwareAppRef app,
    SoftwareAppRef? zapTargetApp,
    String? currentVersion,
    Uri? externalUpdateUrl,
    bool? installationEnabled,
    String channel = 'main',
    List<String> relays = const [],
    UpdateInstaller? installer,
    Duration queryTimeout = const Duration(seconds: 5),
    Duration engagementQueryTimeout = const Duration(seconds: 4),
    Duration engagementMetadataTimeout = const Duration(seconds: 3),
  }) => NAppUpdateController(
    ndkFlutter: ndkFlutter,
    app: app,
    zapTargetApp: zapTargetApp,
    currentVersion: currentVersion,
    externalUpdateUrl: externalUpdateUrl,
    installationEnabled: installationEnabled,
    channel: channel,
    relays: relays,
    installer: installer ?? AndroidPackageInstaller(),
    queryTimeout: queryTimeout,
    engagementQueryTimeout: engagementQueryTimeout,
    engagementMetadataTimeout: engagementMetadataTimeout,
  );

  Future<void> start({bool watchReleases = false}) async {
    if (_disposed) return;
    if (_started) {
      if (watchReleases) {
        _persistentReleaseWatch = true;
        _ensureReleaseSubscription();
      }
      return;
    }
    _started = true;
    _persistentReleaseWatch = watchReleases;
    WidgetsBinding.instance.addObserver(this);
    if (installationEnabled) await _restoreInstalledVersion();
    if (_disposed) return;
    _progressSubscription = installer.progress.listen((progress) {
      if (!_installOperationActive) return;
      _setState(
        _state.copyWith(
          status: progress >= 1
              ? NAppUpdateStatus.verifying
              : NAppUpdateStatus.downloading,
          progress: progress,
        ),
      );
    });
    await checkNow();
    if (_persistentReleaseWatch || _releaseWatchers > 0) {
      _ensureReleaseSubscription();
    }
  }

  Future<void> acquireReleaseWatch() async {
    if (_disposed) return;
    _releaseWatchers++;
    await start();
    if (_releaseWatchers > 0) _ensureReleaseSubscription();
  }

  Future<void> releaseReleaseWatch() async {
    if (_releaseWatchers > 0) _releaseWatchers--;
    if (_releaseWatchers == 0 && !_persistentReleaseWatch) {
      await _releaseSubscription?.cancel();
      _releaseSubscription = null;
    }
  }

  void _ensureReleaseSubscription() {
    if (_disposed || _releaseSubscription != null) return;
    _releaseSubscription = ndkFlutter.ndk.software
        .watchReleases(app: app, channel: channel, relays: relays)
        .listen(
          _evaluate,
          onError: (Object error) {
            _releaseSubscription = null;
            _fail(error);
          },
          onDone: () => _releaseSubscription = null,
          cancelOnError: true,
        );
  }

  Future<void> checkNow({bool allowDuringInstaller = false}) async {
    if (_disposed) return;
    if (_checking) {
      await _checkCompleter?.future;
      return;
    }
    if (_preservesInstallerState && !allowDuringInstaller) {
      return;
    }
    final completer = Completer<void>();
    _checkCompleter = completer;
    final totalTimer = Stopwatch()..start();
    _checking = true;
    _setState(
      _state.copyWith(
        status: NAppUpdateStatus.checking,
        clearError: true,
        clearProgress: true,
      ),
    );
    try {
      if (installationEnabled) {
        final installedTimer = Stopwatch()..start();
        final installed = await installer.getInstalledSoftware();
        if (_disposed) return;
        _logTiming('installed-package', installedTimer);
        _setState(_state.copyWith(installed: installed));
      }
      final releasesTimer = Stopwatch()..start();
      final releases = await ndkFlutter.ndk.software.getReleases(
        app: app,
        channel: channel,
        relays: relays,
        timeout: queryTimeout,
      );
      _logTiming('releases', releasesTimer);
      await _evaluate(releases);
    } catch (error) {
      _fail(error);
    } finally {
      _checking = false;
      if (!completer.isCompleted) completer.complete();
      if (identical(_checkCompleter, completer)) _checkCompleter = null;
      _logTiming('check-total', totalTimer);
    }
  }

  Future<void> _evaluate(List<SoftwareRelease> releases) async {
    if (_disposed || _preservesInstallerState) return;
    final generation = ++_evaluationGeneration;
    try {
      if (!installationEnabled) {
        SoftwareRelease? release;
        for (final candidate in releases) {
          if (candidate.version == currentVersion) {
            release = candidate;
            break;
          }
        }
        release ??= releases.firstOrNull;
        if (!_canCommitEvaluation(generation)) return;
        _setState(
          NAppUpdateState(
            status: NAppUpdateStatus.upToDate,
            currentRelease: release,
            latestRelease: releases.firstOrNull,
            releases: List.unmodifiable(releases),
            lastChecked: DateTime.now(),
          ),
        );
        return;
      }
      final installed =
          _state.installed ?? await installer.getInstalledSoftware();
      if (_disposed) return;
      final previousUpdate = _state.update;
      if (previousUpdate != null &&
          installed.packageId == previousUpdate.asset.identifier &&
          installed.versionCode >= previousUpdate.asset.versionCode!) {
        if (!_canCommitEvaluation(generation)) return;
        final justUpdated =
            _previousInstalledVersionCode != null &&
            installed.versionCode > _previousInstalledVersionCode!;
        if (_previousInstalledVersionCode == null) {
          await _rememberInstalledVersion(installed.versionCode);
        }
        _setState(
          NAppUpdateState(
            status: NAppUpdateStatus.installed,
            installed: installed,
            currentRelease: previousUpdate.release,
            latestRelease: releases.firstOrNull,
            justUpdatedRelease: justUpdated ? previousUpdate.release : null,
            releases: List.unmodifiable(releases),
            assetsByReleaseId: _state.assetsByReleaseId,
            lastChecked: DateTime.now(),
          ),
        );
        return;
      }
      final assets = <String, List<SoftwareAsset>>{};
      final releasesWithAssets = <SoftwareRelease>[];
      final assetsTimer = Stopwatch()..start();
      final resolvedByRelease = await _resolveAssets(releases, installed);
      _logTiming('assets', assetsTimer);
      for (final release in releases) {
        final resolved = resolvedByRelease[release.event.id];
        if (resolved != null) {
          assets[release.event.id] = resolved;
          releasesWithAssets.add(release);
        }
      }
      final latestCompatible = ndkFlutter.ndk.software.selectLatestCompatible(
        releases: releasesWithAssets,
        assetsByReleaseId: assets,
        installed: installed,
      );
      final update =
          latestCompatible != null &&
              latestCompatible.asset.versionCode! > installed.versionCode
          ? latestCompatible
          : null;
      SoftwareRelease? currentRelease;
      for (final release in releases) {
        if (release.version == installed.version) {
          currentRelease = release;
          break;
        }
      }
      final checked = DateTime.now();
      final justUpdated =
          _previousInstalledVersionCode != null &&
          installed.versionCode > _previousInstalledVersionCode!;
      if (_previousInstalledVersionCode == null) {
        await _rememberInstalledVersion(installed.versionCode);
      }
      if (!_canCommitEvaluation(generation)) return;
      final aheadOfPublished =
          currentRelease == null &&
          latestCompatible != null &&
          installed.versionCode > latestCompatible.asset.versionCode!;
      _setState(
        NAppUpdateState(
          status: update == null
              ? aheadOfPublished
                    ? NAppUpdateStatus.aheadOfPublished
                    : NAppUpdateStatus.upToDate
              : NAppUpdateStatus.available,
          installed: installed,
          update: update,
          currentRelease: currentRelease,
          latestRelease: latestCompatible?.release,
          justUpdatedRelease: justUpdated ? currentRelease : null,
          releases: List.unmodifiable(releases),
          assetsByReleaseId: Map.unmodifiable({
            for (final entry in assets.entries)
              entry.key: List<SoftwareAsset>.unmodifiable(entry.value),
          }),
          lastChecked: checked,
        ),
      );
    } catch (error) {
      if (_canCommitEvaluation(generation)) _fail(error);
    }
  }

  bool get _preservesInstallerState =>
      _installOperationActive ||
      _state.status == NAppUpdateStatus.awaitingUserAction ||
      _state.status == NAppUpdateStatus.installing;

  bool get hasExternalUpdate {
    if (installationEnabled ||
        externalUpdateUrl == null ||
        currentVersion == null) {
      return false;
    }
    final currentIndex = _state.releases.indexWhere(
      (release) => release.version == currentVersion,
    );
    return currentIndex > 0;
  }

  Future<void> openExternalUpdate() async {
    final url = externalUpdateUrl;
    if (!hasExternalUpdate || url == null) return;
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      _fail(StateError('Could not open update URL: $url'));
    }
  }

  SoftwareAsset? assetForRelease(SoftwareRelease release) {
    final installed = _state.installed;
    if (installed == null) return null;
    return ndkFlutter.ndk.software
        .selectLatestCompatible(
          releases: [release],
          assetsByReleaseId: _state.assetsByReleaseId,
          installed: installed,
        )
        ?.asset;
  }

  bool _canCommitEvaluation(int generation) =>
      !_disposed &&
      generation == _evaluationGeneration &&
      !_preservesInstallerState;

  Future<Map<String, List<SoftwareAsset>>> _resolveAssets(
    List<SoftwareRelease> releases,
    InstalledSoftware installed,
  ) async {
    final resolved = <String, List<SoftwareAsset>>{};
    var unresolved = releases;
    for (var attempt = 0; attempt < 3; attempt++) {
      final batch = await ndkFlutter.ndk.software.resolveAssetsForReleases(
        unresolved,
        relays: relays,
        timeout: queryTimeout,
      );
      for (final release in unresolved) {
        final assets = batch[release.event.id] ?? const <SoftwareAsset>[];
        if (assets.isNotEmpty) {
          resolved[release.event.id] = {
            for (final asset in [...?resolved[release.event.id], ...assets])
              asset.event.id: asset,
          }.values.toList(growable: false);
        }
      }
      unresolved = unresolved
          .where((release) {
            final assets = resolved[release.event.id] ?? const [];
            final resolvedIds = assets.map((asset) => asset.event.id).toSet();
            final allReferencesResolved = release.assets.every(
              (reference) => resolvedIds.contains(reference.eventId),
            );
            final hasCompatibleAsset =
                ndkFlutter.ndk.software.selectLatestCompatible(
                  releases: [release],
                  assetsByReleaseId: resolved,
                  installed: installed,
                ) !=
                null;
            return !allReferencesResolved && !hasCompatibleAsset;
          })
          .toList(growable: false);
      final update = ndkFlutter.ndk.software.selectUpdate(
        releases: releases,
        assetsByReleaseId: resolved,
        installed: installed,
      );
      if (update != null || unresolved.isEmpty || attempt == 2) {
        return resolved;
      }
      await Future<void>.delayed(Duration(seconds: attempt + 1));
    }
    return resolved;
  }

  void _logTiming(String stage, Stopwatch timer) {
    timer.stop();
    Logger.log.d(
      () =>
          'app-update $stage ${timer.elapsedMilliseconds}ms '
          '(${app.identifier})',
    );
  }

  Future<void> downloadAndInstall() async {
    final update = _state.update;
    if (!installationEnabled ||
        update == null ||
        _installOperationActive ||
        _preservesInstallerState) {
      return;
    }
    _installOperationActive = true;
    _evaluationGeneration++;
    _setState(
      _state.copyWith(
        status: NAppUpdateStatus.downloading,
        clearProgress: true,
        clearError: true,
      ),
    );
    try {
      final result = await installer.downloadAndInstall(update.asset);
      _setState(
        _state.copyWith(
          status: switch (result) {
            UpdateInstallResult.permissionRequired =>
              NAppUpdateStatus.permissionRequired,
            UpdateInstallResult.awaitingUserAction =>
              NAppUpdateStatus.awaitingUserAction,
            UpdateInstallResult.cancelled => NAppUpdateStatus.cancelled,
          },
          clearProgress: true,
        ),
      );
    } catch (error) {
      _fail(error);
    } finally {
      _installOperationActive = false;
    }
  }

  Future<void> cancelDownload() async {
    await installer.cancelDownload();
    _setState(
      _state.copyWith(status: NAppUpdateStatus.cancelled, clearProgress: true),
    );
  }

  Future<void> dismiss() async {
    if (_state.update == null) return;
    _setState(_state.copyWith(status: NAppUpdateStatus.cancelled));
  }

  String get _installedVersionKey =>
      'ndk-update-installed:${app.publisher}:${app.identifier}:$channel';

  Future<void> _restoreInstalledVersion() async {
    final preferences = await SharedPreferences.getInstance();
    _previousInstalledVersionCode = preferences.getInt(_installedVersionKey);
  }

  Future<void> _rememberInstalledVersion(int versionCode) async {
    _previousInstalledVersionCode = versionCode;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setInt(_installedVersionKey, versionCode);
  }

  Future<void> acknowledgeInstalledRelease() async {
    final installed = _state.installed;
    if (installed == null || _state.justUpdatedRelease == null) return;
    await _rememberInstalledVersion(installed.versionCode);
    _setState(_state.copyWith(clearJustUpdatedRelease: true));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _started) {
      checkNow(allowDuringInstaller: true);
    }
  }

  void _fail(Object error) {
    _setState(
      _state.copyWith(
        status: NAppUpdateStatus.failed,
        error: error.toString(),
        clearProgress: true,
      ),
    );
  }

  void _setState(NAppUpdateState value) {
    if (_disposed) return;
    _state = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _evaluationGeneration++;
    WidgetsBinding.instance.removeObserver(this);
    _releaseSubscription?.cancel();
    _progressSubscription?.cancel();
    installer.dispose();
    super.dispose();
  }
}
