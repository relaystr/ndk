#!/bin/bash
# Build the JS bundle and update the Dart file

set -e

cd "$(dirname "$0")"

echo "Building JS bundle..."
npm run build

echo "Updating nostr_crypto_js.dart..."
cat > ../src/nostr_crypto_js.dart << 'DARTEOF'
/// Bundled nostr-crypto-bundle JS code.
/// Generated from lib/assets/nostr_crypto.src.js using esbuild.
/// To regenerate: cd lib/assets && ./build.sh
const String nostrCryptoJs = r'''
DARTEOF

cat nostr_crypto.js >> ../src/nostr_crypto_js.dart
echo "''';" >> ../src/nostr_crypto_js.dart

echo "Done!"
