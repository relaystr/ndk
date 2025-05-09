import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:convert/convert.dart' as convert;
import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ndk/domain_layer/usecases/nwc/consts/nwc_method.dart';
import 'package:ndk/domain_layer/usecases/nwc/nwc_notification.dart';
import 'package:ndk/domain_layer/usecases/nwc/responses/nwc_response.dart';
import 'package:ndk/ndk.dart';
import 'package:protocol_handler/protocol_handler.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'main.dart';

class NwcPage extends StatefulWidget {
  const NwcPage({super.key});

  @override
  State<NwcPage> createState() => _NwcPageState();
}

class _NwcPageState extends State<NwcPage> with ProtocolListener {
  TextEditingController uri = TextEditingController();
  TextEditingController amount =
      TextEditingController(); // For normal and hold invoice
  // TextEditingController holdAmount = TextEditingController(); // Removed
  TextEditingController description =
      TextEditingController(); // Used if isHoldInvoice is true
  TextEditingController invoice =
      TextEditingController(); // For paying invoices
  NwcConnection? connection;
  GetBalanceResponse? balance;
  MakeInvoiceResponse?
      makeInvoice; // Will store result of normal or hold invoice creation
  PayInvoiceResponse? payInvoice;

  // MakeInvoiceResponse? makeHoldInvoiceResponse; // Removed, merged into makeInvoice
  String? holdInvoicePreimage;
  String?
      holdInvoicePaymentHash; // Still needed to identify the hold invoice for notifications/settle/cancel
  bool isHoldInvoice = false; // For the checkbox
  bool _currentInvoiceWasHold =
      false; // To track if the current 'makeInvoice' is a hold type
  bool isHoldInvoiceAccepted = false;
  String? holdInvoiceStatusMessage;
  StreamSubscription? holdInvoiceStateSubscription;
  NwcResponse? settleHoldInvoiceResponse;
  NwcResponse? cancelHoldInvoiceResponse;

  // For regular invoice payment notifications
  bool isRegularInvoicePaid = false;
  String? regularInvoiceStatusMessage;
  StreamSubscription? regularInvoicePaymentSubscription;

  @override
  void initState() {
    super.initState();
    uri.addListener(() {
      setState(() {
        if (uri.text == '') {
          connection = null;
          _resetInvoiceStates(); // Reset invoice states if connection URI is cleared
        }
      });
    });
    amount.addListener(() {
      setState(() {});
    });
    // holdAmount.addListener(() { // Removed
    //   setState(() {});
    // });
    description.addListener(() {
      setState(() {});
    });
    invoice.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    uri.dispose();
    amount.dispose();
    // holdAmount.dispose(); // Removed
    description.dispose();
    invoice.dispose();
    holdInvoiceStateSubscription?.cancel();
    regularInvoicePaymentSubscription?.cancel();
    super.dispose();
  }

  void _resetInvoiceStates() {
    setState(() {
      makeInvoice = null;
      // makeHoldInvoiceResponse = null; // Removed
      holdInvoicePreimage = null;
      holdInvoicePaymentHash = null;
      isHoldInvoiceAccepted = false;
      _currentInvoiceWasHold = false;
      holdInvoiceStatusMessage = null;
      holdInvoiceStateSubscription?.cancel();
      holdInvoiceStateSubscription = null;
      settleHoldInvoiceResponse = null;
      cancelHoldInvoiceResponse = null;

      isRegularInvoicePaid = false;
      regularInvoiceStatusMessage = null;
      regularInvoicePaymentSubscription?.cancel();
      regularInvoicePaymentSubscription = null;
      // isHoldInvoice = false; // Optionally reset checkbox, or leave it as user set
    });
  }

