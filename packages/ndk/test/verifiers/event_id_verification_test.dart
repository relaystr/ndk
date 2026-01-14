import 'package:ndk/ndk.dart';
import 'package:test/test.dart';

void main() {
  test('verify real event', () async {
    final event = Nip01EventModel.fromJson({
      "id": "3c65c446bd71fa90e5c4177abf8526868dbc4b230b15ea8df3fa7ee33145993b",
      "pubkey":
          "52d4650e933525817021571f2e82859da3b5ad44e74ef6498a8af5ff8d7dcc83",
      "created_at": 1766398063,
      "kind": 1,
      "tags": [],
      "content": "content",
      "sig":
          "eff0ae7d37d9739baa920fee76792974bfc0b27219a20c728dd143d8188395abb35ff6b09acbf0049a60f5c73b0a2a154f014bc02e08902c78f07f5c422ae607"
    });

    expect(await Bip340EventVerifier().verify(event), isTrue);
  });

  test('verify event with tampered id', () async {
    final event = Nip01EventModel.fromJson({
      "id": "3c65c446bd71fa90e5c4177abf8526868dbc4b230b15ea8df3fa7ee33145aaaa",
      "pubkey":
          "52d4650e933525817021571f2e82859da3b5ad44e74ef6498a8af5ff8d7dcc83",
      "created_at": 1766398063,
      "kind": 1,
      "tags": [],
      "content": "content",
      "sig":
          "eff0ae7d37d9739baa920fee76792974bfc0b27219a20c728dd143d8188395abb35ff6b09acbf0049a60f5c73b0a2a154f014bc02e08902c78f07f5c422ae607"
    });

    expect(await Bip340EventVerifier().verify(event), isFalse);
  });

  test('verify event with tampered created at', () async {
    final event = Nip01EventModel.fromJson({
      "id": "3c65c446bd71fa90e5c4177abf8526868dbc4b230b15ea8df3fa7ee33145993b",
      "pubkey":
          "52d4650e933525817021571f2e82859da3b5ad44e74ef6498a8af5ff8d7dcc83",
      "created_at": 1766394444,
      "kind": 1,
      "tags": [],
      "content": "content",
      "sig":
          "eff0ae7d37d9739baa920fee76792974bfc0b27219a20c728dd143d8188395abb35ff6b09acbf0049a60f5c73b0a2a154f014bc02e08902c78f07f5c422ae607"
    });

    expect(await Bip340EventVerifier().verify(event), isFalse);
  });
}
