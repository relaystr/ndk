# SembastCacheManager Example

This example demonstrates how to use the SembastCacheManager with the NDK (Nostr Development Kit) library.

## What this example shows

1. **Database Setup**: Creating a Sembast database and initializing the cache manager
2. **Data Creation**: Creating sample Nostr events, metadata, contact lists, and NIP-05 verifications
3. **Caching Operations**: Saving and loading different types of data
4. **Search Functionality**: Searching events by content and tags, searching metadata
5. **Batch Operations**: Saving multiple events at once
6. **Persistence**: Data persists between runs

## Running the example

```bash
# Navigate to the example directory
cd example

# Run the example
dart run main.dart
```

## Sample Output

```
🚀 SembastCacheManager Example

📁 Database path: /tmp/sembast_cache_example_xyz/cache.db
✅ Database opened successfully
✅ Cache manager created

📝 Creating sample data...
✅ Sample data created

💾 Saving data to cache...
✅ Event saved
✅ Metadata saved
✅ Contact list saved
✅ NIP-05 verification saved

📖 Loading data from cache...
✅ Event loaded: "Hello Nostr! This is my first cached event..."
✅ Metadata loaded: Alice Smith (@alice)
✅ Contact list loaded: 3 contacts
✅ NIP-05 loaded: alice@example.com (valid: true)

🔍 Demonstrating search functionality...
✅ Found 1 events containing "Nostr"
✅ Found 1 events with #bitcoin tag
✅ Found 1 metadata entries for "alice"

📦 Demonstrating batch operations...
✅ Saved 2 events in batch
✅ Total events in cache: 3

📊 Cache Statistics:
   - Events: 3
   - Metadata entries: 1
   - Contact lists: 1
   - NIP-05 verifications: 1

🎉 Example completed successfully!
💡 The cache persists data between runs - try running this example again!
✅ Cache manager closed
```

## Key Features Demonstrated

- **Persistent Storage**: All data is stored in a Sembast database file
- **JSON Serialization**: Custom extensions handle NDK object serialization
- **Search Capabilities**: Content search, tag filtering, and metadata search
- **Batch Operations**: Efficient bulk operations for multiple items
- **Data Integrity**: Proper loading and saving of complex nested objects
- **Resource Management**: Proper database closure and cleanup

## Integration with NDK

To use this cache manager with NDK:

```dart
import 'package:ndk/ndk.dart';
import 'package:sembast_cache_manager/sembast_cache_manager.dart';

// Create your cache manager
final cacheManager = SembastCacheManager(database);

// Configure NDK with the cache manager
final ndkConfig = NdkConfig(
  cache: cacheManager,
  eventSigner: yourEventSigner,
  eventVerifier: yourEventVerifier,
);

final ndk = Ndk(ndkConfig);
```

This will enable NDK to use persistent caching for all operations, significantly improving performance for repeated queries and reducing network requests.