  @override
  void onProtocolUrlReceived(String url) async {
    String log = 'Url received: $url)';
    print(log);
    // if (StringUtil) {}
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> widgets = [];
    // widgets.add(Expanded(
    //   child: Column(
    //     mainAxisSize: MainAxisSize.min,
    //     mainAxisAlignment: MainAxisAlignment.start,
    //     crossAxisAlignment: CrossAxisAlignment.center,
    //     children: [
    //       Expanded(
    //         child: Container(
    //           width: double.infinity,
    //           padding: const EdgeInsets.symmetric(horizontal: 16),
    //           child: Column(
    //             mainAxisSize: MainAxisSize.min,
    //             mainAxisAlignment: MainAxisAlignment.center,
    //             crossAxisAlignment: CrossAxisAlignment.center,
    //             children: [
    //               Container(
    //                 width: double.infinity,
    //                 // height: 112,
    //                 padding: const EdgeInsets.only(bottom: 24),
    //                 child: const Column(
    //                   mainAxisSize: MainAxisSize.min,
    //                   mainAxisAlignment: MainAxisAlignment.start,
    //                   crossAxisAlignment: CrossAxisAlignment.center,
    //                   children: [
    //                     SizedBox(height: 20),
    //                     SizedBox(
    //                       width: double.infinity,
    //                       child: Text(
    //                         'Connect Wallet',
    //                         textAlign: TextAlign.center,
    //                         style: TextStyle(
    //                           color: Colors.white,
    //                           fontSize: 24,
    //                           fontFamily: 'Geist',
    //                           fontWeight: FontWeight.w700,
    //                           height: 0.06,
    //                         ),
    //                       ),
    //                     ),
    //                     SizedBox(height: 20),
    //                     SizedBox(
    //                       // width: double.infinity,
    //                       child: Text(
    //                         'Connect your bitcoin lightning wallet with NWC for better zapping experience.',
    //                         textAlign: TextAlign.center,
    //                         style: TextStyle(
    //                           color: Color(0xFF7A7D81),
    //                           fontSize: 16,
    //                           fontFamily: 'Geist',
    //                           fontWeight: FontWeight.w400,
    //                           // height: 0.09,
    //                         ),
    //                       ),
    //                     ),
    //                   ],
    //                 ),
    //               ),
    //               SizedBox(
    //                 width: 80,
    //                 height: 80,
    //                 child: Row(
    //                   mainAxisSize: MainAxisSize.min,
    //                   mainAxisAlignment: MainAxisAlignment.center,
    //                   crossAxisAlignment: CrossAxisAlignment.center,
    //                   children: [
    //                     SizedBox(
    //                       width: 80,
    //                       height: 80,
    //                       child: Column(
    //                         mainAxisSize: MainAxisSize.min,
    //                         mainAxisAlignment: MainAxisAlignment.start,
    //                         crossAxisAlignment: CrossAxisAlignment.start,
    //                         children: [
    //                           Image.asset("assets/imgs/albygo.png"),
    //                         ],
    //                       ),
    //                     ),
    //                   ],
    //                 ),
    //               ),
    //               Row(
    //                 mainAxisSize: MainAxisSize.min,
    //                 mainAxisAlignment: MainAxisAlignment.center,
    //                 crossAxisAlignment: CrossAxisAlignment.start,
    //                 children: [
    //                   FilledButton(
    //                     child: Text("Alby Go"),
    //                     onPressed: () async {
    //                       if (Platform.isAndroid) {
    //                         Uri uri = Uri.parse("nostrnwc://bla?appname=Yana\&appicon=https%3A%2F%2Fyana.do%2Fimages%2Flogo-new.png\&callback=ndk%3A%2F%2Fnwc");
    //                         await launchUrl(uri);
    //                         // AndroidIntent intent = AndroidIntent(
    //                         //   action: 'action_view',
    //                         //   data: "nostrnwc://bla?appname=Yana\&appicon=https%3A%2F%2Fyana.do%2Fimages%2Flogo-new.png\&callback=ndk%3A%2F%2Fnwc",
    //                         // );
    //                         // await intent.launch();
    //                       }
    //                     },
    //                   ),
    //                 ],
    //               ),
    //               SizedBox(height: 20),
    //               SizedBox(
    //                 width: 80,
    //                 height: 80,
    //                 child: Row(
    //                   mainAxisSize: MainAxisSize.min,
    //                   mainAxisAlignment: MainAxisAlignment.center,
    //                   crossAxisAlignment: CrossAxisAlignment.center,
    //                   children: [
    //                     SizedBox(
    //                       width: 80,
    //                       height: 80,
    //                       child: Column(
    //                         mainAxisSize: MainAxisSize.min,
    //                         mainAxisAlignment: MainAxisAlignment.start,
    //                         crossAxisAlignment: CrossAxisAlignment.start,
    //                         children: [
    //                           Image.asset("assets/imgs/nwc.png"),
    //                         ],
    //                       ),
    //                     ),
    //                   ],
    //                 ),
    //               ),
    //               Row(
    //                 mainAxisSize: MainAxisSize.min,
    //                 mainAxisAlignment: MainAxisAlignment.center,
    //                 crossAxisAlignment: CrossAxisAlignment.start,
    //                 children: [
    //                   FilledButton(
    //                     child: Text("NWC manual"),
    //                     onPressed: () {
    //                       // TODO
    //                     },
    //                   ),
    //                 ],
    //               ),
    //             ],
    //           ),
    //         ),
    //       ),
    //     ],
    //   ),
    // ));
    //
    if (Platform.isAndroid) {
      widgets.add(
        FilledButton(
          onPressed: () async {
            if (Platform.isAndroid) {
              Uri uri = Uri.parse(
                  "nostrnwc://bla?appname=Yana\&appicon=https%3A%2F%2Fyana.do%2Fimages%2Flogo-new.png\&callback=ndk%3A%2F%2Fnwc");
              await launchUrl(uri);
            }
          },
          child: const Text('Connect with Alby Go'),
        ),
      );
    }
    widgets.add(Container(
        padding: const EdgeInsets.all(20),
        width: 400,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: TextField(
                controller: uri,
                onEditingComplete: () {
                  setState(() {});
                },
                decoration: InputDecoration(
                  prefixIcon: IconButton(
                      onPressed: () {
                        Clipboard.getData(Clipboard.kTextPlain)
                            .then((clipboardData) {
                          if (clipboardData != null &&
                              clipboardData.text != null) {
                            setState(() {
                              uri.text = clipboardData.text!;
                            });
                          }
                        });
                      },
                      icon: const Icon(Icons.paste)),
                  hintText: "nostr+wallet://... url",
                  hintStyle: const TextStyle(color: Colors.grey),
                ),
                style: const TextStyle(fontSize: 14),
              ),
            )
          ],
        )));
    widgets.add(
      FilledButton(
        onPressed: uri.text.isNotEmpty
            ? () async {
                connection =
                    await ndk.nwc.connect(uri.text, doGetInfoMethod: true);
                setState(() {
                  balance = null;
                });
              }
            : null,
        child: const Text('Connect and get info'),
      ),
    );
    widgets.add(connection != null && connection!.info != null
        ? Text("Methods ${connection!.info!.methods}")
        : Container());

    widgets.add(const SizedBox(
      height: 20,
    ));
    widgets.add(
      FilledButton(
        onPressed: connection != null
            ? () async {
                final b = await ndk.nwc.getBalance(connection!);
                setState(() {
                  balance = b;
                });
              }
            : null,
        child: const Text('Get Balance'),
      ),
    );
    widgets.add(connection != null && balance != null
        ? Text("Balance ${balance!.balanceSats} sats")
        : Container());

    widgets.add(
        const Divider(height: 40, thickness: 1, indent: 20, endIndent: 20));

    // Determine if the "Make Invoice" button should be enabled
    bool canSubmitMakeInvoice = connection != null &&
        amount.text.isNotEmpty &&
        (int.tryParse(amount.text) ?? 0) > 0 &&
        (isHoldInvoice
            ? connection!.info!.methods
                .contains(NwcMethod.MAKE_HOLD_INVOICE.name)
            : connection!.info!.methods.contains(NwcMethod.MAKE_INVOICE.name));

    // --- Make Invoice Section ---
    widgets.add(const Padding(
      padding: EdgeInsets.symmetric(vertical: 16.0),
      child: Text("Make Invoice",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    ));
    widgets.add(
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          children: [
            SizedBox(
              width: 200,
              child: TextField(
                controller: amount,
                textAlign: TextAlign.center, // Center text within field
                decoration: const InputDecoration(
                  hintText: "Amount in sats",
                  hintStyle: TextStyle(color: Colors.grey),
                ),
                style: const TextStyle(fontSize: 14),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: 250, // Smaller width for description field
              child: TextField(
                controller: description,
                textAlign: TextAlign.center, // Center text
                decoration: InputDecoration(
                  hintText: isHoldInvoice
                      ? "Description (for hold)"
                      : "Description (optional)",
                  hintStyle: const TextStyle(color: Colors.grey),
                ),
                style: const TextStyle(fontSize: 14),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: 200, // To help center the checkbox
              child: CheckboxListTile(
                title: const Text("Hold Invoice"),
                value: isHoldInvoice,
                onChanged: (bool? value) {
                  setState(() {
                    isHoldInvoice = value ?? false;
                    _resetInvoiceStates();
                  });
                },
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const SizedBox(height: 10),
            Center(
              // Keep the button centered
              child: FilledButton(
                onPressed: canSubmitMakeInvoice
                    ? () async {
                        _resetInvoiceStates(); // Clear previous invoice details first
                        final int sats = int.tryParse(amount.text) ?? 0;
                        if (isHoldInvoice) {
                          setState(() {
                            _currentInvoiceWasHold = true;
                            holdInvoiceStatusMessage =
                                "Generating preimage and payment hash...";
                          });

                          final random = Random.secure();
                          final preimageBytes = Uint8List.fromList(
                              List<int>.generate(
                                  32, (_) => random.nextInt(256)));
                          final preimageHex = convert.hex.encode(preimageBytes);

                          final paymentHashBytes =
                              crypto.sha256.convert(preimageBytes).bytes;
                          final paymentHashHex =
                              convert.hex.encode(paymentHashBytes);

                          setState(() {
                            holdInvoicePreimage = preimageHex;
                            holdInvoicePaymentHash = paymentHashHex;
                            holdInvoiceStatusMessage =
                                "Creating hold invoice...";
                          });

                          try {
                            final response = await ndk.nwc.makeHoldInvoice(
                                connection!,
                                amountSats: sats,
                                description: description.text.isNotEmpty
                                    ? description.text
                                    : null, // Pass null if empty
                                paymentHash: paymentHashHex);
                            setState(() {
                              makeInvoice =
                                  response; // Store in the unified makeInvoice
                              if (response.errorCode == null) {
                                holdInvoiceStatusMessage =
                                    "Hold invoice created. Waiting for acceptance...";
                                _listenForHoldInvoiceAcceptance(paymentHashHex);
                              } else {
                                holdInvoiceStatusMessage =
                                    "Error creating hold invoice: ${response.errorMessage}";
                              }
                            });
                          } catch (e) {
                            setState(() {
                              holdInvoiceStatusMessage =
                                  "Exception creating hold invoice: $e";
                            });
                          }
                        } else {
                          // Regular invoice
                          setState(() {
                            _currentInvoiceWasHold = false;
                          });
                          try {
                            final response = await ndk.nwc.makeInvoice(
                              connection!,
                              amountSats: sats,
                              description: description.text.isNotEmpty
                                  ? description.text
                                  : null, // Pass description for both types if not empty
                            );
                            setState(() {
                              makeInvoice = response;
                              if (response.errorCode == null &&
                                  response.paymentHash != null) {
                                regularInvoiceStatusMessage =
                                    "Regular invoice created. Waiting for payment...";
                                _listenForRegularInvoicePayment(
                                    response.paymentHash!);
                              } else if (response.errorCode != null) {
                                regularInvoiceStatusMessage =
                                    "Error creating regular invoice: ${response.errorMessage}";
                              }
                            });
                          } catch (e) {
                            setState(() {
                              regularInvoiceStatusMessage =
                                  "Exception creating regular invoice: $e";
                              print("Error making regular invoice: $e");
                            });
                          }
                        }
                      }
                    : null,
                child:
                    Text(isHoldInvoice ? 'Make Hold Invoice' : 'Make Invoice'),
              ),
            ),
          ],
        ),
      ),
    );

    // Display for the created invoice (normal or hold)
    if (makeInvoice != null && makeInvoice!.errorCode == null) {
      widgets.add(SelectableText("Invoice: ${makeInvoice!.invoice}"));
      if (_currentInvoiceWasHold) {
        widgets
            .add(SelectableText("Payment Hash: ${makeInvoice!.paymentHash}"));
      }
      if (makeInvoice!.invoice.isNotEmpty) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: QrImageView(
              data: makeInvoice!.invoice.toUpperCase(),
              version: QrVersions.auto,
              size: 200.0,
              backgroundColor: Colors.white,
            ),
          ),
        );
      }
    } else if (makeInvoice != null && makeInvoice!.errorCode != null) {
      // If there was an error creating the invoice (and it's not a hold-specific status message already handled)
      if (!_currentInvoiceWasHold) {
        // Only show generic error if not a hold invoice with its own status
        widgets.add(Text("Error creating invoice: ${makeInvoice!.errorMessage}",
            style: const TextStyle(color: Colors.red)));
      }
    }

    // Display for regular invoice payment status
    if (!_currentInvoiceWasHold &&
        makeInvoice != null &&
        makeInvoice!.errorCode == null) {
      if (regularInvoiceStatusMessage != null) {
        widgets.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(regularInvoiceStatusMessage!,
              style: isRegularInvoicePaid
                  ? const TextStyle(
                      color: Colors.green, fontWeight: FontWeight.bold)
                  : null),
        ));
      }
    }

    // Hold invoice specific status messages and buttons (Settle/Cancel)
    // are now part of the "Make Invoice" section's output, below the QR code.
    if (_currentInvoiceWasHold) {
      if (holdInvoiceStatusMessage != null) {
        widgets.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(holdInvoiceStatusMessage!),
        ));
      }

      if (isHoldInvoiceAccepted) {
        widgets.add(const Text("Hold invoice accepted!",
            style:
                TextStyle(color: Colors.green, fontWeight: FontWeight.bold)));
        widgets.add(Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FilledButton(
              onPressed: (connection != null &&
                      holdInvoicePreimage != null &&
                      !isSettlingOrCancelling())
                  ? () async {
                      setState(() {
                        holdInvoiceStatusMessage = "Settling hold invoice...";
                        settleHoldInvoiceResponse = null;
                        cancelHoldInvoiceResponse = null;
                      });
                      try {
                        final response = await ndk.nwc.settleHoldInvoice(
                            connection!,
                            preimage: holdInvoicePreimage!);
                        setState(() {
                          settleHoldInvoiceResponse = response;
                          if (response.errorCode == null) {
                            holdInvoiceStatusMessage =
                                "Hold invoice settled successfully. Preimage: $holdInvoicePreimage";
                          } else {
                            holdInvoiceStatusMessage =
                                "Error settling invoice: ${response.errorMessage}";
                          }
                        });
                      } catch (e) {
                        setState(() {
                          holdInvoiceStatusMessage =
                              "Exception settling invoice: $e";
                        });
                      }
                    }
                  : null,
              child: const Text("Settle Invoice"),
            ),
            const SizedBox(width: 20),
            FilledButton(
              onPressed: (connection != null &&
                      holdInvoicePaymentHash != null &&
                      !isSettlingOrCancelling())
                  ? () async {
                      setState(() {
                        holdInvoiceStatusMessage = "Cancelling hold invoice...";
                        settleHoldInvoiceResponse = null;
                        cancelHoldInvoiceResponse = null;
                      });
                      try {
                        final response = await ndk.nwc.cancelHoldInvoice(
                            connection!,
                            paymentHash: holdInvoicePaymentHash!);
                        setState(() {
                          cancelHoldInvoiceResponse = response;
                          if (response.errorCode == null) {
                            holdInvoiceStatusMessage =
                                "Hold invoice cancelled successfully.";
                          } else {
                            holdInvoiceStatusMessage =
                                "Error cancelling invoice: ${response.errorMessage}";
                          }
                        });
                      } catch (e) {
                        setState(() {
                          holdInvoiceStatusMessage =
                              "Exception cancelling invoice: $e";
                        });
                      }
                    }
                  : null,
              child: const Text("Cancel Invoice"),
            ),
          ],
        ));
      }

      if (settleHoldInvoiceResponse != null) {
        widgets.add(Text(settleHoldInvoiceResponse!.errorCode == null
            ? "Settle successful! Preimage: $holdInvoicePreimage"
            : "Settle failed: ${settleHoldInvoiceResponse!.errorMessage}"));
      }
      if (cancelHoldInvoiceResponse != null) {
        widgets.add(Text(cancelHoldInvoiceResponse!.errorCode == null
            ? "Cancel successful!"
            : "Cancel failed: ${cancelHoldInvoiceResponse!.errorMessage}"));
      }
    }

    widgets.add(
        const Divider(height: 40, thickness: 1, indent: 20, endIndent: 20));

    // --- Pay Invoice Section ---
    widgets.add(const Padding(
      padding: EdgeInsets.symmetric(vertical: 8.0), // Reduced top padding
      child: Text("Pay Invoice",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    ));

    bool canPayInvoice = connection != null &&
        connection!.info!.methods.contains(NwcMethod.PAY_INVOICE.name) &&
        invoice.text != '';

    widgets.add(Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          SizedBox(
            width: 300, // Centered invoice input field
            child: TextField(
              controller: invoice,
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                hintText: "Invoice to pay (bolt11)",
                hintStyle: TextStyle(color: Colors.grey),
              ),
              style: const TextStyle(fontSize: 14),
            ),
          ),
          const SizedBox(height: 10),
          FilledButton(
            onPressed: canPayInvoice
                ? () async {
                    final p = await ndk.nwc
                        .payInvoice(connection!, invoice: invoice.text);
                    setState(() {
                      payInvoice = p;
                    });
                  }
                : null,
            child: const Text('Pay Invoice'),
          ),
        ],
      ),
    ));
    widgets.add(payInvoice != null
        ? SelectableText("Payment Preimage: ${payInvoice!.preimage}")
        : Container());

    widgets.add(const Divider(height: 40, thickness: 2));
    widgets.add(
      FilledButton(
        onPressed: connection != null
            ? () async {
                await ndk.nwc.disconnect(connection!);
                _resetInvoiceStates(); // Use the new reset function
                setState(() {
                  connection = null;
                  balance = null;
                  // makeInvoice is reset by _resetInvoiceStates
                  payInvoice = null;
                  // Other NWC specific states are reset by _resetInvoiceStates
                });
              }
            : null,
        child: const Text('Disconnect'),
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: SingleChildScrollView(
        child: Column(
            mainAxisAlignment: MainAxisAlignment.start, children: widgets),
      ),
    );
  }

  bool isSettlingOrCancelling() {
    return (holdInvoiceStatusMessage != null &&
            (holdInvoiceStatusMessage!.contains("Settling") ||
                holdInvoiceStatusMessage!.contains("Cancelling"))) ||
        settleHoldInvoiceResponse != null ||
        cancelHoldInvoiceResponse != null;
  }

  void _listenForHoldInvoiceAcceptance(String expectedPaymentHash) {
    holdInvoiceStateSubscription?.cancel();
    if (connection == null) {
      setState(() {
        holdInvoiceStatusMessage =
            "Connection is null, cannot listen for acceptance.";
      });
      return;
    }
    final stream = connection!.holdInvoiceStateStream;
    if (stream == null) {
      if (mounted) {
        setState(() {
          holdInvoiceStatusMessage = "Hold invoice state stream is null.";
        });
      }
      return;
    }

    // Use makeInvoice.expiresAt as it now holds the response for both normal and hold invoices
    final duration = makeInvoice?.expiresAt != null
        ? (makeInvoice!.expiresAt! -
            DateTime.now().millisecondsSinceEpoch ~/ 1000)
        : 300; // Default timeout if expiresAt is not available

    holdInvoiceStateSubscription = stream
        .timeout(
            Duration(seconds: duration.toInt() > 0 ? duration.toInt() : 300))
        .listen((notification) {
      if (notification.notificationType ==
              NwcNotification.kHoldInvoiceAccepted &&
          notification.paymentHash == expectedPaymentHash) {
        setState(() {
          isHoldInvoiceAccepted = true;
          holdInvoiceStatusMessage = "Hold invoice accepted by wallet!";
        });
        holdInvoiceStateSubscription?.cancel();
      }
    }, onError: (error) {
      if (mounted) {
        setState(() {
          if (error is TimeoutException) {
            holdInvoiceStatusMessage =
                "Timed out waiting for hold invoice acceptance.";
          } else {
            holdInvoiceStatusMessage =
                "Error listening for hold invoice acceptance: $error";
          }
        });
      }
    }, onDone: () {
      if (mounted &&
          !isHoldInvoiceAccepted &&
          settleHoldInvoiceResponse == null &&
          cancelHoldInvoiceResponse == null) {
        // setState(() {
        //   holdInvoiceStatusMessage = "Notification stream closed without acceptance.";
        // });
      }
    });
  }

  void _listenForRegularInvoicePayment(String expectedPaymentHash) {
    regularInvoicePaymentSubscription?.cancel();
    if (connection == null) {
      if (mounted) {
        setState(() {
          regularInvoiceStatusMessage =
              "Connection is null, cannot listen for payment.";
        });
      }
      return;
    }
    // Use the general notificationsStream and filter for payment notifications
    final stream = connection!.paymentsReceivedStream;
    if (stream == null) {
      if (mounted) {
        setState(() {
          regularInvoiceStatusMessage = "Payment notification stream is null.";
        });
      }
      return;
    }

    final duration = makeInvoice?.expiresAt != null
        ? (makeInvoice!.expiresAt! -
            DateTime.now().millisecondsSinceEpoch ~/ 1000)
        : 300; // Default timeout


    regularInvoicePaymentSubscription = stream
        .timeout(
            Duration(seconds: duration.toInt() > 0 ? duration.toInt() : 300))
        .listen((notification) {
      if (notification.notificationType ==
              NwcNotification
                  .kPaymentReceived &&
          notification.paymentHash == expectedPaymentHash) {
        if (mounted) {
          setState(() {
            isRegularInvoicePaid = true;
            regularInvoiceStatusMessage =
                "Invoice PAID! Preimage: ${notification.preimage}";
          });
        }
        regularInvoicePaymentSubscription?.cancel();
      }
      // We might also want to listen for kPaymentFailed if the NWC provider sends such for incoming payments that fail.
      // Or, more commonly, the invoice just expires.
    }, onError: (error) {
      if (mounted) {
        setState(() {
          if (error is TimeoutException) {
            regularInvoiceStatusMessage =
                "Timed out waiting for invoice payment.";
          } else {
            regularInvoiceStatusMessage =
                "Error listening for invoice payment: $error";
          }
        });
      }
    }, onDone: () {
      if (mounted && !isRegularInvoicePaid) {
        // If stream closes and invoice not paid, could update status.
        // For now, timeout handles expiration.
      }
    });
  }
}
