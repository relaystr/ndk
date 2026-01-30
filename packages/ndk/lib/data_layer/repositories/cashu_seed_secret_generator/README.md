# Cashu Key Derivation

This directory contains platform-specific implementations for Cashu key derivation.

## Architecture

The implementation uses Dart's conditional imports to provide different implementations based on the target platform:

### Files

- **`cashu_key_derivation_factory.dart`**: Factory function that creates the appropriate implementation based on the platform.
- **`cashu_key_derivation_impl_stub.dart`**: Stub implementation (fallback, should not be used).
- **`cashu_key_derivation_impl_io.dart`**: Native (Dart VM/Flutter) implementation using `DartCashuKeyDerivation`.
- **`cashu_key_derivation_impl_web.dart`**: Web implementation using `JsCashuKeyDerivation`.
- **`dart_cashu_key_derivation.dart`**: Pure Dart implementation using native cryptographic libraries.
- **`js_cashu_key_derivation.dart`**: Web-specific implementation using JavaScript interop to call browser-based cryptography libraries.

## Platform-Specific Behavior

### Native Platforms (iOS, Android, Desktop)
- Uses `DartCashuKeyDerivation` class
- Implements all cryptography in pure Dart
- Uses libraries: `crypto`, `bip32_keys`, `convert`

### Web Platform
- Uses `JsCashuKeyDerivation` class
- Delegates to JavaScript implementation in `/web/js/cashu_key_derivation.js`
- Uses browser-native libraries: `@noble/hashes`, `@scure/bip32`
- Communicates via Dart's `dart:js_interop` API

## Usage

The factory pattern is used automatically by `init.dart`:

```dart
import 'cashu_key_derivation_factory.dart';

// Automatically selects the correct implementation
final derivation = createCashuKeyDerivation();
```

## Key Derivation Methods

Both implementations support:

1. **Modern derivation (v01)**: HMAC-SHA256 based key derivation
2. **Legacy derivation (v00)**: BIP32-based hierarchical deterministic key derivation

The derivation method is selected automatically based on the keyset ID version prefix.
