```dart
import 'package:ndk/ndk.dart';
import 'package:nip01/nip01.dart';
import 'package:nip49/nip49.dart';
final cacheManager = MemCacheManager();
cacheManager.searchMetadatas("query", 10);
final ndk = Ndk(NdkConfig(eventVerifier: RustEventVerifier(), cache: cacheManager));
final keyPair = KeyPair.generate();
final encryptedKey = await Nip49.encrypt(keyPair.privateKey, "password");
final privateKey = await Nip49.decrypt(encryptedKey, "password");
KeyPair.fromPrivateKey(privateKey: privateKey);
Nip19.npubFromHex("hex");
Nip19.npubToHex("npub");
Nip19.nsecFromHex("hex");
Nip19.nsecToHex("nsec");
ndk.accounts.loginPrivateKey(pubkey: keyPair.publicKey, privkey: keyPair.privateKey);
final contactList = await ndk.follows.getContactList(keyPair.publicKey);
final metadatas = await ndk.metadata.loadMetadatas(contactList!.contacts, null);
final response = ndk.requests.query(
  filters: [
    Filter(
      authors: ['hexPubkey']
      kinds: [Nip01Event.kTextNodeKind],
      limit: 10,
    ),
  ],
  explicitRelays: ["wss://relay.example.com"],
);
await for (final event in response.stream) {print(event.pubKey);}
final metadata = await ndk.metadata.loadMetadata(pubKey);
ndk.broadcast.broadcast(nostrEvent: nostrEvent, specificRelays: ["wss://relay.example.com"]);
ndk.destroy();
```
Never provide an id in the Nip01Event constructor.
