import 'package:ndk/shared/nips/nip01/event_kind_classification.dart';
import 'package:ndk/shared/nips/nip28/channel_metadata.dart';
import 'package:ndk/domain_layer/entities/contact_list.dart';
import 'package:ndk/domain_layer/entities/metadata.dart';
import 'package:test/test.dart';

void main() {
  group('EventKindClassification', () {
    test('detects singleton replaceable kinds', () {
      expect(
        EventKindClassification.isReplaceableKind(Metadata.kKind),
        isTrue,
      );
      expect(
        EventKindClassification.isReplaceableKind(ContactList.kKind),
        isTrue,
      );
      expect(
        EventKindClassification.isReplaceableKind(ChannelMetadata.kKind),
        isTrue,
      );
      expect(
        EventKindClassification.isAddressableKind(Metadata.kKind),
        isFalse,
      );
    });

    test('distinguishes regular replaceable from addressable kinds', () {
      expect(EventKindClassification.isReplaceableKind(10002), isTrue);
      expect(EventKindClassification.isRegularReplaceableKind(10002), isTrue);
      expect(EventKindClassification.isAddressableKind(10002), isFalse);
      expect(
        EventKindClassification.isParameterizedReplaceableKind(10002),
        isFalse,
      );

      expect(EventKindClassification.isReplaceableKind(30023), isTrue);
      expect(
        EventKindClassification.isParameterizedReplaceableKind(30023),
        isTrue,
      );
      expect(EventKindClassification.isAddressableKind(30023), isTrue);
    });

    test('detects ephemeral kinds separately', () {
      expect(EventKindClassification.isEphemeralKind(24133), isTrue);
      expect(EventKindClassification.isReplaceableKind(24133), isFalse);
      expect(EventKindClassification.isAddressableKind(24133), isFalse);
    });
  });
}
