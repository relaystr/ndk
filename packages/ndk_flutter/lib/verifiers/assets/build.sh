#!/bin/bash
# Build the JS bundle and update the Dart file

set -e

cd "$(dirname "$0")"

echo "Building JS bundle..."
npm run build

echo "Updating nostr_verify_js.dart..."
cat > ../src/nostr_verify_js.dart << 'DARTEOF'
/// Bundled nostr-tools verification JS code.
/// Generated from lib/assets/nostr_verify.src.js using esbuild.
/// To regenerate: cd lib/assets && ./build.sh
const String nostrVerifyJs = r'''
DARTEOF

cat nostr_verify.js >> ../src/nostr_verify_js.dart
echo "''';" >> ../src/nostr_verify_js.dart

echo "Done!"
