import 'package:dart_ndk/nips/nip01/bip340_event_verifier.dart';
import 'package:dart_ndk/nips/nip01/event_verifier.dart';
import 'package:dart_ndk/nips/nip01/filter.dart';
import 'package:dart_ndk/nips/nip01/helpers.dart';
import 'package:dart_ndk/nips/nip01/key_pair.dart';
import 'package:dart_ndk/nips/nip02/contact_list.dart';
import 'package:dart_ndk/relay_jit_manager/relay_jit_manager.dart';
import 'package:dart_ndk/relay_jit_manager/request_jit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'dart:developer' as developer;

void main() async {
  group(
    "Calculate best relays (external REAL)",
    skip: true,
    () {
      _calculateBestRelaysForNpubContactsFeed(String npub,
          {int relayMinCountPerPubKey = 2}) async {
        RelayJitManager relayJitManager = RelayJitManager();
        // wait for the relays to connect
        await Future.delayed(Duration(seconds: 2));

        KeyPair key = KeyPair.justPublicKey(Helpers.decodeBech32(npub)[0]);

        EventVerifier eventVerifier = Bip340EventVerifier();

        NostrRequestJit contactsRequest = NostrRequestJit.query(
          "contacts",
          filters: [
            Filter(authors: [key.publicKey], kinds: [ContactList.KIND]),
          ],
          eventVerifier: eventVerifier,
        );

        relayJitManager.handleRequest(
          contactsRequest,
          desiredCoverage: relayMinCountPerPubKey,
        );

        contactsRequest.responseStream.listen((event) {
          developer.log("event: $event");
        });

        await Future.delayed(Duration(seconds: 10));
      }

      test('Leo feed best relays', () async {
        await _calculateBestRelaysForNpubContactsFeed(
            "npub1w9llyw8c3qnn7h27u3msjlet8xyjz5phdycr5rz335r2j5hj5a0qvs3tur",
            relayMinCountPerPubKey: 2);
      }, timeout: const Timeout.factor(10));

      test('Fmar feed best relays', () async {
        await _calculateBestRelaysForNpubContactsFeed(
            "npub1xpuz4qerklyck9evtg40wgrthq5rce2mumwuuygnxcg6q02lz9ms275ams",
            relayMinCountPerPubKey: 2);
      }, timeout: const Timeout.factor(10));

      test('mikedilger feed best relays', () async {
        await _calculateBestRelaysForNpubContactsFeed(
            "npub1acg6thl5psv62405rljzkj8spesceyfz2c32udakc2ak0dmvfeyse9p35c",
            relayMinCountPerPubKey: 2);
      }, timeout: const Timeout.factor(10));

      test('Fiatjaf feed best relays', () async {
        await _calculateBestRelaysForNpubContactsFeed(
            "npub180cvv07tjdrrgpa0j7j7tmnyl2yr6yr7l8j4s3evf6u64th6gkwsyjh6w6",
            relayMinCountPerPubKey: 2);
      }, timeout: const Timeout.factor(10));

      test('Love is Bitcoin (3k follows) feed best relays', () async {
        await _calculateBestRelaysForNpubContactsFeed(
            "npub1kwcatqynqmry9d78a8cpe7d882wu3vmrgcmhvdsayhwqjf7mp25qpqf3xx",
            relayMinCountPerPubKey: 2);
      }, timeout: const Timeout.factor(10));
    },
  );
}
