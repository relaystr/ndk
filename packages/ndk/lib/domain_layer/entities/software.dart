import 'nip_01_event.dart';

const softwareApplicationKind = 32267;
const softwareReleaseKind = 30063;
const softwareAssetKind = 3063;
const androidPackageMimeType = 'application/vnd.android.package-archive';

class SoftwareParseException implements Exception {
  final String message;
  const SoftwareParseException(this.message);

  @override
  String toString() => 'SoftwareParseException: $message';
}

class SoftwareAppRef {
  final String publisher;
  final String identifier;

  const SoftwareAppRef({required this.publisher, required this.identifier});
}

String _requiredTag(Nip01Event event, String name) {
  final values = event.tags
      .where((tag) => tag.length > 1 && tag.first == name)
      .map((tag) => tag[1])
      .where((value) => value.isNotEmpty)
      .toList();
  if (values.length != 1) {
    throw SoftwareParseException(
      'kind ${event.kind} requires exactly one non-empty $name tag',
    );
  }
  return values.single;
}

String? _optionalTag(Nip01Event event, String name) {
  final values = event.tags
      .where((tag) => tag.length > 1 && tag.first == name)
      .map((tag) => tag[1])
      .where((value) => value.isNotEmpty)
      .toList();
  if (values.length > 1) {
    throw SoftwareParseException('kind ${event.kind} has duplicate $name tags');
  }
  return values.firstOrNull;
}

List<String> _tags(Nip01Event event, String name) => event.tags
    .where((tag) => tag.length > 1 && tag.first == name)
    .map((tag) => tag[1])
    .where((value) => value.isNotEmpty)
    .toList(growable: false);

String _normalizedHash(String value) =>
    value.toLowerCase().replaceAll(RegExp('[^0-9a-f]'), '');

class SoftwareApp {
  final SoftwareAppRef ref;
  final String name;
  final String description;
  final String? summary;
  final String? iconUrl;
  final List<String> imageUrls;
  final List<String> platforms;
  final Nip01Event event;

  const SoftwareApp({
    required this.ref,
    required this.name,
    required this.description,
    required this.summary,
    required this.iconUrl,
    required this.imageUrls,
    required this.platforms,
    required this.event,
  });

  factory SoftwareApp.fromEvent(Nip01Event event) {
    if (event.kind != softwareApplicationKind) {
      throw SoftwareParseException('expected kind $softwareApplicationKind');
    }
    return SoftwareApp(
      ref: SoftwareAppRef(
        publisher: event.pubKey,
        identifier: _requiredTag(event, 'd'),
      ),
      name: _requiredTag(event, 'name'),
      description: event.content,
      summary: _optionalTag(event, 'summary'),
      iconUrl: _optionalTag(event, 'icon'),
      imageUrls: _tags(event, 'image'),
      platforms: _tags(event, 'f'),
      event: event,
    );
  }
}

class SoftwareAssetRef {
  final String eventId;
  final String? relayHint;

  const SoftwareAssetRef({required this.eventId, this.relayHint});
}

class SoftwareRelease {
  final String identifier;
  final String version;
  final String channel;
  final String releaseNotes;
  final List<SoftwareAssetRef> assets;
  final Nip01Event event;

  const SoftwareRelease({
    required this.identifier,
    required this.version,
    required this.channel,
    required this.releaseNotes,
    required this.assets,
    required this.event,
  });

  factory SoftwareRelease.fromEvent(Nip01Event event) {
    if (event.kind != softwareReleaseKind) {
      throw SoftwareParseException('expected kind $softwareReleaseKind');
    }
    final identifier = _requiredTag(event, 'i');
    final version = _requiredTag(event, 'version');
    if (_requiredTag(event, 'd') != '$identifier@$version') {
      throw const SoftwareParseException('release d tag must equal i@version');
    }
    final assets = event.tags
        .where((tag) => tag.length > 1 && tag.first == 'e' && tag[1].isNotEmpty)
        .map(
          (tag) => SoftwareAssetRef(
            eventId: tag[1],
            relayHint: tag.length > 2 && tag[2].isNotEmpty ? tag[2] : null,
          ),
        )
        .toList(growable: false);
    if (assets.isEmpty) {
      throw const SoftwareParseException('release requires an asset reference');
    }
    return SoftwareRelease(
      identifier: identifier,
      version: version,
      channel: _requiredTag(event, 'c'),
      releaseNotes: event.content,
      assets: assets,
      event: event,
    );
  }
}

class SoftwareAsset {
  final String identifier;
  final String version;
  final String mimeType;
  final String sha256;
  final String? url;
  final int? size;
  final List<String> platforms;
  final int? minPlatformVersion;
  final int? versionCode;
  final int? minAllowedVersionCode;
  final List<String> certificateHashes;
  final String? variant;
  final Nip01Event event;

  const SoftwareAsset({
    required this.identifier,
    required this.version,
    required this.mimeType,
    required this.sha256,
    required this.url,
    required this.size,
    required this.platforms,
    required this.minPlatformVersion,
    required this.versionCode,
    required this.minAllowedVersionCode,
    required this.certificateHashes,
    required this.variant,
    required this.event,
  });

  factory SoftwareAsset.fromEvent(Nip01Event event) {
    if (event.kind != softwareAssetKind) {
      throw SoftwareParseException('expected kind $softwareAssetKind');
    }
    if (event.content.isNotEmpty) {
      throw const SoftwareParseException('asset content must be empty');
    }
    final mimeType = _requiredTag(event, 'm');
    final hash = _normalizedHash(_requiredTag(event, 'x'));
    if (!RegExp(r'^[0-9a-f]{64}$').hasMatch(hash)) {
      throw const SoftwareParseException('asset x tag must be a SHA-256 hash');
    }
    int? parseIntTag(String name) {
      final value = _optionalTag(event, name);
      if (value == null) return null;
      final parsed = int.tryParse(value);
      if (parsed == null || parsed < 0) {
        throw SoftwareParseException(
            'asset $name must be a non-negative integer');
      }
      return parsed;
    }

    final versionCode = parseIntTag('version_code');
    final certificates = _tags(event, 'apk_certificate_hash')
        .map(_normalizedHash)
        .toList(growable: false);
    if (mimeType == androidPackageMimeType &&
        (versionCode == null ||
            certificates.isEmpty ||
            certificates.any((hash) => hash.length != 64))) {
      throw const SoftwareParseException(
        'Android asset requires version_code and apk_certificate_hash',
      );
    }
    return SoftwareAsset(
      identifier: _requiredTag(event, 'i'),
      version: _requiredTag(event, 'version'),
      mimeType: mimeType,
      sha256: hash,
      url: _optionalTag(event, 'url'),
      size: parseIntTag('size'),
      platforms: _tags(event, 'f'),
      minPlatformVersion: parseIntTag('min_platform_version'),
      versionCode: versionCode,
      minAllowedVersionCode: parseIntTag('min_allowed_version_code'),
      certificateHashes: certificates,
      variant: _optionalTag(event, 'variant'),
      event: event,
    );
  }
}

class InstalledSoftware {
  final String packageId;
  final String version;
  final int versionCode;
  final int platformVersion;
  final List<String> platforms;
  final List<String> certificateHashes;
  final String? variant;

  const InstalledSoftware({
    required this.packageId,
    required this.version,
    required this.versionCode,
    required this.platformVersion,
    required this.platforms,
    required this.certificateHashes,
    this.variant,
  });
}

class SoftwareUpdate {
  final SoftwareRelease release;
  final SoftwareAsset asset;

  const SoftwareUpdate({required this.release, required this.asset});
}
