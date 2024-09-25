import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/mockito.dart';
import 'package:ndk/shared/nips/nip05/nip05.dart';
import 'nip05_test.mocks.dart';
import 'nip05_test.mocks.mocks.dart';

void main() {
  group('Nip05.needsUpdate', () {
    test('returns true when updatedAt is older than the given duration', () {
      // Create a Nip05 object with an old updatedAt timestamp
      final oldTimestamp =
          (DateTime.now().subtract(Duration(days: 10)).millisecondsSinceEpoch ~/
              1000);
      final nip05 = Nip05(
          pubKey: 'test_pubkey',
          nip05: 'test_nip05',
          valid: true,
          updatedAt: oldTimestamp);

      // Test with a duration of 5 days
      final result = nip05.needsUpdate(Duration(days: 5));
      expect(result,
          true); // Should return true since the object is older than 5 days
    });

    test('returns false when updatedAt is more recent than the given duration',
        () {
      // Create a Nip05 object with a recent updatedAt timestamp
      final recentTimestamp =
          (DateTime.now().subtract(Duration(days: 2)).millisecondsSinceEpoch ~/
              1000);
      final nip05 = Nip05(
          pubKey: 'test_pubkey',
          nip05: 'test_nip05',
          valid: true,
          updatedAt: recentTimestamp);

      // Test with a duration of 5 days
      final result = nip05.needsUpdate(Duration(days: 5));
      expect(result,
          false); // Should return false since the object is more recent than 5 days
    });

    test('returns false when updatedAt is exactly the duration ago', () {
      // Create a Nip05 object with an updatedAt timestamp exactly equal to the duration
      final exactTimestamp =
          (DateTime.now().subtract(Duration(days: 5)).millisecondsSinceEpoch ~/
              1000);
      final nip05 = Nip05(
          pubKey: 'test_pubkey',
          nip05: 'test_nip05',
          valid: true,
          updatedAt: exactTimestamp);

      // Test with a duration of 5 days
      final result = nip05.needsUpdate(Duration(days: 5));
      expect(
          result, false); // Should return false since it's exactly at the limit
    });
  });
  group('Nip05.check', () {
    late MockClient mockClient;

    setUp(() {
      mockClient = MockClient();
    });

    test('returns true when the pubkey matches', () async {
      final nip05Address = 'name@domain.com';
      final pubkey = 'sample_pubkey';

      // Mocking the response
      final responseBody = jsonEncode({
        "names": {"name": "sample_pubkey"}
      });

      // Simulate a successful HTTP response
      when(mockClient.get(any)).thenAnswer(
        (_) async => http.Response(responseBody, 200),
      );

      // Inject the mocked client into your method
      final result =
          await Nip05.check(nip05Address, pubkey, client: mockClient);
      expect(result, true);
    });

    test('returns false when pubkey does not match', () async {
      final nip05Address = 'name@domain.com';
      final pubkey = 'wrong_pubkey';

      // Mocking the response
      final responseBody = jsonEncode({
        "names": {"name": "sample_pubkey"}
      });

      // Simulate a successful HTTP response
      when(mockClient.get(any)).thenAnswer(
        (_) async => http.Response(responseBody, 200),
      );

      // Inject the mocked client into your method
      final result = await Nip05.check(nip05Address, pubkey);
      expect(result, false);
    });

    test('returns false when an error occurs', () async {
      final nip05Address = 'name@domain.com';
      final pubkey = 'sample_pubkey';

      // Simulate an error in the HTTP request
      when(mockClient.get(any)).thenThrow(Exception('Failed to load'));

      // Inject the mocked client into your method
      final result = await Nip05.check(nip05Address, pubkey);
      expect(result, false);
    });
  });
}
