import 'dart:async';

import '../../entities/filter.dart';
import '../../entities/relay_request_outcome.dart';
import '../../entities/software.dart';
import '../requests/requests.dart';

class Software {
  final Requests _requests;

  Software({required Requests requests}) : _requests = requests;

  Future<SoftwareApp?> getApp({
    required SoftwareAppRef app,
    Iterable<String>? relays,
    Duration? timeout,
  }) async {
    final response = _requests.query(
      filter: Filter(
        authors: [app.publisher],
        kinds: const [softwareApplicationKind],
        dTags: [app.identifier],
        limit: 1,
      ),
      explicitRelays: relays,
      timeout: timeout,
      name: 'software-app',
    );
    final events = await response.future;
    if (events.isEmpty &&
        !response.relayOutcomes.values.any(
          (outcome) => outcome.status == RelayRequestStatus.eose,
        )) {
      throw const SoftwareDiscoveryException(
        'No relay completed software application discovery',
      );
    }
    final parsed = events
        .map(_parseApp)
        .whereType<SoftwareApp>()
        .where((candidate) => candidate.ref.identifier == app.identifier)
        .toList();
    parsed.sort((a, b) => b.event.createdAt.compareTo(a.event.createdAt));
    return parsed.firstOrNull;
  }

  Future<List<SoftwareRelease>> getReleases({
    required SoftwareAppRef app,
    String channel = 'main',
    Iterable<String>? relays,
    Duration? timeout,
  }) async {
    final response = _requests.query(
      filter: Filter(
        authors: [app.publisher],
        kinds: const [softwareReleaseKind],
        tags: {
          '#i': [app.identifier],
          '#c': [channel],
        },
      ),
      explicitRelays: relays,
      timeout: timeout,
      name: 'software-releases',
    );
    final events = await response.future;
    if (events.isEmpty &&
        !response.relayOutcomes.values.any(
          (outcome) => outcome.status == RelayRequestStatus.eose,
        )) {
      throw const SoftwareDiscoveryException(
        'No relay completed software release discovery',
      );
    }
    return _validReleases(events, app, channel);
  }

  Stream<List<SoftwareRelease>> watchReleases({
    required SoftwareAppRef app,
    String channel = 'main',
    Iterable<String>? relays,
  }) {
    final response = _requests.subscription(
      filter: Filter(
        authors: [app.publisher],
        kinds: const [softwareReleaseKind],
        tags: {
          '#i': [app.identifier],
          '#c': [channel],
        },
      ),
      explicitRelays: relays,
      cacheRead: true,
      cacheWrite: true,
      name: 'software-release-watch',
    );
    final byCoordinate = <String, SoftwareRelease>{};
    StreamSubscription<dynamic>? subscription;
    late final StreamController<List<SoftwareRelease>> controller;
    controller = StreamController<List<SoftwareRelease>>(
      onListen: () {
        subscription = response.stream.listen(
          (event) {
            final release = _parseRelease(event);
            if (release != null &&
                release.event.pubKey == app.publisher &&
                release.identifier == app.identifier &&
                release.channel == channel) {
              final coordinate =
                  '${release.identifier}:${release.version}:${release.channel}';
              final previous = byCoordinate[coordinate];
              if (previous == null ||
                  previous.event.createdAt < release.event.createdAt) {
                byCoordinate[coordinate] = release;
                final values = byCoordinate.values.toList()
                  ..sort(
                    (a, b) => b.event.createdAt.compareTo(a.event.createdAt),
                  );
                controller.add(values);
              }
            }
          },
          onError: controller.addError,
          onDone: controller.close,
        );
      },
      onCancel: () async {
        await subscription?.cancel();
        await _requests.closeSubscription(
          response.requestId,
          debugLabel: 'software release watcher cancelled',
        );
      },
    );
    return controller.stream;
  }

  Future<List<SoftwareAsset>> resolveAssets(
    SoftwareRelease release, {
    Iterable<String>? relays,
    Duration? timeout,
  }) async =>
      (await resolveAssetsForReleases(
        [release],
        relays: relays,
        timeout: timeout,
      ))[release.event.id] ??
      const [];

