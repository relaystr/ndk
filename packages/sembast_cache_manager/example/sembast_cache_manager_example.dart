import 'dart:io';
import 'package:ndk/domain_layer/entities/nip_05.dart';
import 'package:ndk/ndk.dart';
import 'package:sembast/sembast_io.dart';
import 'package:sembast_cache_manager/sembast_cache_manager.dart';

Future<void> main() async {
  print('🚀 SembastCacheManager Example\n');

  // 1. Create a temporary database
  final tempDir = await Directory.systemTemp.createTemp('sembast_cache_example_');
  final dbPath = '${tempDir.path}/cache.db';
  print('📁 Database path: $dbPath');

  // 2. Open the Sembast database
  final database = await databaseFactoryIo.openDatabase(dbPath);
  print('✅ Database opened successfully');

  // 3. Create the cache manager
  final cacheManager = SembastCacheManager(database);
  print('✅ Cache manager created\n');

  try {
    // 4. Create some sample data
    print('📝 Creating sample data...');
    
    // Create a sample event
    final event = Nip01Event(
      pubKey: 'npub1abc123def456ghi789jkl012mno345pqr678stu901vwx234yz567890',
      kind: 1, // Text note
      tags: [
        ['p', 'npub1other123456789'],
        ['t', 'nostr'],
        ['t', 'bitcoin']
      ],
      content: 'Hello Nostr! This is my first cached event using SembastCacheManager 🎉',
      createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );

    // Create sample metadata
    final metadata = Metadata(
      pubKey: 'npub1abc123def456ghi789jkl012mno345pqr678stu901vwx234yz567890',
      name: 'alice',
      displayName: 'Alice Smith',
      about: 'Bitcoin enthusiast and Nostr developer',
      picture: 'https://example.com/alice.jpg',
      nip05: 'alice@example.com',
      website: 'https://alice.example.com',
    );

    // Create sample contact list
    final contactList = ContactList(
      pubKey: 'npub1abc123def456ghi789jkl012mno345pqr678stu901vwx234yz567890',
      contacts: [
        'npub1friend123456789',
        'npub1buddy987654321',
        'npub1pal555666777',
      ],
    );
    contactList.petnames = ['Friend', 'Buddy', 'Pal'];
    contactList.createdAt = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    // Create sample NIP-05 verification
    final nip05 = Nip05(
      pubKey: 'npub1abc123def456ghi789jkl012mno345pqr678stu901vwx234yz567890',
      nip05: 'alice@example.com',
      valid: true,
      relays: ['wss://relay1.example.com', 'wss://relay2.example.com'],
    );

    print('✅ Sample data created\n');

    // 5. Save data to cache
    print('💾 Saving data to cache...');
    await cacheManager.saveEvent(event);
    print('✅ Event saved');
    
    await cacheManager.saveMetadata(metadata);
    print('✅ Metadata saved');
    
    await cacheManager.saveContactList(contactList);
    print('✅ Contact list saved');
    
    await cacheManager.saveNip05(nip05);
    print('✅ NIP-05 verification saved\n');

    // 6. Load data from cache
    print('📖 Loading data from cache...');
    
    final loadedEvent = await cacheManager.loadEvent(event.id);
    print('✅ Event loaded: "${loadedEvent?.content}"');
    
    final loadedMetadata = await cacheManager.loadMetadata(metadata.pubKey);
    print('✅ Metadata loaded: ${loadedMetadata?.displayName} (@${loadedMetadata?.name})');
    
    final loadedContactList = await cacheManager.loadContactList(contactList.pubKey);
    print('✅ Contact list loaded: ${loadedContactList?.contacts.length} contacts');
    
    final loadedNip05 = await cacheManager.loadNip05(nip05.pubKey);
    print('✅ NIP-05 loaded: ${loadedNip05?.nip05} (valid: ${loadedNip05?.valid})\n');

    // 7. Demonstrate search functionality
    print('🔍 Demonstrating search functionality...');
    
    // Search events by content
    final eventsByContent = await cacheManager.searchEvents(search: 'Nostr');
    print('✅ Found ${eventsByContent.length} events containing "Nostr"');
    
    // Search events by tags
    final eventsByTag = await cacheManager.searchEvents(tags: {'t': ['bitcoin']});
    print('✅ Found ${eventsByTag.length} events with #bitcoin tag');
    
    // Search metadata
    final metadataResults = await cacheManager.searchMetadatas('alice', 10);
    print('✅ Found ${metadataResults.length} metadata entries for "alice"\n');

    // 8. Demonstrate batch operations
    print('📦 Demonstrating batch operations...');
    
    final moreEvents = [
      Nip01Event(
        pubKey: 'npub1user222333444',
        kind: 1,
        tags: [['t', 'nostr']],
        content: 'Another event for batch demo',
      ),
      Nip01Event(
        pubKey: 'npub1user555666777',
        kind: 1,
        tags: [['t', 'bitcoin']],
        content: 'Yet another event for batch demo',
      ),
    ];

    await cacheManager.saveEvents(moreEvents);
    print('✅ Saved ${moreEvents.length} events in batch');

    final allEvents = await cacheManager.searchEvents(limit: 10);
    print('✅ Total events in cache: ${allEvents.length}\n');

    // 9. Show some statistics
    print('📊 Cache Statistics:');
    print('   - Events: ${allEvents.length}');
    print('   - Metadata entries: ${metadataResults.length}');
    print('   - Contact lists: 1');
    print('   - NIP-05 verifications: 1\n');

    print('🎉 Example completed successfully!');
    print('💡 The cache persists data between runs - try running this example again!');

  } catch (error) {
    print('❌ Error: $error');
  } finally {
    // 10. Clean up
    await cacheManager.close();
    print('✅ Cache manager closed');
    
    // Optionally clean up the temporary directory
    // await tempDir.delete(recursive: true);
  }
}