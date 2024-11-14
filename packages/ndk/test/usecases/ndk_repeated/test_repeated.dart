import 'package:test/test.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';

Future<void> testNdk({
  required Ndk myNdk,
  required int coverage,
  required List<Filter> myFilters,
  required Map<KeyPair, Nip01Event> key1TextNotes,
  required Map<KeyPair, Nip01Event> key2TextNotes,
  required Map<KeyPair, Nip01Event> key3TextNotes,
  required Map<KeyPair, Nip01Event> key4TextNotes,
}) async {
  NdkResponse response0 = myNdk.requests.query(
    filters: [
      myFilters[0],
    ],
    desiredCoverage: coverage,
  );

  await expectLater(response0.stream, emitsInAnyOrder(key1TextNotes.values));

  NdkResponse response1 = myNdk.requests.query(
    filters: [
      myFilters[1],
    ],
    desiredCoverage: coverage,
  );

  await expectLater(response1.stream,
      emitsInAnyOrder([...key1TextNotes.values, ...key2TextNotes.values]));

  NdkResponse response2 = myNdk.requests.query(
    filters: [
      myFilters[2],
    ],
    desiredCoverage: coverage,
  );

  await expectLater(response2.stream,
      emitsInAnyOrder([...key3TextNotes.values, ...key4TextNotes.values]));

  NdkResponse response3 = myNdk.requests.query(
    filters: [
      myFilters[3],
    ],
    desiredCoverage: coverage,
  );

  await expectLater(response3.stream,
      emitsInAnyOrder([...key2TextNotes.values, ...key4TextNotes.values]));

  NdkResponse response4 = myNdk.requests.query(
    filters: [
      myFilters[4],
    ],
    desiredCoverage: coverage,
  );
  await expectLater(
      response4.stream,
      emitsInAnyOrder([
        ...key1TextNotes.values,
        ...key2TextNotes.values,
        ...key3TextNotes.values,
      ]));

  NdkResponse response5 = myNdk.requests.query(
    filters: [
      myFilters[5],
    ],
    desiredCoverage: coverage,
  );

  await expectLater(
      response5.stream,
      emitsInAnyOrder([
        ...key1TextNotes.values,
        ...key2TextNotes.values,
        ...key3TextNotes.values,
        ...key4TextNotes.values,
      ]));
}
