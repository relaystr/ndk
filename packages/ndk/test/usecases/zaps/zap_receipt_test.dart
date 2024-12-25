import 'dart:convert';

import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:ndk/domain_layer/usecases/lnurl/lnurl.dart';
import 'package:ndk/ndk.dart';
import 'package:test/test.dart';

import 'zap_receipt_test.mocks.dart';

// Mock classes
@GenerateMocks([Nip01Event])
void main() {
  group('ZapReceipt', () {
    late MockNip01Event mockEvent;

    setUp(() {
      mockEvent = MockNip01Event();
    });

    test('fromEvent initializes correctly with valid event', () {
      when(mockEvent.kind).thenReturn(9735);
      when(mockEvent.pubKey).thenReturn('testPubKey');
      when(mockEvent.tags).thenReturn([
        ['bolt11', 'testBolt11'],
        ['preimage', 'testPreimage'],
        [
          'description',
          jsonEncode({
            'id':'duparomana',
            'pubkey': 'testSender',
            'kind': ZapRequest.KIND,
            'sig': "sig",
            'created_at':DateTime.now().millisecondsSinceEpoch,
            'content': 'testComment',
            'pubKey': 'testSender',
            'tags': [
              ['lnurl', 'testLnurl'],
              ['amount', '1000']
            ]
          })
        ],
        ['p', 'testRecipient'],
        ['e', 'testEventId'],
        ['anon', 'testAnon'],
        ['P', 'testSender']
      ]);
      when(mockEvent.createdAt).thenReturn(1234567890);

      final zapReceipt = ZapReceipt.fromEvent(mockEvent);

      expect(zapReceipt.pubKey, 'testPubKey');
      expect(zapReceipt.bolt11, 'testBolt11');
      expect(zapReceipt.preimage, 'testPreimage');
      expect(zapReceipt.comment, 'testComment');
      expect(zapReceipt.sender, 'testSender');
      expect(zapReceipt.lnurl, 'testLnurl');
      expect(zapReceipt.amountSats, 1); // 1000 msats = 1 sat
      expect(zapReceipt.recipient, 'testRecipient');
      expect(zapReceipt.eventId, 'testEventId');
      expect(zapReceipt.anon, 'testAnon');
      expect(zapReceipt.paidAt, 1234567890);
    });

    test('fromEvent throws exception for non-nip57 event', () {
      when(mockEvent.pubKey).thenReturn('testPubKey');
      when(mockEvent.createdAt).thenReturn(1234567890);
      when(mockEvent.kind).thenReturn(1234);

      expect(() => ZapReceipt.fromEvent(mockEvent), throwsException);
    });

    test('isValid returns true for valid zap receipt', () {
      when(mockEvent.kind).thenReturn(9735);
      when(mockEvent.pubKey).thenReturn('testPubKey');
      when(mockEvent.createdAt).thenReturn(1234567890);
      when(mockEvent.tags).thenReturn([
        ['bolt11', 'lnbc15u1p'],
        [
          'description',
          jsonEncode({
            'id':'duparomana',
            'pubkey': 'testSender',
            'kind': ZapRequest.KIND,
            'sig': "sig",
            'created_at':DateTime.now().millisecondsSinceEpoch,
            'content':'',
            'tags': [
              ['lnurl', 'testLnurl'],
              ['amount', '1500000']
            ]
          })
        ]
      ]);

      final zapReceipt = ZapReceipt.fromEvent(mockEvent);

      expect(
          zapReceipt.isValid(
              nostrPubKey: 'testPubKey', recipientLnurl: 'testLnurl'),
          isTrue);
    });

    test('isValid returns false for invalid pubKey', () {
      when(mockEvent.kind).thenReturn(9735);
      when(mockEvent.pubKey).thenReturn('wrongPubKey');
      when(mockEvent.createdAt).thenReturn(1234567890);
      when(mockEvent.tags).thenReturn([
        ['bolt11', 'lnbc15u1p'],
        [
          'description',
          jsonEncode({
            'id':'duparomana',
            'pubkey': 'testSender',
            'kind': ZapRequest.KIND,
            'sig': "sig",
            'created_at':DateTime.now().millisecondsSinceEpoch,
            'content':'',
            'tags': [
              ['lnurl', 'testLnurl'],
              ['amount', '1500000']
            ]
          })
        ]
      ]);

      final zapReceipt = ZapReceipt.fromEvent(mockEvent);
      expect(
          zapReceipt.isValid(
              nostrPubKey: 'testPubKey', recipientLnurl: 'testLnurl'),
          isFalse);
    });

    test('isValid returns false for mismatched amount', () {
      when(mockEvent.kind).thenReturn(9735);
      when(mockEvent.pubKey).thenReturn('testPubKey');
      when(mockEvent.createdAt).thenReturn(1234567890);
      when(mockEvent.tags).thenReturn([
        ['bolt11', 'lnbc15u1p'],
        [
          'description',
          jsonEncode({
            'id':'duparomana',
            'pubkey': 'testSender',
            'kind': ZapRequest.KIND,
            'sig': "sig",
            'created_at':DateTime.now().millisecondsSinceEpoch,
            'content':'',
            'tags': [
              ['lnurl', 'testLnurl'],
              ['amount', '2000000']
            ]
          })
        ]
      ]);

      final zapReceipt = ZapReceipt.fromEvent(mockEvent);
      expect(
          zapReceipt.isValid(
              nostrPubKey: 'testPubKey', recipientLnurl: 'testLnurl'),
          isFalse);
    });

    test('isValid returns false for mismatched lnurl', () {
      when(mockEvent.kind).thenReturn(9735);
      when(mockEvent.pubKey).thenReturn('testPubKey');
      when(mockEvent.createdAt).thenReturn(1234567890);
      when(mockEvent.tags).thenReturn([
        ['bolt11', 'lnbc15u1p'],
        [
          'description',
          jsonEncode({
            'id':'duparomana',
            'pubkey': 'testSender',
            'kind': ZapRequest.KIND,
            'sig': "sig",
            'created_at':DateTime.now().millisecondsSinceEpoch,
            'content':'',
            'tags': [
              ['lnurl', 'wrongLnurl'],
              ['amount', '1500000']
            ]
          })
        ]
      ]);

      final zapReceipt = ZapReceipt.fromEvent(mockEvent);

      expect(
          zapReceipt.isValid(
              nostrPubKey: 'testPubKey', recipientLnurl: 'testLnurl'),
          isFalse);
    });
  });
}
