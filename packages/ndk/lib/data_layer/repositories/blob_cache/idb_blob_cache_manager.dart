import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:idb_shim/idb.dart';

import '../../../domain_layer/entities/blossom_blobs.dart';
import '../../../domain_layer/repositories/blob_cache_manager.dart';

const String _kDataStore = 'blob_data';
const String _kMetadataStore = 'blob_metadata';
const int _kSchemaVersion = 1;

/// IndexedDB-backed [BlobCacheManager], usable on web (real IndexedDB),
/// native (idb_io / idb_sqflite) and in tests (`newMemoryIdbFactory()`).
///
/// The concrete [IdbFactory] is injected so this class stays
/// platform-agnostic; callers pick the right one for their platform.
class IdbBlobCacheManager implements BlobCacheManager {
  final IdbFactory _factory;
  final String _dbName;
  Future<Database>? _dbFuture;

  IdbBlobCacheManager({
    required IdbFactory factory,
    String dbName = 'ndk_blob_cache',
  })  : _factory = factory,
        _dbName = dbName;

  Future<Database> _db() {
    return _dbFuture ??= _factory.open(
      _dbName,
      version: _kSchemaVersion,
      onUpgradeNeeded: (VersionChangeEvent e) {
        final db = e.database;
        if (!db.objectStoreNames.contains(_kDataStore)) {
          db.createObjectStore(_kDataStore);
        }
        if (!db.objectStoreNames.contains(_kMetadataStore)) {
          db.createObjectStore(_kMetadataStore);
        }
      },
    );
  }

  @override
  Future<BlobDescriptor> saveBlob({
    required Uint8List data,
    String? sha256,
    String? mimeType,
    String? sourceUrl,
    BlobNip94? nip94,
  }) async {
    final hash = sha256 ?? crypto.sha256.convert(data).toString();
    final descriptor = BlobDescriptor(
      url: sourceUrl ?? '',
      sha256: hash,
      size: data.length,
      type: mimeType,
      uploaded: DateTime.now(),
      nip94: nip94,
    );

    final db = await _db();
    final txn = db.transaction(
      [_kDataStore, _kMetadataStore],
      idbModeReadWrite,
    );
    try {
      await txn.objectStore(_kDataStore).put(data, hash);
      await txn.objectStore(_kMetadataStore).put(descriptor.toJson(), hash);
    } finally {
      await txn.completed;
    }
    return descriptor;
  }

  @override
  Future<BlobResponse?> getBlob(String sha256) async {
    final db = await _db();
    final txn = db.transaction(
      [_kDataStore, _kMetadataStore],
      idbModeReadOnly,
    );
    Object? bytes;
    Object? meta;
    try {
      bytes = await txn.objectStore(_kDataStore).getObject(sha256);
      meta = await txn.objectStore(_kMetadataStore).getObject(sha256);
    } finally {
      await txn.completed;
    }
    if (bytes == null) return null;
    final data = _asUint8List(bytes);
    final descriptor = meta is Map
        ? BlobDescriptor.fromJson(Map<String, dynamic>.from(meta))
        : null;
    return BlobResponse(
      data: data,
      mimeType: descriptor?.type,
      contentLength: data.length,
    );
  }

  @override
  Future<bool> hasBlob(String sha256) async {
    final db = await _db();
    final txn = db.transaction(_kMetadataStore, idbModeReadOnly);
    Object? key;
    try {
      key = await txn.objectStore(_kMetadataStore).getKey(sha256);
    } finally {
      await txn.completed;
    }
    return key != null;
  }

  @override
  Future<BlobDescriptor?> getBlobDescriptor(String sha256) async {
    final db = await _db();
    final txn = db.transaction(_kMetadataStore, idbModeReadOnly);
    Object? meta;
    try {
      meta = await txn.objectStore(_kMetadataStore).getObject(sha256);
    } finally {
      await txn.completed;
    }
    if (meta is! Map) return null;
    return BlobDescriptor.fromJson(Map<String, dynamic>.from(meta));
  }

  @override
  Future<List<BlobDescriptor>> listBlobs() async {
    final db = await _db();
    final txn = db.transaction(_kMetadataStore, idbModeReadOnly);
    List<Object?> values;
    try {
      values = await txn.objectStore(_kMetadataStore).getAll();
    } finally {
      await txn.completed;
    }
    final descriptors = <BlobDescriptor>[];
    for (final v in values) {
      if (v is Map) {
        descriptors.add(BlobDescriptor.fromJson(Map<String, dynamic>.from(v)));
      }
    }
    descriptors.sort((a, b) => b.uploaded.compareTo(a.uploaded));
    return descriptors;
  }

  @override
  Future<void> removeBlob(String sha256) async {
    final db = await _db();
    final txn = db.transaction(
      [_kDataStore, _kMetadataStore],
      idbModeReadWrite,
    );
    try {
      await txn.objectStore(_kDataStore).delete(sha256);
      await txn.objectStore(_kMetadataStore).delete(sha256);
    } finally {
      await txn.completed;
    }
  }

  @override
  Future<void> removeAllBlobs() async {
    final db = await _db();
    final txn = db.transaction(
      [_kDataStore, _kMetadataStore],
      idbModeReadWrite,
    );
    try {
      await txn.objectStore(_kDataStore).clear();
      await txn.objectStore(_kMetadataStore).clear();
    } finally {
      await txn.completed;
    }
  }

  @override
  Future<int> getTotalSize() async {
    // Sum the `size` field from descriptors instead of loading payloads.
    final db = await _db();
    final txn = db.transaction(_kMetadataStore, idbModeReadOnly);
    List<Object?> values;
    try {
      values = await txn.objectStore(_kMetadataStore).getAll();
    } finally {
      await txn.completed;
    }
    var total = 0;
    for (final v in values) {
      if (v is Map) {
        final size = v['size'];
        if (size is int) total += size;
      }
    }
    return total;
  }

  @override
  Future<void> close() async {
    final f = _dbFuture;
    if (f != null) {
      _dbFuture = null;
      final db = await f;
      db.close();
    }
  }

  /// Some [IdbFactory] implementations return `List<int>` instead of a
  /// proper [Uint8List]. Normalise so callers always get a [Uint8List].
  Uint8List _asUint8List(Object value) {
    if (value is Uint8List) return value;
    if (value is List<int>) return Uint8List.fromList(value);
    throw StateError(
      'Unexpected blob payload type: ${value.runtimeType}',
    );
  }
}
