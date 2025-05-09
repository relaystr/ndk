// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:convert/convert.dart';
import 'package:ascii_qr/ascii_qr.dart';
import 'package:ndk/domain_layer/usecases/nwc/nwc_notification.dart';

import 'package:ndk/ndk.dart';

void main() async {
  // We use an empty bootstrap relay list,
  // since NWC will provide the relay we connect to so we don't need default relays
  final ndk = Ndk.emptyBootstrapRelaysConfig();

  // You need an NWC_URI env var or to replace with your NWC uri connection
  final nwcUri = Platform.environment['NWC_URI']!;
  final connection = await ndk.nwc.connect(nwcUri);

  final amount = 29;
  final description = "hello hold";

  // Generate a random 32-byte preimage
  final random = Random.secure();
  final preimageBytes =
      Uint8List.fromList(List<int>.generate(32, (_) => random.nextInt(256)));
  final preimageHex =
      hex.encode(preimageBytes); // Optional: hex encode for printing

  // Calculate the payment hash (SHA256 of the preimage)
  final paymentHashBytes = sha256.convert(preimageBytes).bytes;
  final paymentHash = hex.encode(paymentHashBytes);

  print("Generated Preimage: $preimageHex");
  print("Generated Payment Hash: $paymentHash");

  try {
    // 1. Create the hold invoice
    print("Creating hold invoice...");
    final makeResponse = await ndk.nwc.makeHoldInvoice(connection,
        amountSats: amount, description: description, paymentHash: paymentHash);

    if (makeResponse.errorCode == null) {
      // Check if errorCode is null for success
      final invoice = makeResponse.invoice;
      print(
          "Hold invoice created successfully. Invoice: $invoice, Payment Hash: ${makeResponse.paymentHash}");

      if (invoice.isNotEmpty) {
        print("\nScan QR Code to pay/hold:");
        try {
          final asciiQr = AsciiQrGenerator.generate(
            invoice.toUpperCase(),
          );
          print(asciiQr.toString());
        } catch (e) {
          print("Error generating ASCII QR code: $e");
        }
        print("\nOr copy Bolt11 invoice:\n$invoice\n");
      }

      final duration = makeResponse.expiresAt!-DateTime.now().millisecondsSinceEpoch ~/ 1000;
      print(
          "Waiting for hold invoice acceptance notification (max $duration seconds)...");
      try {
        final acceptedNotification = await connection.holdInvoiceStateStream
            .firstWhere((notification) {
          return notification.notificationType == NwcNotification.kHoldInvoiceAccepted;
        }).timeout(Duration(seconds: duration.toInt()));

        print(
            "Hold invoice accepted by wallet! (Notification: ${acceptedNotification.notificationType})");

        // 3. Ask user whether to settle or cancel
        print("Settle this accepted invoice? (Y/N)");
        String? input = stdin.readLineSync()?.trim().toLowerCase();

        if (input == 'n') {
          // 4a. Cancel the hold invoice
          print("Canceling hold invoice with payment hash: $paymentHash...");
          final cancelResponse = await ndk.nwc
              .cancelHoldInvoice(connection, paymentHash: paymentHash);

          if (cancelResponse.errorCode == null) {
            // Check if errorCode is null for success
            print("Hold invoice canceled successfully.");
          } else {
            print(
                "Failed to cancel hold invoice. Error: ${cancelResponse.errorMessage} (Code: ${cancelResponse.errorCode})");
          }
        } else if (input == 'y') {
          // 4b. Settle the hold invoice using the preimage
          print("Settling hold invoice with preimage: $preimageHex...");
          final settleResponse = await ndk.nwc
              .settleHoldInvoice(connection, preimage: preimageHex);

          if (settleResponse.errorCode == null) {
            print(
                "Hold invoice settled successfully. Preimage used: $preimageHex");
          } else {
            print(
                "Failed to settle hold invoice. Error: ${settleResponse.errorMessage} (Code: ${settleResponse.errorCode})");
          }
        } else {
          print("Invalid input. Not settling or canceling.");
        }
      } on TimeoutException {
        print(
            "Timed out waiting for hold invoice acceptance notification. The invoice might not be held by the wallet.");
        // Optionally, try to cancel here as a fallback?
      } catch (e) {
        print("Error waiting for notification: $e");
      }
    } else {
      print(
          "Failed to create hold invoice. Error: ${makeResponse.errorMessage} (Code: ${makeResponse.errorCode})");
    }
  } catch (e) {
    print("An error occurred: $e");
  } finally {
    // Ensure ndk.destroy() is called in the finally block
    await ndk.destroy();
  }
}