  /// Resolves assets for multiple releases with one relay query.
  Future<Map<String, List<SoftwareAsset>>> resolveAssetsForReleases(
    Iterable<SoftwareRelease> releases, {
    Iterable<String>? relays,
    Duration? timeout,
  }) async {
    final releaseList = releases.toList(growable: false);
    final ids = releaseList
        .expand((release) => release.assets)
        .map((asset) => asset.eventId)
        .toSet();
    if (ids.isEmpty) {
      return {for (final release in releaseList) release.event.id: const []};
    }
    final hintedRelays = releaseList
        .expand((release) => release.assets)
        .map((asset) => asset.relayHint)
        .whereType<String>();
    final explicitRelays = {...?relays, ...hintedRelays};
    final events = await _requests
        .query(
          filter: Filter(ids: ids.toList(), kinds: const [softwareAssetKind]),
          explicitRelays: explicitRelays.isEmpty ? null : explicitRelays,
          timeout: timeout,
          name: 'software-assets',
        )
        .future;
    final assetsById = <String, SoftwareAsset>{
      for (final asset in events
          .where((event) => ids.contains(event.id))
          .map(_parseAsset)
          .whereType<SoftwareAsset>())
        asset.event.id: asset,
    };
    return {
      for (final release in releaseList)
        release.event.id: release.assets
            .map((reference) => assetsById[reference.eventId])
            .whereType<SoftwareAsset>()
            .where(
              (asset) =>
                  asset.identifier == release.identifier &&
                  asset.version == release.version,
            )
            .toList(growable: false),
    };
  }

  SoftwareUpdate? selectUpdate({
    required List<SoftwareRelease> releases,
    required Map<String, List<SoftwareAsset>> assetsByReleaseId,
    required InstalledSoftware installed,
  }) {
    final candidate = selectLatestCompatible(
      releases: releases,
      assetsByReleaseId: assetsByReleaseId,
      installed: installed,
    );
    return candidate != null &&
            candidate.asset.versionCode! > installed.versionCode
        ? candidate
        : null;
  }

  SoftwareUpdate? selectLatestCompatible({
    required List<SoftwareRelease> releases,
    required Map<String, List<SoftwareAsset>> assetsByReleaseId,
    required InstalledSoftware installed,
  }) {
    final candidates = <SoftwareUpdate>[];
    for (final release in releases) {
      for (final asset in assetsByReleaseId[release.event.id] ?? const []) {
        final versionCode = asset.versionCode;
        if (asset.mimeType != androidPackageMimeType ||
            asset.url == null ||
            asset.identifier != installed.packageId ||
            versionCode == null ||
            (asset.minPlatformVersion ?? 0) > installed.platformVersion ||
            (asset.minAllowedVersionCode ?? 0) > installed.versionCode ||
            (asset.variant != null && asset.variant != installed.variant) ||
            !_supportsPlatform(asset.platforms, installed.platforms) ||
            !_hasMatchingCertificate(
              asset.certificateHashes,
              installed.certificateHashes,
            )) {
          continue;
        }
        candidates.add(SoftwareUpdate(release: release, asset: asset));
      }
    }
    candidates.sort(
      (a, b) => b.asset.versionCode!.compareTo(a.asset.versionCode!),
    );
    return candidates.firstOrNull;
  }

  bool _supportsPlatform(List<String> asset, List<String> installed) =>
      asset.isEmpty || asset.any(installed.contains);

  bool _hasMatchingCertificate(List<String> asset, List<String> installed) {
    final normalized = installed.map((value) => value.toLowerCase()).toSet();
    return asset.any((value) => normalized.contains(value.toLowerCase()));
  }

  List<SoftwareRelease> _validReleases(
    Iterable<dynamic> events,
    SoftwareAppRef app,
    String channel,
  ) {
    final releases = events
        .map((event) => _parseRelease(event))
        .whereType<SoftwareRelease>()
        .where(
          (release) =>
              release.event.pubKey == app.publisher &&
              release.identifier == app.identifier &&
              release.channel == channel,
        )
        .toList();
    releases.sort((a, b) => b.event.createdAt.compareTo(a.event.createdAt));
    return releases;
  }

  SoftwareApp? _parseApp(dynamic event) {
    try {
      return SoftwareApp.fromEvent(event);
    } on SoftwareParseException {
      return null;
    }
  }

  SoftwareRelease? _parseRelease(dynamic event) {
    try {
      return SoftwareRelease.fromEvent(event);
    } on SoftwareParseException {
      return null;
    }
  }

  SoftwareAsset? _parseAsset(dynamic event) {
    try {
      return SoftwareAsset.fromEvent(event);
    } on SoftwareParseException {
      return null;
    }
  }
}

class SoftwareDiscoveryException implements Exception {
  final String message;
  const SoftwareDiscoveryException(this.message);

  @override
  String toString() => 'SoftwareDiscoveryException: $message';
}
