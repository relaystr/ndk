# NUT-16: Animated QR Codes for Cashu Tokens

This document describes the implementation of NUT-16 (Animated QR codes) in the NDK library using the UR (Uniform Resources) protocol.

## Overview

The `CashuTokenUrEncoder` class provides encoding and decoding functionality for Cashu tokens using the UR protocol, enabling:
- **Static QR codes** for small tokens (≤2 proofs)
- **Animated QR codes** for larger tokens that don't fit in a single QR code

## Implementation

### Library Used
- **bc-ur-dart**: Dart implementation of the UR protocol from [bukata-sa/bc-ur-dart](https://github.com/bukata-sa/bc-ur-dart)
- Based on the [UR specification](https://developer.blockchaincommons.com/ur/) by Blockchain Commons

### How It Works

1. **Encoding**: 
   - Cashu token is serialized to CBOR (same as V4 tokens)
   - CBOR bytes are encoded using UR protocol
   - For large tokens, data is split into fountain-encoded parts

2. **Decoding**:
   - UR strings are decoded back to CBOR
   - CBOR is deserialized to Cashu token
   - Multi-part decoding supports out-of-order reception

## Usage

### Single-Part UR (Static QR Code)

```dart
import 'package:ndk/domain_layer/usecases/cashu/cashu_token_ur_encoder.dart';

// Encode token to UR
final urString = CashuTokenUrEncoder.encodeSinglePart(token: token);
// Returns: "ur:bytes/..."

// Display as QR code...

// Decode scanned UR
final decodedToken = CashuTokenUrEncoder.decodeSinglePart(urString);
```

### Multi-Part UR (Animated QR Code)

**Sender (Display animated QR):**
```dart
// Create encoder
final encoder = CashuTokenUrEncoder.createMultiPartEncoder(
  token: token,
  maxFragmentLen: 100, // Adjust based on QR capacity
);

// Generate parts and display as animated QR
while (!encoder.isComplete) {
  final part = encoder.nextPart();
  // Display 'part' as QR code frame
  // Wait 200-500ms before next frame
}
```

**Receiver (Scan animated QR):**
```dart
// Create decoder
final decoder = CashuTokenUrEncoder.createMultiPartDecoder();

// Feed scanned parts
while (!decoder.isComplete()) {
  final scannedPart = scanQRCode(); // Your QR scanning logic
  decoder.receivePart(scannedPart);
  
  // Optional: Show progress
  final progress = decoder.estimatedPercentComplete();
  print('${(progress * 100).toFixed(1)}% complete');
}

// Decode complete token
final token = CashuTokenUrEncoder.decodeFromMultiPartDecoder(decoder);
```

## API Reference

### `CashuTokenUrEncoder`

#### Static Methods

**`encodeSinglePart({required CashuToken token})`**
- Encodes a token to a single UR string
- Returns: `String` (e.g., "ur:bytes/...")
- Use for small tokens that fit in one QR code

**`decodeSinglePart(String urString)`**
- Decodes a single UR string back to a token
- Returns: `CashuToken?` (null if invalid)

**`createMultiPartEncoder({required CashuToken token, int maxFragmentLen = 100, ...})`**
- Creates an encoder for animated QR codes
- `maxFragmentLen`: Maximum bytes per fragment (default: 100)
- Returns: `UREncoder` instance
- Call `nextPart()` repeatedly to generate QR frames

**`createMultiPartDecoder()`**
- Creates a decoder for animated QR codes
- Returns: `URDecoder` instance
- Call `receivePart(String)` for each scanned frame

**`decodeFromMultiPartDecoder(URDecoder decoder)`**
- Extracts the complete token from a decoder
- Returns: `CashuToken?` (null if not complete or invalid)
- Only call when `decoder.isComplete()` is true

### UREncoder Methods
- `nextPart()`: Get next UR part to display
- `isComplete`: Check if all parts have been generated
- `isSinglePart`: Check if token fits in single part

### URDecoder Methods
- `receivePart(String)`: Feed a scanned UR part
- `isComplete()`: Check if all parts received
- `isSuccess()`: Check if decoding succeeded
- `estimatedPercentComplete()`: Get progress (0.0-1.0)

## Features

✅ **Fountain Encoding**: Parts can be received in any order  
✅ **Progress Tracking**: Know how much of the token is scanned  
✅ **Error Resilience**: Handles missed or duplicate frames  
✅ **Standard Compliant**: Uses standard UR protocol  
✅ **CBOR Encoding**: Compatible with existing V4 tokens  

## Example

See `example/cashu_animated_qr_example.dart` for a complete working example demonstrating both single-part and multi-part encoding/decoding.

## Specification

This implements [NUT-16](https://github.com/cashubtc/nuts/blob/main/16.md) from the Cashu specification.

## Testing

Comprehensive test suite in `test/cashu/cashu_token_ur_encoder_test.dart` covering:
- Single-part encoding/decoding
- Multi-part encoding/decoding
- Progress tracking
- Out-of-order reception
- Edge cases (empty tokens, unicode, long memos)
- Error handling

Run tests:
```bash
dart test test/cashu/cashu_token_ur_encoder_test.dart
```
