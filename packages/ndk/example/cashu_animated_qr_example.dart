// ignore_for_file: avoid_print
import 'package:ndk/domain_layer/entities/cashu/cashu_proof.dart';
import 'package:ndk/domain_layer/entities/cashu/cashu_token.dart';
import 'package:ndk/domain_layer/usecases/cashu/cashu_token_ur_encoder.dart';

/// Example demonstrating NUT-16 Animated QR codes using UR encoding
///
/// This shows how to encode and decode Cashu tokens using the UR (Uniform Resources)
/// protocol for both single-part (static QR) and multi-part (animated QR) scenarios.
void main() {
  print('=== Cashu Token UR Encoding Example (NUT-16) ===\n');

  // Example 1: Single-part UR (for small tokens - static QR code)
  singlePartExample();

  print('\n' + '=' * 60 + '\n');

  // Example 2: Multi-part UR (for large tokens - animated QR codes)
  multiPartExample();
}

void singlePartExample() {
  print('Example 1: Single-Part UR (Static QR Code)\n');

  // Create a simple Cashu token with one proof
  final token = CashuToken(
    proofs: [
      CashuProof(
        amount: 8,
        secret: 'my-secret-proof-data',
        unblindedSig:
            '02a9acc1e48c25eeeb9289b5031cc57da9fe72f3fe2861d264bdc074209b107ba2',
        keysetId: '009a1f293253e41e',
      ),
    ],
    memo: 'Payment for coffee',
    unit: 'sat',
    mintUrl: 'https://mint.example.com',
  );

  // Encode to single-part UR
  final urString = CashuTokenUrEncoder.encodeSinglePart(token: token);
  print('Encoded UR (for QR code):');
  print(urString);
  print('\nThis can be displayed as a single static QR code.');

  // Decode back
  final decodedToken = CashuTokenUrEncoder.decodeSinglePart(urString);
  if (decodedToken != null) {
    print('\nSuccessfully decoded token:');
    print('  Mint: ${decodedToken.mintUrl}');
    print('  Amount: ${decodedToken.proofs[0].amount} ${decodedToken.unit}');
    print('  Memo: ${decodedToken.memo}');
  }
}

void multiPartExample() {
  print('Example 2: Multi-Part UR (Animated QR Code)\n');

  // Create a larger token that requires multiple parts
  final proofs = List<CashuProof>.generate(
    5,
    (i) => CashuProof(
      amount: 1 << i, // 1, 2, 4, 8, 16
      secret: 'proof-$i-with-long-data-${"x" * 50}',
      unblindedSig:
          '02a9acc1e48c25eeeb9289b5031cc57da9fe72f3fe2861d264bdc074209b107ba2',
      keysetId: '009a1f293253e41e',
    ),
  );

  final token = CashuToken(
    proofs: proofs,
    memo: 'Large payment requiring multiple QR codes',
    unit: 'sat',
    mintUrl: 'https://mint.example.com',
  );

  // Create multi-part encoder with small fragment size to demonstrate
  final encoder = CashuTokenUrEncoder.createMultiPartEncoder(
    token: token,
    maxFragmentLen: 80, // Small size to force multiple parts
  );

  print('Encoding large token as animated QR code...');
  print('Is single part: ${encoder.isSinglePart}');

  // Generate all parts (each part would be a frame in the animated QR)
  final parts = <String>[];
  while (!encoder.isComplete) {
    final part = encoder.nextPart();
    parts.add(part);
    if (parts.length > 20) break; // Safety limit for example
  }

  print('Generated ${parts.length} parts for animated QR code\n');

  // Show first few parts
  print('First 3 parts (each would be a QR code frame):');
  for (var i = 0; i < 3 && i < parts.length; i++) {
    print('  Part ${i + 1}: ${parts[i].substring(0, 40)}...');
  }

  // Demonstrate decoding (receiver side)
  print('\nDecoding process (scanning animated QR)...');

  final decoder = CashuTokenUrEncoder.createMultiPartDecoder();

  // Feed parts to decoder (simulating scanning QR codes)
  for (var i = 0; i < parts.length; i++) {
    decoder.receivePart(parts[i]);
    final progress = decoder.estimatedPercentComplete();
    if (i % 2 == 0 || decoder.isComplete()) {
      // Show progress every 2 parts
      print(
          '  Scanned part ${i + 1}/${parts.length} - ${(progress * 100).toStringAsFixed(1)}% complete');
    }
    if (decoder.isComplete()) break;
  }

  // Decode the complete token
  if (decoder.isComplete()) {
    final decodedToken =
        CashuTokenUrEncoder.decodeFromMultiPartDecoder(decoder);
    if (decodedToken != null) {
      print('\nSuccessfully decoded complete token:');
      print('  Mint: ${decodedToken.mintUrl}');
      print('  Total proofs: ${decodedToken.proofs.length}');
      final totalAmount =
          decodedToken.proofs.fold(0, (sum, p) => sum + p.amount);
      print('  Total amount: $totalAmount ${decodedToken.unit}');
      print('  Memo: ${decodedToken.memo}');
    }
  }

  print('\n📱 In a real wallet app:');
  print('   - Sender: Display parts as animated QR (cycling through frames)');
  print('   - Receiver: Scan until decoder.isComplete() returns true');
  print('   - Parts can be received in any order (robust to missed frames)');
}
