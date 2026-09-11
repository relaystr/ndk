import 'dart:async';

import 'package:flutter/services.dart';
import 'package:ndk/ndk.dart';

enum UpdateInstallResult { permissionRequired, awaitingUserAction, cancelled }

abstract class UpdateInstaller {
  Stream<double> get progress;

  Future<InstalledSoftware> getInstalledSoftware();

  Future<UpdateInstallResult> downloadAndInstall(SoftwareAsset asset);

  Future<void> cancelDownload() async {}

  void dispose() {}
}

class AndroidPackageInstaller extends UpdateInstaller {
  static const MethodChannel _channel = MethodChannel('ndk/app_updates');
  static final AndroidPackageInstaller _instance = AndroidPackageInstaller._();
  final StreamController<double> _progress = StreamController.broadcast();

  factory AndroidPackageInstaller() => _instance;

  AndroidPackageInstaller._() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'progress') {
        final value = (call.arguments as num?)?.toDouble();
        if (value != null && !_progress.isClosed) _progress.add(value);
      }
    });
  }

  @override
  Stream<double> get progress => _progress.stream;

  @override
  Future<InstalledSoftware> getInstalledSoftware() async {
    final result = await _channel.invokeMapMethod<String, dynamic>(
      'getInstalledSoftware',
    );
    if (result == null) {
      throw UnsupportedError('Android package information is unavailable');
    }
    return InstalledSoftware(
      packageId: result['packageId'] as String,
      version: result['version'] as String,
      versionCode: result['versionCode'] as int,
      platformVersion: result['platformVersion'] as int,
      platforms: (result['platforms'] as List).cast<String>(),
      certificateHashes: (result['certificateHashes'] as List).cast<String>(),
    );
  }

  @override
  Future<UpdateInstallResult> downloadAndInstall(SoftwareAsset asset) async {
    final url = asset.url;
    if (url == null) {
      throw StateError('Android update asset has no download URL');
    }
    final result = await _channel.invokeMethod<String>('downloadAndInstall', {
      'url': url,
      'sha256': asset.sha256,
      'packageId': asset.identifier,
      'versionCode': asset.versionCode,
      'size': asset.size,
      'certificateHashes': asset.certificateHashes,
    });
    return switch (result) {
      'permissionRequired' => UpdateInstallResult.permissionRequired,
      'awaitingUserAction' => UpdateInstallResult.awaitingUserAction,
      'cancelled' => UpdateInstallResult.cancelled,
      _ => throw StateError('Unexpected Android installer result: $result'),
    };
  }

  @override
  Future<void> cancelDownload() =>
      _channel.invokeMethod<void>('cancelDownload');

  // Process-wide singleton owns the process-wide MethodChannel.
  @override
  void dispose() {}
}
