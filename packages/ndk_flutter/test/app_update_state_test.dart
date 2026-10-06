import 'package:flutter_test/flutter_test.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk_flutter/ndk_flutter.dart';

SoftwareRelease _release(String version, int createdAt) => SoftwareRelease(
  identifier: 'example.app',
  version: version,
  channel: 'main',
  releaseNotes: 'Changes in $version',
  assets: const [SoftwareAssetRef(eventId: 'asset')],
  event: Nip01Event(
    id: 'release-$version',
    pubKey: 'publisher',
    kind: softwareReleaseKind,
    tags: const [],
    content: '',
    createdAt: createdAt,
  ),
);

void main() {
  test('update state retains discovered releases across status changes', () {
    final releases = [_release('2.0.0', 2), _release('1.0.0', 1)];
    final assetsByReleaseId = <String, List<SoftwareAsset>>{
      releases.first.event.id: const [],
    };
    final state = NAppUpdateState(
      releases: releases,
      assetsByReleaseId: assetsByReleaseId,
    );

    final checking = state.copyWith(status: NAppUpdateStatus.checking);

    expect(checking.releases, same(releases));
    expect(checking.assetsByReleaseId, same(assetsByReleaseId));
    expect(checking.releases.map((release) => release.version), [
      '2.0.0',
      '1.0.0',
    ]);
  });
}
